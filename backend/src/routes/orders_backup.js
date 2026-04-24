const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// 模拟数据库 - 实际开发中替换为真实数据库
let orders = [
  {
    id: 'order_001',
    user_id: 'user_001',
    hospital_id: 'hospital_001',
    companion_id: 'companion_001',
    service_type: '普通陪诊',
    appointment_time: '2026-04-08T09:00:00Z',
    duration_minutes: 120,
    price: 229.0,
    status: 'pending',
    payment_method: null,
    payment_status: 'unpaid',
    created_at: '2026-04-07T08:00:00Z',
    updated_at: '2026-04-07T08:00:00Z',
  },
  {
    id: 'order_002',
    user_id: 'user_001',
    hospital_id: 'hospital_002',
    companion_id: 'companion_002',
    service_type: '专业陪诊',
    appointment_time: '2026-04-09T14:00:00Z',
    duration_minutes: 180,
    price: 320.0,
    status: 'confirmed',
    payment_method: 'wechat',
    payment_status: 'paid',
    created_at: '2026-04-06T10:00:00Z',
    updated_at: '2026-04-06T10:05:00Z',
  },
  {
    id: 'order_003',
    user_id: 'user_001',
    hospital_id: 'hospital_003',
    companion_id: 'companion_003',
    service_type: '急诊陪诊',
    appointment_time: '2026-04-07T10:00:00Z',
    duration_minutes: 240,
    price: 450.0,
    status: 'completed',
    payment_method: 'alipay',
    payment_status: 'paid',
    created_at: '2026-04-05T09:00:00Z',
    updated_at: '2026-04-07T12:00:00Z',
  },
  {
    id: 'order_004',
    user_id: 'user_002',
    hospital_id: 'hospital_001',
    companion_id: 'companion_001',
    service_type: '普通陪诊',
    appointment_time: '2026-04-10T11:00:00Z',
    duration_minutes: 120,
    price: 229.0,
    status: 'cancelled',
    payment_method: null,
    payment_status: 'unpaid',
    created_at: '2026-04-04T15:00:00Z',
    updated_at: '2026-04-04T16:00:00Z',
  },
];

// 模拟用户数据
const users = [
  { id: 'user_001', name: '张三', phone: '13800138000' },
  { id: 'user_002', name: '李四', phone: '13900139000' }
];

// 模拟医院数据
const hospitals = [
  { id: 'hospital_001', name: '北京协和医院', level: '三甲', address: '北京市东城区帅府园1号' },
  { id: 'hospital_002', name: '上海华山医院', level: '三甲', address: '上海市静安区乌鲁木齐中路12号' },
  { id: 'hospital_003', name: '广州中山医院', level: '三甲', address: '广州市越秀区中山二路58号' }
];

// 模拟陪诊师数据
const companions = [
  { id: 'companion_001', name: '张医生', level: '高级', specialty: '全科陪诊' },
  { id: 'companion_002', name: '李护士', level: '中级', specialty: '儿科陪诊' },
  { id: 'companion_003', name: '王医生', level: '专家', specialty: '老年科陪诊' }
];

// 简单的认证中间件（开发环境跳过）
const devAuthMiddleware = (req, res, next) => {
  // 开发环境跳过认证
  if (process.env.NODE_ENV === 'development') {
    return next();
  }
  
  // 生产环境需要认证
  const token = req.headers.authorization;
  if (!token) {
    return res.status(401).json({
      success: false,
      message: '访问令牌缺失',
    });
  }
  
  next();
};

// 获取订单列表（增强版）
router.get('/', devAuthMiddleware, (req, res) => {
  try {
    const { 
      user_id, 
      status, 
      search,
      start_date,
      end_date,
      min_price,
      max_price,
      page = 1, 
      limit = 10,
      sort_by = 'created_at',
      sort_order = 'desc'
    } = req.query;
    
    let filteredOrders = [...orders];
    
    // 按用户ID过滤
    if (user_id) {
      filteredOrders = filteredOrders.filter(order => order.user_id === user_id);
    }
    
    // 按状态过滤
    if (status) {
      filteredOrders = filteredOrders.filter(order => order.status === status);
    }
    
    // 搜索功能
    if (search) {
      filteredOrders = filteredOrders.filter(order => {
        const orderId = order.id.toLowerCase();
        const hospital = hospitals.find(h => h.id === order.hospital_id);
        const companion = companions.find(c => c.id === order.companion_id);
        const hospitalName = hospital?.name?.toLowerCase() || '';
        const companionName = companion?.name?.toLowerCase() || '';
        const searchTerm = search.toLowerCase();
        
        return orderId.includes(searchTerm) ||
               hospitalName.includes(searchTerm) ||
               companionName.includes(searchTerm);
      });
    }
    
    // 按日期范围过滤
    if (start_date) {
      const startDate = new Date(start_date);
      filteredOrders = filteredOrders.filter(order => {
        const orderDate = new Date(order.created_at);
        return orderDate >= startDate;
      });
    }
    
    if (end_date) {
      const endDate = new Date(end_date);
      filteredOrders = filteredOrders.filter(order => {
        const orderDate = new Date(order.created_at);
        return orderDate <= endDate;
      });
    }
    
    // 按价格范围过滤
    if (min_price) {
      const minPrice = parseFloat(min_price);
      filteredOrders = filteredOrders.filter(order => order.price >= minPrice);
    }
    
    if (max_price) {
      const maxPrice = parseFloat(max_price);
      filteredOrders = filteredOrders.filter(order => order.price <= maxPrice);
    }
    
    // 排序
    filteredOrders.sort((a, b) => {
      let aValue, bValue;
      
      switch (sort_by) {
        case 'price':
          aValue = a.price;
          bValue = b.price;
          break;
        case 'appointment_time':
          aValue = new Date(a.appointment_time);
          bValue = new Date(b.appointment_time);
          break;
        case 'created_at':
        default:
          aValue = new Date(a.created_at);
          bValue = new Date(b.created_at);
          break;
      }
      
      if (sort_order === 'asc') {
        return aValue > bValue ? 1 : -1;
      } else {
        return aValue < bValue ? 1 : -1;
      }
    });
    
    // 分页
    const startIndex = (page - 1) * limit;
    const endIndex = page * limit;
    const paginatedOrders = filteredOrders.slice(startIndex, endIndex);
    
    // 丰富订单数据
    const enrichedOrders = paginatedOrders.map(order => {
      const user = users.find(u => u.id === order.user_id);
      const hospital = hospitals.find(h => h.id === order.hospital_id);
      const companion = companions.find(c => c.id === order.companion_id);
      
      return {
        ...order,
        user_name: user?.name || '未知用户',
        user_phone: user?.phone || '',
        hospital_name: hospital?.name || '未知医院',
        hospital_level: hospital?.level || '',
        hospital_address: hospital?.address || '',
        companion_name: companion?.name || '未知陪诊师',
        companion_level: companion?.level || '',
        companion_specialty: companion?.specialty || '',
      };
    });
    
    // 统计信息
    const stats = {
      total: filteredOrders.length,
      total_amount: filteredOrders.reduce((sum, order) => sum + order.price, 0),
      status_counts: {
        pending: filteredOrders.filter(o => o.status === 'pending').length,
        confirmed: filteredOrders.filter(o => o.status === 'confirmed').length,
        in_progress: filteredOrders.filter(o => o.status === 'in_progress').length,
        completed: filteredOrders.filter(o => o.status === 'completed').length,
        cancelled: filteredOrders.filter(o => o.status === 'cancelled').length,
      }
    };
    
    res.json({
      success: true,
      data: enrichedOrders,
      stats: stats,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: filteredOrders.length,
        total_pages: Math.ceil(filteredOrders.length / limit),
      },
    });
  } catch (error) {
    console.error('获取订单列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取订单列表失败',
      error: error.message,
    });
  }
});

// 获取订单统计信息
router.get('/stats', devAuthMiddleware, (req, res) => {
  try {
    const { user_id, start_date, end_date } = req.query;
    
    let filteredOrders = [...orders];
    
    // 按用户ID过滤
    if (user_id) {
      filteredOrders = filteredOrders.filter(order => order.user_id === user_id);
    }
    
    // 按日期范围过滤
    if (start_date) {
      const startDate = new Date(start_date);
      filteredOrders = filteredOrders.filter(order => {
        const orderDate = new Date(order.created_at);
        return orderDate >= startDate;
      });
    }
    
    if (end_date) {
      const endDate = new Date(end_date);
      filteredOrders = filteredOrders.filter(order => {
        const orderDate = new Date(order.created_at);
        return orderDate <= endDate;
      });
    }
    
    // 计算统计信息
    const totalOrders = filteredOrders.length;
    const totalAmount = filteredOrders.reduce((sum, order) => sum + order.price, 0);
    const avgOrderValue = totalOrders > 0 ? totalAmount / totalOrders : 0;
    
    // 状态统计
    const statusStats = {
      pending: filteredOrders.filter(o => o.status === 'pending').length,
      confirmed: filteredOrders.filter(o => o.status === 'confirmed').length,
      in_progress: filteredOrders.filter(o => o.status === 'in_progress').length,
      completed: filteredOrders.filter(o => o.status === 'completed').length,
      cancelled: filteredOrders.filter(o => o.status === 'cancelled').length,
    };
    
    // 服务类型统计
    const serviceTypeStats = {};
    filteredOrders.forEach(order => {
      const type = order.service_type;
      serviceTypeStats[type] = (serviceTypeStats[type] || 0) + 1;
    });
    
    // 支付方式统计
    const paymentMethodStats = {};
    filteredOrders.forEach(order => {
      if (order.payment_method) {
        const method = order.payment_method;
        paymentMethodStats[method] = (paymentMethodStats[method] || 0) + 1;
      }
    });
    
    // 月度趋势（最近6个月）
    const monthlyTrends = {};
    const now = new Date();
    for (let i = 5; i >= 0; i--) {
      const month = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthKey = `${month.getFullYear()}-${(month.getMonth() + 1).toString().padStart(2, '0')}`;
      
      const monthOrders = filteredOrders.filter(order => {
        const orderDate = new Date(order.created_at);
        return orderDate.getFullYear() === month.getFullYear() &&
               orderDate.getMonth() === month.getMonth();
      });
      
      monthlyTrends[monthKey] = {
        count: monthOrders.length,
        amount: monthOrders.reduce((sum, order) => sum + order.price, 0),
      };
    }
    
    res.json({
      success: true,
      data: {
        summary: {
          total_orders: totalOrders,
          total_amount: totalAmount,
          avg_order_value: avgOrderValue,
          completion_rate: totalOrders > 0 
            ? (statusStats.completed / totalOrders * 100).toFixed(2) + '%'
            : '0%',
        },
        status_stats: statusStats,
        service_type_stats: serviceTypeStats,
        payment_method_stats: paymentMethodStats,
        monthly_trends: monthlyTrends,
        recent_orders: filteredOrders
          .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
          .slice(0, 5)
          .map(order => ({
            id: order.id,
            hospital_name: hospitals.find(h => h.id === order.hospital_id)?.name || '未知医院',
            price: order.price,
            status: order.status,
            created_at: order.created_at,
          })),
      },
    });
  } catch (error) {
    console.error('获取订单统计失败:', error);
    res.status(500).json({
      success: false,
      message: '获取订单统计失败',
      error: error.message,
    });
  }
});

// 批量操作
router.post('/batch', devAuthMiddleware, (req, res) => {
  try {
    const { action, order_ids, data } = req.body;
    
    if (!action || !order_ids || !Array.isArray(order_ids)) {
      return res.status(400).json({
        success: false,
        message: '缺少必要参数',
        required: ['action', 'order_ids'],
      });
    }
    
    const validActions = ['cancel', 'confirm', 'complete', 'update_status'];
    if (!validActions.includes(action)) {
      return res.status(400).json({
        success: false,
        message: '无效的操作',
        valid_actions: validActions,
      });
    }
    
    const results = [];
    const errors = [];
    
    order_ids.forEach(orderId => {
      const orderIndex = orders.findIndex(o => o.id === orderId);
      
      if (orderIndex === -1) {
        errors.push({
          order_id: orderId,
          error: '订单不存在',
        });
        return;
      }
      
      try {
        const order = orders[orderIndex];
        
        switch (action) {
          case 'cancel':
            if (order.status !== 'pending' && order.status !== 'confirmed') {
              errors.push({
                order_id: orderId,
                error: '订单状态不允许取消',
                current_status: order.status,
              });
              return;
            }
            
            orders[orderIndex].status = 'cancelled';
            orders[orderIndex].cancellation_reason = data?.reason || '批量取消';
            orders[orderIndex].cancelled_at = new Date().toISOString();
            orders[orderIndex].updated_at = new Date().toISOString();
            
            if (order.payment_status === 'paid') {
              orders[orderIndex].payment_status = 'refunded';
            }
            break;
            
          case 'confirm':
            if (order.status !== 'pending') {
              errors.push({
                order_id: orderId,
                error: '只有待支付订单可以确认',
                current_status: order.status,
              });
              return;
            }
            
            orders[orderIndex].status = 'confirmed';
            orders[orderIndex].updated_at = new Date().toISOString();
            break;
            
          case 'complete':
            if (order.status !== 'in_progress') {
              errors.push({
                order_id: orderId,
                error: '只有进行中订单可以完成',
                current_status: order.status,
              });
              return;
            }
            
            orders[orderIndex].status = 'completed';
            orders[orderIndex].completed_at = new Date().toISOString();
            orders[orderIndex].updated_at = new Date().toISOString();
            break;
            
          case 'update_status':
            if (!data?.status) {
              errors.push({
                order_id: orderId,
                error: '缺少状态参数',
              });
              return;
            }
            
            const validStatuses = ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'];
            if (!validStatuses.includes(data.status)) {
              errors.push({
                order_id: orderId,
                error: '无效的状态',
                valid_statuses: validStatuses,
              });
              return;
            }
            
            orders[orderIndex].status = data.status;
            orders[orderIndex].updated_at = new Date().toISOString();
            
            // 设置相关时间戳
            if (data.status === 'cancelled') {
              orders[orderIndex].cancelled_at = new Date().toISOString();
            } else if (data.status === 'completed') {
              orders[orderIndex].completed_at = new Date().toISOString();
            }
            break;
        }
        
        results.push({
          order_id: orderId,
          success: true,
          new_status: orders[orderIndex].status,
        });
        
      } catch (error) {
        errors.push({
          order_id: orderId,
          error: error.message,
        });
      }
    });
    
    res.json({
      success: true,
      message: `批量操作完成，成功: ${results.length}，失败: ${errors.length}`,
      results: results,
      errors: errors.length > 0 ? errors : undefined,
    });
  } catch (error) {
    console.error('批量操作失败:', error);
    res.status(500).json({
      success: false,
      message: '批量操作失败',
      error: error.message,
    });
