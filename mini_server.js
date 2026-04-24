/**
 * 医小伴APP - 最小化支付测试服务器
 * 创建时间：2026年4月19日
 */

const express = require('./backend/node_modules/express');
const app = express();
const PORT = 3002;

// 中间件
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
});

// 模拟数据库
let orders = [
  {
    id: 'order_001',
    user_id: 'user_001',
    hospital_id: 'hospital_001',
    companion_id: 'companion_001',
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
    hospital_id: 'hospital_002',
    companion_id: 'companion_002',
    service_type: '专业陪诊',
    price: 320.0,
    status: 'confirmed',
    payment_method: 'wechat',
    payment_status: 'paid',
    created_at: '2026-04-06T10:00:00Z',
    updated_at: '2026-04-06T10:05:00Z',
  },
];

// 支付方式映射
const paymentMethods = {
  wechat: '微信支付',
  alipay: '支付宝',
  balance: '余额支付',
  bank_card: '银行卡'
};

// 支付状态映射
const paymentStatuses = {
  pending: '待支付',
  processing: '支付中',
  success: '支付成功',
  failed: '支付失败',
  refunded: '已退款'
};

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: '医小伴支付测试服务器',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// 获取订单列表
app.get('/api/orders', (req, res) => {
  res.json({
    success: true,
    data: orders,
    message: '获取订单列表成功',
    timestamp: new Date().toISOString(),
  });
});

// 获取订单详情
app.get('/api/orders/:id', (req, res) => {
  const order = orders.find(o => o.id === req.params.id);
  
  if (!order) {
    return res.status(404).json({
      success: false,
      message: '订单不存在',
    });
  }
  
  res.json({
    success: true,
    data: order,
    message: '获取订单详情成功',
  });
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
    if (amount !== order.price) {
      return res.status(400).json({
        success: false,
        message: `支付金额不匹配，订单金额：${order.price}`
      });
    }
    
    // 生成支付ID
    const payment_id = `pay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 更新订单支付状态
    order.payment_method = payment_method;
    order.payment_status = 'processing';
    order.updated_at = new Date().toISOString();
    
    res.json({
      success: true,
      data: {
        payment_id,
        order_id,
        payment_method,
        amount,
        status: 'pending',
        payment_url: `/api/orders/${order_id}/payment/simulate/${payment_id}`,
        created_at: new Date().toISOString()
      },
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
    
    res.json({
      success: true,
      data: {
        order_id,
        payment_status: order.payment_status,
        payment_method: order.payment_method,
        amount: order.price,
        status_text: paymentStatuses[order.payment_status] || '未知状态',
        method_text: paymentMethods[order.payment_method] || '未知方式'
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
app.get('/api/orders/payment/statistics', (req, res) => {
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

// 创建新订单
app.post('/api/orders', (req, res) => {
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

// 启动服务
app.listen(PORT, () => {
  console.log(`🚀 医小伴支付测试服务器已启动`);
  console.log(`📡 端口：${PORT}`);
  console.log(`🏥 健康检查：http://localhost:${PORT}/health`);
  console.log(`📋 订单列表：http://localhost:${PORT}/api/orders`);
  console.log(`💳 支付创建：POST http://localhost:${PORT}/api/orders/:order_id/payment/create`);
  console.log(`🔄 模拟支付：POST http://localhost:${PORT}/api/orders/:order_id/payment/simulate/:payment_id`);
  console.log(`📊 支付统计：http://localhost:${PORT}/api/orders/payment/statistics`);
  console.log(`\n📝 示例命令：`);
  console.log(`curl -X POST http://localhost:${PORT}/api/orders/order_001/payment/create -H "Content-Type: application/json" -d '{"payment_method":"wechat","amount":229.0}'`);
});