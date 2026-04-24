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
  }
];

// 模拟用户数据
const users = [
  { id: 'user_001', name: '张三', phone: '13800138000' }
];

// 模拟医院数据
const hospitals = [
  { id: 'hospital_001', name: '北京协和医院', level: '三甲' }
];

// 模拟陪诊师数据
const companions = [
  { id: 'companion_001', name: '李医生', level: '高级' }
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
  
  // 这里应该验证token
  // 暂时跳过
  next();
};

// 获取订单列表
router.get('/', devAuthMiddleware, (req, res) => {
  try {
    const { user_id, status, page = 1, limit = 10 } = req.query;
    
    let filteredOrders = [...orders];
    
    // 按用户ID过滤
    if (user_id) {
      filteredOrders = filteredOrders.filter(order => order.user_id === user_id);
    }
    
    // 按状态过滤
    if (status) {
      filteredOrders = filteredOrders.filter(order => order.status === status);
    }
    
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
        hospital_name: hospital?.name || '未知医院',
        companion_name: companion?.name || '未知陪诊师',
      };
    });
    
    res.json({
      success: true,
      data: enrichedOrders,
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

// 获取单个订单
router.get('/:id', devAuthMiddleware, (req, res) => {
  try {
    const { id } = req.params;
    const order = orders.find(o => o.id === id);
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在',
      });
    }
    
    // 丰富订单数据
    const user = users.find(u => u.id === order.user_id);
    const hospital = hospitals.find(h => h.id === order.hospital_id);
    const companion = companions.find(c => c.id === order.companion_id);
    
    const enrichedOrder = {
      ...order,
      user_info: user || null,
      hospital_info: hospital || null,
      companion_info: companion || null,
    };
    
    res.json({
      success: true,
      data: enrichedOrder,
    });
  } catch (error) {
    console.error('获取订单失败:', error);
    res.status(500).json({
      success: false,
      message: '获取订单失败',
      error: error.message,
    });
  }
});

// 创建订单
router.post('/', devAuthMiddleware, (req, res) => {
  try {
    const {
      user_id,
      hospital_id,
      companion_id,
      service_type = '普通陪诊',
      appointment_time,
      duration_minutes = 120,
    } = req.body;
    
    // 验证必填字段
    if (!user_id || !hospital_id || !companion_id || !appointment_time) {
      return res.status(400).json({
        success: false,
        message: '缺少必填字段',
        required_fields: ['user_id', 'hospital_id', 'companion_id', 'appointment_time'],
      });
    }
    
    // 验证用户是否存在
    const user = users.find(u => u.id === user_id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: '用户不存在',
      });
    }
    
    // 验证医院是否存在
    const hospital = hospitals.find(h => h.id === hospital_id);
    if (!hospital) {
      return res.status(404).json({
        success: false,
        message: '医院不存在',
      });
    }
    
    // 验证陪诊师是否存在
    const companion = companions.find(c => c.id === companion_id);
    if (!companion) {
      return res.status(404).json({
        success: false,
        message: '陪诊师不存在',
      });
    }
    
    // 计算价格
    const price = calculatePrice(service_type, duration_minutes, companion.level);
    
    // 创建新订单
    const newOrder = {
      id: `order_${uuidv4().substring(0, 8)}`,
      user_id,
      hospital_id,
      companion_id,
      service_type,
      appointment_time,
      duration_minutes,
      price,
      status: 'pending',
      payment_method: null,
      payment_status: 'unpaid',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    orders.push(newOrder);
    
    // 丰富返回数据
    const enrichedOrder = {
      ...newOrder,
      user_name: user.name,
      hospital_name: hospital.name,
      companion_name: companion.name,
    };
    
    res.status(201).json({
      success: true,
      message: '订单创建成功',
      data: enrichedOrder,
      payment_info: {
        order_id: newOrder.id,
        amount: price,
        currency: 'CNY',
        payment_url: `https://payment.example.com/pay/${newOrder.id}`,
      },
    });
  } catch (error) {
    console.error('创建订单失败:', error);
    res.status(500).json({
      success: false,
      message: '创建订单失败',
      error: error.message,
    });
  }
});

// 更新订单状态
router.patch('/:id/status', devAuthMiddleware, (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    const validStatuses = ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'];
    
    if (!status || !validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: '无效的状态',
        valid_statuses: validStatuses,
      });
    }
    
    const orderIndex = orders.findIndex(o => o.id === id);
    
    if (orderIndex === -1) {
      return res.status(404).json({
        success: false,
        message: '订单不存在',
      });
    }
    
    // 更新订单状态
    orders[orderIndex].status = status;
    orders[orderIndex].updated_at = new Date().toISOString();
    
    res.json({
      success: true,
      message: '订单状态更新成功',
      data: orders[orderIndex],
    });
  } catch (error) {
    console.error('更新订单状态失败:', error);
    res.status(500).json({
      success: false,
      message: '更新订单状态失败',
      error: error.message,
    });
  }
});

// 支付订单
router.post('/:id/pay', devAuthMiddleware, (req, res) => {
  try {
    const { id } = req.params;
    const { payment_method, payment_amount } = req.body;
    
    const orderIndex = orders.findIndex(o => o.id === id);
    
    if (orderIndex === -1) {
      return res.status(404).json({
        success: false,
        message: '订单不存在',
      });
    }
    
    const order = orders[orderIndex];
    
    // 验证订单状态
    if (order.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: '订单状态不允许支付',
        current_status: order.status,
      });
    }
    
    // 验证支付金额
    if (payment_amount !== order.price) {
      return res.status(400).json({
        success: false,
        message: '支付金额不正确',
        expected_amount: order.price,
        provided_amount: payment_amount,
      });
    }
    
    // 更新订单支付信息
    orders[orderIndex].payment_method = payment_method;
    orders[orderIndex].payment_status = 'paid';
    orders[orderIndex].status = 'confirmed';
    orders[orderIndex].updated_at = new Date().toISOString();
    
    res.json({
      success: true,
      message: '支付成功',
      data: {
        order_id: order.id,
        payment_status: 'paid',
        order_status: 'confirmed',
        payment_time: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error('支付订单失败:', error);
    res.status(500).json({
      success: false,
      message: '支付订单失败',
      error: error.message,
    });
  }
});

// 取消订单
router.post('/:id/cancel', devAuthMiddleware, (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    
    const orderIndex = orders.findIndex(o => o.id === id);
    
    if (orderIndex === -1) {
      return res.status(404).json({
        success: false,
        message: '订单不存在',
      });
    }
    
    const order = orders[orderIndex];
    
    // 验证订单状态是否可以取消
    const cancellableStatuses = ['pending', 'confirmed'];
    if (!cancellableStatuses.includes(order.status)) {
      return res.status(400).json({
        success: false,
        message: '当前订单状态不允许取消',
        current_status: order.status,
        cancellable_statuses: cancellableStatuses,
      });
    }
    
    // 更新订单状态
    orders[orderIndex].status = 'cancelled';
    orders[orderIndex].updated_at = new Date().toISOString();
    
    // 如果已支付，需要退款
    if (order.payment_status === 'paid') {
      orders[orderIndex].payment_status = 'refunded';
      // 这里应该调用退款API
    }
    
    res.json({
      success: true,
      message: '订单取消成功',
      data: {
        order_id: order.id,
        status: 'cancelled',
        refund_status: order.payment_status === 'paid' ? 'pending' : 'not_applicable',
        cancellation_time: new Date().toISOString(),
        reason: reason || '用户取消',
      },
    });
  } catch (error) {
    console.error('取消订单失败:', error);
    res.status(500).json({
      success: false,
      message: '取消订单失败',
      error: error.message,
    });
  }
});

// 计算价格函数
function calculatePrice(serviceType, durationMinutes, companionLevel) {
  let basePrice = 199.0;
  const serviceFee = 30.0;
  
  // 根据服务类型调整价格
  switch (serviceType) {
    case '专业陪诊':
      basePrice *= 1.5;
      break;
    case '急诊陪诊':
      basePrice *= 2.0;
      break;
    case '长期陪护':
      basePrice *= 3.0;
      break;
  }
  
  // 根据时长调整价格
  const hours = durationMinutes / 60;
  basePrice *= hours;
  
  // 陪诊师等级加成
  switch (companionLevel) {
    case '高级':
      basePrice *= 1.3;
      break;
    case '专家':
      basePrice *= 1.5;
      break;
  }
  
  return parseFloat((basePrice + serviceFee).toFixed(2));
}

// 导出路由
module.exports = router;