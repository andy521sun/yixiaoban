const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: '医小伴测试API',
    version: '1.0.0',
  });
});

// API文档
app.get('/api', (req, res) => {
  res.json({
    message: '医小伴测试API',
    endpoints: {
      health: 'GET /health',
      auth: {
        login: 'POST /api/auth/login',
        profile: 'GET /api/auth/profile',
      },
      hospitals: 'GET /api/hospitals',
      companions: 'GET /api/companions',
      orders: 'GET /api/orders',
      payments: 'POST /api/payments/create',
    }
  });
});

// 模拟认证路由
app.post('/api/auth/login', (req, res) => {
  res.json({
    success: true,
    data: {
      user_id: 'user_001',
      name: '测试用户',
      token: 'test_token_123',
    },
    message: '登录成功',
  });
});

app.get('/api/auth/profile', (req, res) => {
  res.json({
    success: true,
    data: {
      user_id: 'user_001',
      name: '测试用户',
      phone: '13800138000',
      email: 'test@example.com',
      created_at: '2026-04-01T00:00:00Z',
    },
    message: '获取用户信息成功',
  });
});

// 模拟医院数据
app.get('/api/hospitals', (req, res) => {
  const hospitals = [
    { id: 'hosp_001', name: '北京协和医院', level: '三甲', address: '北京市东城区帅府园1号' },
    { id: 'hosp_002', name: '上海华山医院', level: '三甲', address: '上海市静安区乌鲁木齐中路12号' },
    { id: 'hosp_003', name: '广州中山医院', level: '三甲', address: '广州市越秀区中山二路58号' },
    { id: 'hosp_004', name: '深圳人民医院', level: '三甲', address: '深圳市罗湖区东门北路1017号' },
    { id: 'hosp_005', name: '成都华西医院', level: '三甲', address: '成都市武侯区国学巷37号' },
  ];
  
  res.json({
    success: true,
    data: hospitals,
    message: '获取医院列表成功',
  });
});

app.get('/api/hospitals/:id', (req, res) => {
  const hospital = {
    id: req.params.id,
    name: '北京协和医院',
    level: '三甲',
    address: '北京市东城区帅府园1号',
    phone: '010-69151188',
    description: '中国最著名的综合性医院之一',
    departments: ['内科', '外科', '儿科', '妇产科', '眼科'],
  };
  
  res.json({
    success: true,
    data: hospital,
    message: '获取医院详情成功',
  });
});

// 模拟陪诊师数据
app.get('/api/companions', (req, res) => {
  const companions = [
    { id: 'companion_001', name: '张医生', level: '高级', specialty: '全科陪诊', rating: 4.8 },
    { id: 'companion_002', name: '李护士', level: '中级', specialty: '儿科陪诊', rating: 4.6 },
    { id: 'companion_003', name: '王医生', level: '专家', specialty: '老年科陪诊', rating: 4.9 },
  ];
  
  res.json({
    success: true,
    data: companions,
    message: '获取陪诊师列表成功',
  });
});

app.get('/api/companions/:id', (req, res) => {
  const companion = {
    id: req.params.id,
    name: '张医生',
    level: '高级',
    specialty: '全科陪诊',
    experience: '8年',
    rating: 4.8,
    completed_orders: 156,
    description: '专业陪诊师，服务耐心细致',
  };
  
  res.json({
    success: true,
    data: companion,
    message: '获取陪诊师详情成功',
  });
});

// 订单路由
const ordersRouter = require('./src/routes/orders');
app.use('/api/orders', ordersRouter);

// 模拟支付
app.post('/api/payments/create', (req, res) => {
  res.json({
    success: true,
    data: {
      payment_id: 'pay_' + Date.now(),
      order_id: req.body.order_id,
      amount: req.body.amount,
      payment_method: req.body.payment_method,
      status: 'pending',
      created_at: new Date().toISOString(),
    },
    message: '创建支付订单成功',
  });
});

// 404处理
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: '接口不存在',
    path: req.path,
  });
});

// 错误处理
app.use((err, req, res, next) => {
  console.error('服务器错误:', err);
  res.status(500).json({
    success: false,
    message: '服务器内部错误',
    error: err.message,
  });
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`🚀 测试服务器启动成功`);
  console.log(`📡 地址: http://localhost:${PORT}`);
  console.log(`🏥 健康检查: http://localhost:${PORT}/health`);
  console.log(`📋 API文档: http://localhost:${PORT}/api`);
  console.log(`📊 订单API: http://localhost:${PORT}/api/orders`);
  console.log(`\n按 Ctrl+C 停止服务器`);
});