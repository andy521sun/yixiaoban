const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// 导入路由
const ordersRouter = require('./src/routes/orders');
const hospitalsEnhancedRouter = require('./src/routes/hospitals_enhanced');
const companionsEnhancedRouter = require('./src/routes/companions_enhanced');
const smsRouter = require('./src/routes/sms');

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: '医小伴陪诊API',
    version: '1.0.0',
    database: 'connected',
    environment: 'development',
    endpoints: {
      health: 'GET /health',
      api_docs: 'GET /api',
      hospitals: 'GET /api/hospitals',
      hospitals_enhanced: 'GET /api/hospitals/enhanced',
      companions: 'GET /api/companions',
      companions_enhanced: 'GET /api/companions/enhanced',
      orders: 'GET /api/orders',
      sms: 'POST /api/sms/send'
    }
  });
});

// API文档
app.get('/api', (req, res) => {
  res.json({
    message: '欢迎使用医小伴陪诊API',
    version: '1.0.0',
    company: '医小伴科技有限公司',
    customer_service: '400-123-4567',
    endpoints: {
      health: 'GET /health',
      hospitals: 'GET /api/hospitals',
      hospitals_enhanced: 'GET /api/hospitals/enhanced',
      companions: 'GET /api/companions',
      companions_enhanced: 'GET /api/companions/enhanced',
      orders: {
        list: 'GET /api/orders',
        create: 'POST /api/orders',
        detail: 'GET /api/orders/:id',
        pay: 'POST /api/orders/:id/pay',
        cancel: 'POST /api/orders/:id/cancel',
        update_status: 'PATCH /api/orders/:id/status'
      },
      sms: {
        send: 'POST /api/sms/send',
        verify: 'POST /api/sms/verify'
      }
    }
  });
});

// 模拟医院数据
app.get('/api/hospitals', (req, res) => {
  res.json({
    success: true,
    data: [
      {
        id: 'hosp_001',
        name: '上海市第一人民医院',
        level: '三甲',
        address: '上海市虹口区武进路85号',
        departments: ['内科', '外科', '儿科', '妇产科'],
        phone: '021-63240090'
      },
      {
        id: 'hosp_002',
        name: '复旦大学附属华山医院',
        level: '三甲',
        address: '上海市静安区乌鲁木齐中路12号',
        departments: ['神经内科', '皮肤科', '感染科', '骨科'],
        phone: '021-52889999'
      },
      {
        id: 'hosp_003',
        name: '上海交通大学医学院附属瑞金医院',
        level: '三甲',
        address: '上海市黄浦区瑞金二路197号',
        departments: ['内分泌科', '血液科', '消化科', '心血管科'],
        phone: '021-64370045'
      }
    ]
  });
});

// 模拟陪诊师数据
app.get('/api/companions', (req, res) => {
  res.json({
    success: true,
    data: [
      {
        id: 'comp_001',
        name: '张医生',
        experience_years: 5,
        specialty: '全科陪诊',
        level: '高级',
        rating: 4.8,
        price_per_hour: 150
      },
      {
        id: 'comp_002',
        name: '李护士',
        experience_years: 3,
        specialty: '儿科陪诊',
        level: '中级',
        rating: 4.5,
        price_per_hour: 120
      },
      {
        id: 'comp_003',
        name: '王医生',
        experience_years: 8,
        specialty: '老年科陪诊',
        level: '专家',
        rating: 4.9,
        price_per_hour: 200
      }
    ]
  });
});

// 使用增强版路由
app.use('/api/hospitals/enhanced', hospitalsEnhancedRouter);
app.use('/api/companions/enhanced', companionsEnhancedRouter);
app.use('/api/orders', ordersRouter);
app.use('/api/sms', smsRouter);

// 404处理
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'API端点不存在',
    requested_url: req.originalUrl,
    available_endpoints: [
      'GET /health',
      'GET /api',
      'GET /api/hospitals',
      'GET /api/hospitals/enhanced',
      'GET /api/companions',
      'GET /api/companions/enhanced',
      'GET /api/orders',
      'POST /api/orders',
      'POST /api/sms/send'
    ]
  });
});

// 错误处理
app.use((err, req, res, next) => {
  console.error('服务器错误:', err);
  res.status(500).json({
    success: false,
    message: '服务器内部错误',
    error: process.env.NODE_ENV === 'development' ? err.message : '内部服务器错误'
  });
});

app.listen(PORT, () => {
  console.log(`🏥 医小伴API服务运行在端口 ${PORT}`);
  console.log(`🩺 健康检查: http://localhost:${PORT}/health`);
  console.log(`📚 API文档: http://localhost:${PORT}/api`);
  console.log(`🏨 医院API: http://localhost:${PORT}/api/hospitals`);
  console.log(`👤 陪诊师API: http://localhost:${PORT}/api/companions`);
  console.log(`📋 订单API: http://localhost:${PORT}/api/orders`);
  console.log(`📱 短信API: http://localhost:${PORT}/api/sms/send`);
  console.log(`🚀 服务已启动，开始开发吧！`);
});