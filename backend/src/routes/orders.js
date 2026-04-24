const express = require('express');
const router = express.Router();

// 模拟数据库
const orders = [
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
];

// 模拟数据
const users = [{ id: 'user_001', name: '张三' }];
const hospitals = [
  { id: 'hospital_001', name: '北京协和医院' },
  { id: 'hospital_002', name: '上海华山医院' },
];
const companions = [
  { id: 'companion_001', name: '张医生' },
  { id: 'companion_002', name: '李护士' },
];

// 完全跳过认证
router.use((req, res, next) => {
  // 添加支付相关功能
  req.paymentMethods = {
    wechat: '微信支付',
    alipay: '支付宝',
    balance: '余额支付',
    bank_card: '银行卡'
  };
  
  req.paymentStatuses = {
    pending: '待支付',
    processing: '支付中',
    success: '支付成功',
    failed: '支付失败',
    refunded: '已退款'
  };
  
  next();
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// 获取订单列表
router.get('/', (req, res) => {
  try {
    const { user_id } = req.query;
    
    let filteredOrders = [...orders];
    if (user_id) {
      filteredOrders = filteredOrders.filter(o => o.user_id === user_id);
    }
    
    const enrichedOrders = filteredOrders.map(order => ({
      ...order,
      user_name: users.find(u => u.id === order.user_id)?.name || '未知用户',
      hospital_name: hospitals.find(h => h.id === order.hospital_id)?.name || '未知医院',
      companion_name: companions.find(c => c.id === order.companion_id)?.name || '未知陪诊师',
    }));
    
    res.json({
      success: true,
      data: enrichedOrders,
      message: '获取订单列表成功',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取订单列表失败',
      error: error.message,
    });
  }
});

// 获取订单详情
router.get('/:id', (req, res) => {
  try {
    const order = orders.find(o => o.id === req.params.id);
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在',
      });
    }
    
    const enrichedOrder = {
      ...order,
      user_name: users.find(u => u.id === order.user_id)?.name || '未知用户',
      hospital_name: hospitals.find(h => h.id === order.hospital_id)?.name || '未知医院',
      companion_name: companions.find(c => c.id === order.companion_id)?.name || '未知陪诊师',
    };
    
    res.json({
      success: true,
      data: enrichedOrder,
      message: '获取订单详情成功',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取订单详情失败',
      error: error.message,
    });
  }
});

// 订单统计
router.get('/stats', (req, res) => {
  try {
    const { user_id } = req.query;
    
    let filteredOrders = [...orders];
    if (user_id) {
      filteredOrders = filteredOrders.filter(o => o.user_id === user_id);
    }
    
    const stats = {
      total_orders: filteredOrders.length,
      total_amount: filteredOrders.reduce((sum, o) => sum + o.price, 0),
      status_counts: {
        pending: filteredOrders.filter(o => o.status === 'pending').length,
        confirmed: filteredOrders.filter(o => o.status === 'confirmed').length,
        completed: filteredOrders.filter(o => o.status === 'completed').length,
        cancelled: filteredOrders.filter(o => o.status === 'cancelled').length,
      }
    };
    
    res.json({
      success: true,
      data: stats,
      message: '获取订单统计成功',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取订单统计失败',
      error: error.message,
    });
  }
});

// 创建订单
router.post('/', (req, res) => {
  try {
    const newOrder = {
      id: `order_${Date.now()}`,
      ...req.body,
      status: 'pending',
      payment_status: 'unpaid',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    orders.push(newOrder);
    
    res.json({
      success: true,
      data: newOrder,
      message: '创建订单成功',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '创建订单失败',
      error: error.message,
    });
  }
});

// ==================== 支付功能 ====================

// 创建支付订单
router.post('/:order_id/payment/create', (req, res) => {
  try {
    const { order_id } = req.params;
    const { payment_method, amount } = req.body;
    
    // 查找订单
    const order = orders.find(o => o.id === order_id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    // 验证支付方式
    if (!req.paymentMethods[payment_method]) {
      return res.status(400).json({
        success: false,
        message: `无效的支付方式，支持：${Object.keys(req.paymentMethods).join(', ')}`
      });
    }
    
    // 验证金额
    if (amount !== order.price) {
      return res.status(400).json({
        success: false,
        message: `支付金额不匹配，订单金额：${order.price}`
      });
    }
    
    // 生成支付ID
    const payment_id = `pay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 创建支付记录
    const payment = {
      payment_id,
      order_id,
      payment_method,
      amount,
      status: 'pending',
      payment_url: `/api/orders/${order_id}/payment/simulate/${payment_id}`,
      created_at: new Date().toISOString()
    };
    
    // 更新订单支付状态
    order.payment_method = payment_method;
    order.payment_status = 'processing';
    order.updated_at = new Date().toISOString();
    
    res.json({
      success: true,
      data: payment,
      message: '创建支付订单成功'
    });
    
  } catch (error) {
    console.error('创建支付订单失败:', error);
    res.status(500).json({
      success: false,
      message: '创建支付订单失败',
      error: error.message
    });
  }
});

// 模拟支付
router.post('/:order_id/payment/simulate/:payment_id', (req, res) => {
  try {
    const { order_id, payment_id } = req.params;
    const { result = 'success' } = req.body;
    
    // 查找订单
    const order = orders.find(o => o.id === order_id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    // 更新支付状态
    const newStatus = result === 'success' ? 'success' : 'failed';
    const transaction_id = `trans_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
    
    // 更新订单状态
    if (result === 'success') {
      order.payment_status = 'paid';
      order.status = 'confirmed';
      order.updated_at = new Date().toISOString();
    } else {
      order.payment_status = 'unpaid';
      order.updated_at = new Date().toISOString();
    }
    
    res.json({
      success: true,
      message: `模拟支付${result === 'success' ? '成功' : '失败'}`,
      data: {
        payment_id,
        order_id,
        status: newStatus,
        transaction_id,
        paid_at: new Date().toISOString()
      }
    });
    
  } catch (error) {
    console.error('模拟支付失败:', error);
    res.status(500).json({
      success: false,
      message: '模拟支付失败',
      error: error.message
    });
  }
});

// 获取支付状态
router.get('/:order_id/payment/status', (req, res) => {
  try {
    const { order_id } = req.params;
    
    const order = orders.find(o => o.id === order_id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    res.json({
      success: true,
      data: {
        order_id,
        payment_status: order.payment_status,
        payment_method: order.payment_method,
        amount: order.price,
        status_text: req.paymentStatuses[order.payment_status] || '未知状态',
        method_text: req.paymentMethods[order.payment_method] || '未知方式'
      }
    });
    
  } catch (error) {
    console.error('获取支付状态失败:', error);
    res.status(500).json({
      success: false,
      message: '获取支付状态失败',
      error: error.message
    });
  }
});

// 支付统计
router.get('/payment/statistics', (req, res) => {
  try {
    const stats = {
      total_orders: orders.length,
      total_amount: orders.reduce((sum, o) => sum + o.price, 0),
      paid_orders: orders.filter(o => o.payment_status === 'paid').length,
      paid_amount: orders.filter(o => o.payment_status === 'paid').reduce((sum, o) => sum + o.price, 0),
      unpaid_orders: orders.filter(o => o.payment_status === 'unpaid').length,
      unpaid_amount: orders.filter(o => o.payment_status === 'unpaid').reduce((sum, o) => sum + o.price, 0),
      payment_methods: {}
    };
    
    // 统计支付方式
    orders.forEach(order => {
      if (order.payment_method) {
        const method = order.payment_method;
        stats.payment_methods[method] = stats.payment_methods[method] || {
          count: 0,
          amount: 0
        };
        stats.payment_methods[method].count++;
        stats.payment_methods[method].amount += order.price;
      }
    });
    
    // 计算成功率
    stats.success_rate = stats.total_orders > 0 
      ? ((stats.paid_orders / stats.total_orders) * 100).toFixed(2)
      : '0.00';
    
    res.json({
      success: true,
      data: stats
    });
    
  } catch (error) {
    console.error('获取支付统计失败:', error);
    res.status(500).json({
      success: false,
      message: '获取支付统计失败',
      error: error.message
    });
  }
});

module.exports = router;