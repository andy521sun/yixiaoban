/**
 * 医小伴APP - 支付开发服务器
 * 创建时间：2026年4月19日
 */

const express = require('./backend/node_modules/express');
const cors = require('./backend/node_modules/cors');
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
  }
];

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
    res.json({
      success: true,
      data: orders,
      total: orders.length,
      message: '获取订单列表成功'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取订单列表失败',
      error: error.message
    });
  }
});

// 创建订单
app.post('/api/orders', (req, res) => {
  try {
    const { user_id, hospital_id, service_type, price } = req.body;
    
    const newOrder = {
      id: `order_${Date.now()}`,
      user_id: user_id || 'user_001',
      user_name: '测试用户',
      hospital_id: hospital_id || 'hospital_001',
      hospital_name: '测试医院',
      companion_id: 'companion_001',
      companion_name: '测试陪诊师',
      service_type: service_type || '普通陪诊',
      price: price || 200.0,
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
    res.status(500).json({
      success: false,
      message: '创建订单失败',
      error: error.message
    });
  }
});

// ==================== 支付API ====================

// 创建支付订单
app.post('/api/orders/:order_id/payment/create', (req, res) => {
  try {
    const { order_id } = req.params;
    const { payment_method, amount } = req.body;
    
    console.log(`创建支付: ${order_id}, ${payment_method}, ${amount}`);
    
    const order = orders.find(o => o.id === order_id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
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
    
    // 更新订单
    order.payment_method = payment_method;
    order.payment_status = 'processing';
    order.updated_at = new Date().toISOString();
    
    res.json({
      success: true,
      data: payment,
      message: '创建支付订单成功'
    });
    
  } catch (error) {
    console.error('创建支付失败:', error);
    res.status(500).json({
      success: false,
      message: '创建支付失败',
      error: error.message
    });
  }
});

// 模拟支付
app.post('/api/orders/:order_id/payment/simulate/:payment_id', (req, res) => {
  try {
    const { order_id, payment_id } = req.params;
    const { result = 'success' } = req.body;
    
    console.log(`模拟支付: ${order_id}, ${payment_id}, ${result}`);
    
    const order = orders.find(o => o.id === order_id);
    const payment = payments.find(p => p.id === payment_id);
    
    if (!order || !payment) {
      return res.status(404).json({
        success: false,
        message: '订单或支付记录不存在'
      });
    }
    
    // 更新支付状态
    const newStatus = result === 'success' ? 'success' : 'failed';
    const transaction_id = `trans_${Date.now()}`;
    
    payment.status = newStatus;
    payment.transaction_id = transaction_id;
    payment.paid_at = new Date().toISOString();
    
    // 更新订单状态
    if (result === 'success') {
      order.payment_status = 'paid';
      order.status = 'confirmed';
    } else {
      order.payment_status = 'unpaid';
    }
    order.updated_at = new Date().toISOString();
    
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

// 支付状态查询
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
    
    const orderPayments = payments.filter(p => p.order_id === order_id);
    
    res.json({
      success: true,
      data: {
        order_id,
        payment_status: order.payment_status,
        payment_method: order.payment_method,
        amount: order.price,
        payments: orderPayments
      }
    });
    
  } catch (error) {
    console.error('查询支付状态失败:', error);
    res.status(500).json({
      success: false,
      message: '查询支付状态失败',
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
      success_rate: orders.length > 0 ? ((orders.filter(o => o.payment_status === 'paid').length / orders.length) * 100).toFixed(2) : '0.00'
    };
    
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

// 启动服务器
app.listen(PORT, () => {
  console.log(`🚀 医小伴支付开发服务器已启动`);
  console.log(`📡 端口：${PORT}`);
  console.log(`🏥 健康检查：http://localhost:${PORT}/health`);
  console.log(`📋 订单列表：http://localhost:${PORT}/api/orders`);
  console.log(`💰 支付统计：http://localhost:${PORT}/api/payment/statistics`);
  console.log(`\n📝 测试命令：`);
  console.log(`1. 创建订单：curl -X POST http://localhost:${PORT}/api/orders -H "Content-Type: application/json" -d '{"service_type":"测试陪诊","price":250.0}'`);
  console.log(`2. 创建支付：curl -X POST http://localhost:${PORT}/api/orders/order_001/payment/create -H "Content-Type: application/json" -d '{"payment_method":"wechat","amount":229.0}'`);
  console.log(`3. 模拟支付：curl -X POST http://localhost:${PORT}/api/orders/order_001/payment/simulate/pay_xxx -H "Content-Type: application/json" -d '{"result":"success"}'`);
  console.log(`4. 查看统计：curl http://localhost:${PORT}/api/payment/statistics`);
});