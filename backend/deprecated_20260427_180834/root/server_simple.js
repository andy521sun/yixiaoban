/**
 * 医小伴APP - 简化开发服务器（专注于支付功能）
 * 创建时间：2026年4月19日
 */

const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3003;

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
    service: '医小伴支付开发服务器',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// 模拟数据库
let orders = [
  {
    id: 'order_001',
    user_id: 'user_001',
    user_name: '张三',
    hospital_id: 'hospital_001',
    hospital_name: '上海市第一人民医院',
    companion_id: 'companion_001',
    companion_name: '张医生',
    service_type: '普通陪诊',
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
    user_name: '张三',
    hospital_id: 'hospital_002',
    hospital_name: '华山医院',
    companion_id: 'companion_002',
    companion_name: '李护士',
    service_type: '专业陪诊',
    price: 320.0,
    status: 'confirmed',
    payment_method: 'wechat',
    payment_status: 'paid',
    created_at: '2026-04-06T10:00:00Z',
    updated_at: '2026-04-06T10:05:00Z',
  },
  {
    id: 'order_003',
    user_id: 'user_002',
    user_name: '李四',
    hospital_id: 'hospital_003',
    hospital_name: '瑞金医院',
    companion_id: 'companion_003',
    companion_name: '王医生',
    service_type: '专家陪诊',
    price: 450.0,
    status: 'pending',
    payment_method: null,
    payment_status: 'unpaid',
    created_at: '2026-04-08T09:00:00Z',
    updated_at: '2026-04-08T09:00:00Z',
  }
];

// 支付方式映射
const paymentMethods = {
  wechat: { code: 'wechat', name: '微信支付', icon: 'wechat.png' },
  alipay: { code: 'alipay', name: '支付宝', icon: 'alipay.png' },
  balance: { code: 'balance', name: '余额支付', icon: 'balance.png' },
  bank_card: { code: 'bank_card', name: '银行卡', icon: 'bank.png' }
};

// 支付状态映射
const paymentStatuses = {
  unpaid: { code: 'unpaid', name: '待支付', color: '#ff9500' },
  processing: { code: 'processing', name: '支付中', color: '#007aff' },
  paid: { code: 'paid', name: '已支付', color: '#34c759' },
  failed: { code: 'failed', name: '支付失败', color: '#ff3b30' },
  refunded: { code: 'refunded', name: '已退款', color: '#8e8e93' }
};

// 支付记录
let payments = [
  {
    id: 'pay_001',
    order_id: 'order_002',
    payment_method: 'wechat',
    amount: 320.0,
    status: 'success',
    transaction_id: 'trans_wx_20260406_001',
    created_at: '2026-04-06T10:00:00Z',
    paid_at: '2026-04-06T10:05:00Z'
  }
];

// ==================== 订单API ====================

// 获取订单列表
app.get('/api/orders', (req, res) => {
  try {
    const { user_id, status } = req.query;
    
    let filteredOrders = [...orders];
    
    if (user_id) {
      filteredOrders = filteredOrders.filter(o => o.user_id === user_id);
    }
    
    if (status) {
      filteredOrders = filteredOrders.filter(o => o.status === status);
    }
    
    res.json({
      success: true,
      data: filteredOrders,
      total: filteredOrders.length,
      message: '获取订单列表成功'
    });
    
  } catch (error) {
    console.error('获取订单列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取订单列表失败',
      error: error.message
    });
  }
});

// 获取订单详情
app.get('/api/orders/:id', (req, res) => {
  try {
    const order = orders.find(o => o.id === req.params.id);
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    // 获取支付记录
    const orderPayments = payments.filter(p => p.order_id === order.id);
    
    res.json({
      success: true,
      data: {
        ...order,
        payments: orderPayments
      },
      message: '获取订单详情成功'
    });
    
  } catch (error) {
    console.error('获取订单详情失败:', error);
    res.status(500).json({
      success: false,
      message: '获取订单详情失败',
      error: error.message
    });
  }
});

// 创建订单
app.post('/api/orders', (req, res) => {
  try {
    const { user_id, user_name, hospital_id, hospital_name, companion_id, companion_name, service_type, price } = req.body;
    
    if (!user_id || !hospital_id || !service_type || !price) {
      return res.status(400).json({
        success: false,
        message: '缺少必要参数'
      });
    }
    
    const newOrder = {
      id: `order_${Date.now()}`,
      user_id,
      user_name: user_name || '用户' + user_id.substr(-4),
      hospital_id,
      hospital_name: hospital_name || '医院' + hospital_id.substr(-4),
      companion_id,
      companion_name: companion_name || '陪诊师' + (companion_id ? companion_id.substr(-4) : '001'),
      service_type,
      price: parseFloat(price),
      status: 'pending',
      payment_method: null,
      payment_status: 'unpaid',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    orders.push(newOrder);
    
    res.json({
      success: true,
      data: newOrder,
      message: '创建订单成功'
    });
    
  } catch (error) {
    console.error('创建订单失败:', error);
    res.status(500).json({
      success: false,
      message: '创建订单失败',
      error: error.message
    });
  }
});

// ==================== 支付API ====================

// 获取支付方式列表
app.get('/api/payment/methods', (req, res) => {
  try {
    const methods = Object.values(paymentMethods).map(method => ({
      ...method,
      enabled: true
    }));
    
    res.json({
      success: true,
      data: methods,
      message: '获取支付方式成功'
    });
    
  } catch (error) {
    console.error('获取支付方式失败:', error);
    res.status(500).json({
      success: false,
      message: '获取支付方式失败',
      error: error.message
    });
  }
});

// 创建支付订单
app.post('/api/orders/:order_id/payment/create', (req, res) => {
  try {
    const { order_id } = req.params;
    const { payment_method, amount } = req.body;
    
    console.log(`创建支付订单: ${order_id}, 方式: ${payment_method}, 金额: ${amount}`);
    
    // 查找订单
    const order = orders.find(o => o.id === order_id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    // 验证支付方式
    if (!paymentMethods[payment_method]) {
      return res.status(400).json({
        success: false,
        message: `无效的支付方式，支持：${Object.keys(paymentMethods).join(', ')}`
      });
    }
    
    // 验证金额
    if (parseFloat(amount) !== order.price) {
      return res.status(400).json({
        success: false,
        message: `支付金额不匹配，订单金额：${order.price}`
      });
    }
    
    // 检查订单状态
    if (order.payment_status === 'paid') {
      return res.status(400).json({
        success: false,
        message: '订单已支付，无需重复支付'
      });
    }
    
    // 生成支付ID
    const payment_id = `pay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 创建支付记录
    const payment = {
      id: payment_id,
      order_id,
      payment_method,
      amount: parseFloat(amount),
      status: 'pending',
      payment_url: `/api/orders/${order_id}/payment/simulate/${payment_id}`,
      created_at: new Date().toISOString()
    };
    
    payments.push(payment);
    
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
app.post('/api/orders/:order_id/payment/simulate/:payment_id', (req, res) => {
  try {
    const { order_id, payment_id } = req.params;
    const { result = 'success' } = req.body;
    
    console.log(`模拟支付: ${order_id}, 支付ID: ${payment_id}, 结果: ${result}`);
    
    // 查找订单
    const order = orders.find(o => o.id === order_id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    // 查找支付记录
    const payment = payments.find(p => p.id === payment_id && p.order_id === order_id);
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: '支付记录不存在'
      });
    }
    
    // 更新支付状态
    const newStatus = result === 'success' ? 'success' : 'failed';
    const transaction_id = `trans_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
    
    payment.status = newStatus;
    payment.transaction_id = transaction_id;
    payment.paid_at = new Date().toISOString();
    
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
        paid_at: payment.paid_at
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
app.get('/api/orders/:order_id/payment/status', (req, res) => {
  try {
    const { order_id } = req.params;
    
    const order = orders.find(o => o.id === order_id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    // 获取支付记录
    const orderPayments = payments.filter(p => p.order_id === order_id);
    
    res.json({
      success: true,
      data: {
        order_id,
        payment_status: order.payment_status,
        payment_method: order.payment_method,
        amount: order.price,
        status_info: paymentStatuses[order.payment_status] || { code: 'unknown', name: '未知状态' },
        method_info: paymentMethods[order.payment_method] || { code: 'unknown', name: '未知方式' },
        payments: orderPayments
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
app.get('/api/payment/statistics', (req, res) => {
  try {
    const stats = {
      total_orders: orders.length,
      total_amount: orders.reduce((sum, o) => sum + o.price, 0),
      paid_orders: orders.filter(o => o.payment_status === 'paid').length,
      paid_amount: orders.filter(o => o.payment_status === 'paid').reduce((sum, o) => sum + o.price, 0),
      unpaid_orders: orders.filter(o => o.payment_status === 'unpaid').length,
      unpaid_amount: orders.filter(o => o.payment_status === 'unpaid').reduce((sum, o) => sum + o.price, 0),
      processing_orders: orders.filter(o => o.payment_status === 'processing').length,
      payment_methods: {},
      daily_stats: {}
    };
    
    // 统计支付方式
    orders.forEach(order => {
      if (order.payment_method) {
        const method = order.payment_method;
        stats.payment_methods[method] = stats.payment_methods[method] || {
          code: method,
          name: paymentMethods[method]?.name || method,
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
    
    // 支付记录统计
    stats.total_payments = payments.length;
    stats.success_payments = payments.filter(p => p.status === 'success').length;
    stats.failed_payments = payments.filter(p => p.status === 'failed').length;
    stats.pending_payments = payments.filter(p => p.status === 'pending').length;
    
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

// 退款申请
app.post('/api/orders/:order_id/payment/refund', (req, res) => {
  try {
    const { order_id } = req.params;
    const { refund_reason } = req.body;
    
    const order = orders.find(o => o.id === order_id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    if (order.payment_status !== 'paid') {
      return res.status(400).json({
        success: false,
        message: '只有已支付的订单才能申请退款'
      });
    }
    
    // 更新订单状态
    order.payment_status = 'refunded';
    order.status = 'cancelled';
    order.updated_at = new Date().toISOString();
    
    // 更新支付记录
    const payment = payments.find(p => p.order_id === order_id && p.status === 'success');
    if (payment) {
      payment.status = 'refunded';
      payment.refunded_at = new Date().toISOString();
    }
    
    res.json({
      success: true,
      message: '退款申请已提交',
      data: {
        order_id,
        refund_amount: order.price,
        refund_reason: refund_reason || '用户申请退款',
        status: 'refunded'
      }
    });
    
  } catch (error) {
    console.error('申请退款失败:', error);
    res.status(500).json({
      success: false,
      message: '申请退款失败',
      error: error.message
    });
  }
});

// ==================== 启动服务器 ====================

app.listen(PORT, () => {
  console.log(`🚀 医小伴支付开发服务器已启动`);
  console.log(`📡 端口：${PORT}`);
  console.log(`🏥 健康检查：http://localhost:${PORT}/health`);
  console.log(`📋 订单列表：http://localhost: