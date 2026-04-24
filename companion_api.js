/**
 * 医小伴APP - 陪诊师端API
 * 创建时间：2026年4月19日
 */

const express = require('./backend/node_modules/express');
const cors = require('./backend/node_modules/cors');
const app = express();
const PORT = 3004;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 请求日志
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: '医小伴陪诊师端API',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// ==================== 模拟数据 ====================

// 陪诊师用户
let companions = [
  {
    id: 'comp_001',
    username: 'zhangyisheng',
    password: '123456', // 实际中应该加密
    real_name: '张医生',
    phone: '13800138001',
    id_card: '310101198505151234',
    experience_years: 5,
    specialty: ['内科陪诊', '老年陪护', '报告解读'],
    certification_number: 'CERT2024001',
    introduction: '拥有5年陪诊经验，擅长内科疾病陪诊和老年患者陪护，耐心细致，服务周到。',
    service_count: 128,
    average_rating: 4.8,
    hourly_rate: 200.0,
    is_available: true,
    is_certified: true,
    created_at: '2026-03-30T23:58:39.000Z',
    updated_at: '2026-03-30T23:58:39.000Z'
  },
  {
    id: 'comp_002',
    username: 'lijian',
    password: '123456',
    real_name: '李建国',
    phone: '13800138002',
    id_card: '310101197808221235',
    experience_years: 8,
    specialty: ['全科陪诊', '报告解读', '医患沟通'],
    certification_number: 'CERT2024002',
    introduction: '原三甲医院医生，8年临床经验，精通医学术语，能有效协助医患沟通。',
    service_count: 256,
    average_rating: 4.9,
    hourly_rate: 300.0,
    is_available: true,
    is_certified: true,
    created_at: '2026-03-30T23:58:39.000Z',
    updated_at: '2026-03-30T23:58:39.000Z'
  }
];

// 陪诊师任务（订单）
let companionTasks = [
  {
    id: 'task_001',
    companion_id: 'comp_001',
    order_id: 'order_001',
    patient_name: '张三',
    patient_phone: '13800138000',
    hospital_name: '上海市第一人民医院',
    service_type: '普通陪诊',
    appointment_date: '2026-04-20',
    appointment_time: '09:00',
    duration_hours: 2,
    address: '上海市虹口区武进路85号',
    symptoms: '高血压复查，需要测量血压和咨询用药',
    special_requirements: '需要提前30分钟到达',
    status: 'pending', // pending, accepted, in_progress, completed, cancelled
    price: 229.0,
    payment_status: 'unpaid',
    created_at: '2026-04-19T08:00:00Z',
    updated_at: '2026-04-19T08:00:00Z'
  },
  {
    id: 'task_002',
    companion_id: 'comp_001',
    order_id: 'order_002',
    patient_name: '李四',
    patient_phone: '13800138011',
    hospital_name: '华山医院',
    service_type: '专业陪诊',
    appointment_date: '2026-04-21',
    appointment_time: '14:00',
    duration_hours: 3,
    address: '上海市静安区乌鲁木齐中路12号',
    symptoms: '糖尿病并发症检查',
    special_requirements: '需要协助记录医生建议',
    status: 'accepted',
    price: 320.0,
    payment_status: 'paid',
    created_at: '2026-04-18T10:00:00Z',
    updated_at: '2026-04-18T10:30:00Z'
  },
  {
    id: 'task_003',
    companion_id: 'comp_002',
    order_id: 'order_003',
    patient_name: '王五',
    patient_phone: '13800138022',
    hospital_name: '瑞金医院',
    service_type: '专家陪诊',
    appointment_date: '2026-04-22',
    appointment_time: '10:30',
    duration_hours: 4,
    address: '上海市黄浦区瑞金二路197号',
    symptoms: '心脏不适，需要做心电图和心脏彩超',
    special_requirements: '需要协助排队和取报告',
    status: 'pending',
    price: 450.0,
    payment_status: 'unpaid',
    created_at: '2026-04-19T09:00:00Z',
    updated_at: '2026-04-19T09:00:00Z'
  }
];

// 任务状态映射
const taskStatusMap = {
  pending: { code: 'pending', name: '待接单', color: '#ff9500', action: 'accept' },
  accepted: { code: 'accepted', name: '已接单', color: '#007aff', action: 'start' },
  in_progress: { code: 'in_progress', name: '进行中', color: '#5856d6', action: 'complete' },
  completed: { code: 'completed', name: '已完成', color: '#34c759', action: 'review' },
  cancelled: { code: 'cancelled', name: '已取消', color: '#8e8e93', action: 'none' }
};

// ==================== 认证API ====================

// 陪诊师登录
app.post('/api/companion/auth/login', (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: '请输入用户名和密码'
      });
    }
    
    const companion = companions.find(c => c.username === username && c.password === password);
    
    if (!companion) {
      return res.status(401).json({
        success: false,
        message: '用户名或密码错误'
      });
    }
    
    // 移除密码字段
    const { password: _, ...companionInfo } = companion;
    
    // 生成简单token（实际应该用JWT）
    const token = `comp_token_${companion.id}_${Date.now()}`;
    
    res.json({
      success: true,
      data: {
        token,
        companion: companionInfo,
        expires_in: 86400 // 24小时
      },
      message: '登录成功'
    });
    
  } catch (error) {
    console.error('登录失败:', error);
    res.status(500).json({
      success: false,
      message: '登录失败',
      error: error.message
    });
  }
});

// 获取陪诊师信息
app.get('/api/companion/profile', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }
    
    // 简单验证token（实际应该验证JWT）
    const companionId = token.split('_')[2];
    const companion = companions.find(c => c.id === companionId);
    
    if (!companion) {
      return res.status(401).json({
        success: false,
        message: '认证失败'
      });
    }
    
    const { password, ...companionInfo } = companion;
    
    // 获取今日任务统计
    const today = new Date().toISOString().split('T')[0];
    const todayTasks = companionTasks.filter(t => 
      t.companion_id === companionId && 
      t.appointment_date === today
    );
    
    const stats = {
      total_tasks: companionTasks.filter(t => t.companion_id === companionId).length,
      today_tasks: todayTasks.length,
      pending_tasks: todayTasks.filter(t => t.status === 'pending').length,
      in_progress_tasks: todayTasks.filter(t => t.status === 'in_progress').length,
      completed_tasks: companionTasks.filter(t => t.companion_id === companionId && t.status === 'completed').length,
      total_income: companionTasks
        .filter(t => t.companion_id === companionId && t.payment_status === 'paid')
        .reduce((sum, t) => sum + t.price, 0)
    };
    
    res.json({
      success: true,
      data: {
        companion: companionInfo,
        stats
      },
      message: '获取陪诊师信息成功'
    });
    
  } catch (error) {
    console.error('获取陪诊师信息失败:', error);
    res.status(500).json({
      success: false,
      message: '获取陪诊师信息失败',
      error: error.message
    });
  }
});

// ==================== 任务管理API ====================

// 获取任务列表
app.get('/api/companion/tasks', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { status, date } = req.query;
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }
    
    const companionId = token.split('_')[2];
    
    let tasks = companionTasks.filter(t => t.companion_id === companionId);
    
    // 状态筛选
    if (status) {
      tasks = tasks.filter(t => t.status === status);
    }
    
    // 日期筛选
    if (date) {
      tasks = tasks.filter(t => t.appointment_date === date);
    }
    
    // 添加状态信息
    const enrichedTasks = tasks.map(task => ({
      ...task,
      status_info: taskStatusMap[task.status] || { code: task.status, name: '未知状态' }
    }));
    
    // 按时间排序
    enrichedTasks.sort((a, b) => new Date(a.appointment_date + 'T' + a.appointment_time) - new Date(b.appointment_date + 'T' + b.appointment_time));
    
    res.json({
      success: true,
      data: enrichedTasks,
      total: enrichedTasks.length,
      message: '获取任务列表成功'
    });
    
  } catch (error) {
    console.error('获取任务列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取任务列表失败',
      error: error.message
    });
  }
});

// 获取任务详情
app.get('/api/companion/tasks/:task_id', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { task_id } = req.params;
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }
    
    const companionId = token.split('_')[2];
    const task = companionTasks.find(t => t.id === task_id && t.companion_id === companionId);
    
    if (!task) {
      return res.status(404).json({
        success: false,
        message: '任务不存在或无权访问'
      });
    }
    
    res.json({
      success: true,
      data: {
        ...task,
        status_info: taskStatusMap[task.status] || { code: task.status, name: '未知状态' }
      },
      message: '获取任务详情成功'
    });
    
  } catch (error) {
    console.error('获取任务详情失败:', error);
    res.status(500).json({
      success: false,
      message: '获取任务详情失败',
      error: error.message
    });
  }
});

// 接单（更新任务状态）
app.post('/api/companion/tasks/:task_id/accept', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { task_id } = req.params;
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }
    
    const companionId = token.split('_')[2];
    const task = companionTasks.find(t => t.id === task_id && t.companion_id === companionId);
    
    if (!task) {
      return res.status(404).json({
        success: false,
        message: '任务不存在或无权访问'
      });
    }
    
    if (task.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `任务状态为${taskStatusMap[task.status]?.name || task.status}，无法接单`
      });
    }
    
    // 更新任务状态
    task.status = 'accepted';
    task.updated_at = new Date().toISOString();
    
    res.json({
      success: true,
      data: {
        task_id,
        status: 'accepted',
        status_info: taskStatusMap.accepted,
        updated_at: task.updated_at
      },
      message: '接单成功'
    });
    
  } catch (error) {
    console.error('接单失败:', error);
    res.status(500).json({
      success: false,
      message: '接单失败',
      error: error.message
    });
  }
});

// 开始任务
app.post('/api/companion/tasks/:task_id/start', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { task_id } = req.params;
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }
    
    const companionId = token.split('_')[2];
    const task = companionTasks.find(t => t.id === task_id && t.companion_id === companionId);
    
    if (!task) {
      return res.status(404).json({
        success: false,
        message: '任务不存在或无权访问'
      });
    }
    
    if (task.status !== 'accepted') {
      return res.status(400).json({
        success: false,
        message: `任务状态为${taskStatusMap[task.status]?.name || task.status}，无法开始`
      });
    }
    
    // 更新任务状态
    task.status = 'in_progress';
    task.updated_at = new Date().toISOString();
    
    res.json({
      success: true,
      data: {
        task_id,
        status: 'in_progress',
        status_info: taskStatusMap.in_progress,
        updated_at: task.updated_at,
        start_time: new Date().toISOString()
      },
      message: '任务开始成功'
    });
    
  } catch (error) {
    console.error('开始任务失败:', error);
    res.status(500).json({
      success: false,
      message: '开始任务失败',
      error: error.message
    });
  }
});

// 完成任务
app.post('/api/companion/tasks/:task_id/complete', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { task_id } = req.params;
    const { notes, patient_condition } = req.body;
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }
    
    const companionId = token.split('_')[2];
    const task = companionTasks.find(t => t.id === task_id && t.companion_id === companionId);
    
    if (!task) {
      return res.status(404).json({
        success: false,
        message: '任务不存在或无权访问'
      });
    }
    
    if (task.status !== 'in_progress') {
      return res.status(400).json({
        success: false,
        message: `任务状态为${taskStatusMap[task.status]?.name || task.status}，无法完成`
      });
    }
    
    // 更新任务状态
    task.status = 'completed';
    task.updated_at = new Date().toISOString();
    task.completion_notes = notes;
    task.patient_condition = patient_condition;
    task.completed_at = new Date().toISOString();
    
    res.json({
      success: true,
      data: {
        task_id,
        status: 'completed',
        status_info: taskStatusMap.completed,
        updated_at: task.updated_at,
        completed_at: task.completed_at
      },
      message: '任务完成成功'
    });
    
  } catch (error) {
    console.error('完成任务失败:', error);
    res.status(500).json({
      success: false,
      message: '完成任务失败',
      error: error.message
    });
  }
});

// ==================== 统计API ====================

// 陪诊师统计
app.get('/api/companion/statistics', (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json