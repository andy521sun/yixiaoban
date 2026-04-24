/**
 * 医小伴APP - 陪诊师端API（续）
 */

// 陪诊师统计
app.get('/api/companion/statistics', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { start_date, end_date } = req.query;
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }
    
    const companionId = token.split('_')[2];
    
    // 获取陪诊师的所有任务
    let tasks = companionTasks.filter(t => t.companion_id === companionId);
    
    // 日期筛选
    if (start_date && end_date) {
      tasks = tasks.filter(t => t.appointment_date >= start_date && t.appointment_date <= end_date);
    }
    
    // 计算统计
    const stats = {
      total_tasks: tasks.length,
      completed_tasks: tasks.filter(t => t.status === 'completed').length,
      in_progress_tasks: tasks.filter(t => t.status === 'in_progress').length,
      pending_tasks: tasks.filter(t => t.status === 'pending').length,
      cancelled_tasks: tasks.filter(t => t.status === 'cancelled').length,
      
      total_income: tasks
        .filter(t => t.payment_status === 'paid')
        .reduce((sum, t) => sum + t.price, 0),
      
      pending_income: tasks
        .filter(t => t.payment_status === 'unpaid' && t.status === 'completed')
        .reduce((sum, t) => sum + t.price, 0),
      
      // 服务类型统计
      service_types: {},
      
      // 按状态统计
      by_status: {},
      
      // 按日期统计
      by_date: {}
    };
    
    // 服务类型统计
    tasks.forEach(task => {
      const type = task.service_type;
      stats.service_types[type] = stats.service_types[type] || { count: 0, amount: 0 };
      stats.service_types[type].count++;
      if (task.payment_status === 'paid') {
        stats.service_types[type].amount += task.price;
      }
    });
    
    // 状态统计
    tasks.forEach(task => {
      const status = task.status;
      stats.by_status[status] = stats.by_status[status] || { count: 0 };
      stats.by_status[status].count++;
    });
    
    // 日期统计
    tasks.forEach(task => {
      const date = task.appointment_date;
      stats.by_date[date] = stats.by_date[date] || { count: 0, amount: 0 };
      stats.by_date[date].count++;
      if (task.payment_status === 'paid') {
        stats.by_date[date].amount += task.price;
      }
    });
    
    // 计算完成率
    stats.completion_rate = stats.total_tasks > 0 
      ? ((stats.completed_tasks / stats.total_tasks) * 100).toFixed(2)
      : '0.00';
    
    res.json({
      success: true,
      data: stats,
      message: '获取统计信息成功'
    });
    
  } catch (error) {
    console.error('获取统计信息失败:', error);
    res.status(500).json({
      success: false,
      message: '获取统计信息失败',
      error: error.message
    });
  }
});

// 获取日程安排
app.get('/api/companion/schedule', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { start_date, end_date } = req.query;
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }
    
    const companionId = token.split('_')[2];
    
    // 默认显示未来7天
    const defaultStart = new Date().toISOString().split('T')[0];
    const defaultEnd = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    
    const start = start_date || defaultStart;
    const end = end_date || defaultEnd;
    
    // 获取日程任务
    const scheduleTasks = companionTasks.filter(t => 
      t.companion_id === companionId && 
      t.appointment_date >= start && 
      t.appointment_date <= end &&
      t.status !== 'cancelled'
    );
    
    // 按日期分组
    const scheduleByDate = {};
    scheduleTasks.forEach(task => {
      const date = task.appointment_date;
      if (!scheduleByDate[date]) {
        scheduleByDate[date] = [];
      }
      scheduleByDate[date].push({
        id: task.id,
        patient_name: task.patient_name,
        hospital_name: task.hospital_name,
        appointment_time: task.appointment_time,
        duration_hours: task.duration_hours,
        service_type: task.service_type,
        status: task.status,
        status_info: taskStatusMap[task.status]
      });
    });
    
    // 按时间排序
    Object.keys(scheduleByDate).forEach(date => {
      scheduleByDate[date].sort((a, b) => a.appointment_time.localeCompare(b.appointment_time));
    });
    
    res.json({
      success: true,
      data: {
        start_date: start,
        end_date: end,
        schedule: scheduleByDate,
        total_tasks: scheduleTasks.length
      },
      message: '获取日程安排成功'
    });
    
  } catch (error) {
    console.error('获取日程安排失败:', error);
    res.status(500).json({
      success: false,
      message: '获取日程安排失败',
      error: error.message
    });
  }
});

// 更新陪诊师状态（在线/离线）
app.put('/api/companion/availability', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { is_available } = req.body;
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }
    
    const companionId = token.split('_')[2];
    const companion = companions.find(c => c.id === companionId);
    
    if (!companion) {
      return res.status(404).json({
        success: false,
        message: '陪诊师不存在'
      });
    }
    
    if (typeof is_available !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: '请提供有效的可用状态'
      });
    }
    
    // 更新状态
    companion.is_available = is_available;
    companion.updated_at = new Date().toISOString();
    
    res.json({
      success: true,
      data: {
        companion_id: companionId,
        is_available,
        updated_at: companion.updated_at
      },
      message: `已${is_available ? '上线' : '下线'}`
    });
    
  } catch (error) {
    console.error('更新可用状态失败:', error);
    res.status(500).json({
      success: false,
      message: '更新可用状态失败',
      error: error.message
    });
  }
});

// ==================== 启动服务器 ====================

app.listen(PORT, () => {
  console.log(`🚀 医小伴陪诊师端API已启动`);
  console.log(`📡 端口：${PORT}`);
  console.log(`🏥 健康检查：http://localhost:${PORT}/health`);
  console.log(`👨‍⚕️ 陪诊师登录：POST http://localhost:${PORT}/api/companion/auth/login`);
  console.log(`📋 任务列表：GET http://localhost:${PORT}/api/companion/tasks`);
  console.log(`📊 统计信息：GET http://localhost:${PORT}/api/companion/statistics`);
  console.log(`📅 日程安排：GET http://localhost:${PORT}/api/companion/schedule`);
  console.log(`\n📝 测试账号：`);
  console.log(`  用户名：zhangyisheng，密码：123456`);
  console.log(`  用户名：lijian，密码：123456`);
  console.log(`\n🎯 功能说明：`);
  console.log(`  1. 陪诊师登录认证`);
  console.log(`  2. 任务管理（接单、开始、完成）`);
  console.log(`  3. 个人统计报表`);
  console.log(`  4. 日程安排查看`);
  console.log(`  5. 在线状态管理`);
});