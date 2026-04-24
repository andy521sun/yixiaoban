const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 3001; // 使用不同端口

app.use(cors());
app.use(express.json());

// 模拟数据
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

const hospitals = [
  { id: 'hospital_001', name: '北京协和医院', level: '三甲' },
  { id: 'hospital_002', name: '上海华山医院', level: '三甲' },
  { id: 'hospital_003', name: '广州中山医院', level: '三甲' },
];

const companions = [
  { id: 'companion_001', name: '张医生', level: '高级' },
  { id: 'companion_002', name: '李护士', level: '中级' },
];

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: '医小伴测试API（无认证）',
    version: '1.0.0',
  });
});

// 订单列表
app.get('/api/orders', (req, res) => {
  const { user_id } = req.query;
  
  let filteredOrders = [...orders];
  if (user_id) {
    filteredOrders = filteredOrders.filter(o => o.user_id === user_id);
  }
  
  const enrichedOrders = filteredOrders.map(order => ({
    ...order,
    hospital_name: hospitals.find(h => h.id === order.hospital_id)?.name || '未知医院',
    companion_name: companions.find(c => c.id === order.companion_id)?.name || '未知陪诊师',
  }));
  
  res.json({
    success: true,
    data: enrichedOrders,
    message: '获取订单列表成功',
  });
});

// 订单详情
app.get('/api/orders/:id', (req, res) => {
  const order = orders.find(o => o.id === req.params.id);
  
  if (!order) {
    return res.status(404).json({
      success: false,
      message: '订单不存在',
    });
  }
  
  const enrichedOrder = {
    ...order,
    hospital_name: hospitals.find(h => h.id === order.hospital_id)?.name || '未知医院',
    companion_name: companions.find(c => c.id === order.companion_id)?.name || '未知陪诊师',
  };
  
  res.json({
    success: true,
    data: enrichedOrder,
    message: '获取订单详情成功',
  });
});

// 订单统计
app.get('/api/orders/stats', (req, res) => {
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
});

// 医院列表
app.get('/api/hospitals', (req, res) => {
  res.json({
    success: true,
    data: hospitals,
    message: '获取医院列表成功',
  });
});

// 陪诊师列表
app.get('/api/companions', (req, res) => {
  res.json({
    success: true,
    data: companions,
    message: '获取陪诊师列表成功',
  });
});

// 用户登录
app.post('/api/auth/login', (req, res) => {
  res.json({
    success: true,
    data: {
      user_id: 'user_001',
      name: '测试用户',
      phone: '13800138000',
      token: 'test_token_123',
    },
    message: '登录成功',
  });
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`🚀 无认证测试服务器启动成功`);
  console.log(`📡 地址: http://localhost:${PORT}`);
  console.log(`🏥 健康检查: http://localhost:${PORT}/health`);
  console.log(`📊 订单API: http://localhost:${PORT}/api/orders`);
  console.log(`\n按 Ctrl+C 停止服务器`);
});