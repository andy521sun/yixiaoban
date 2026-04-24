const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined'));

// 健康检查端点
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: '医小伴陪诊API',
    version: '1.0.0'
  });
});

// 基础API路由
app.get('/api', (req, res) => {
  res.json({
    message: '欢迎使用医小伴陪诊API',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      orders: '/api/orders',
      hospitals: '/api/hospitals',
      companions: '/api/companions',
      ai: '/api/ai'
    }
  });
});

// 用户认证路由
app.post('/api/auth/register', (req, res) => {
  const { phone, password, name } = req.body;
  
  // 模拟用户注册
  res.status(201).json({
    success: true,
    message: '注册成功',
    data: {
      id: 'user_' + Date.now(),
      phone,
      name,
      role: 'patient',
      createdAt: new Date().toISOString()
    }
  });
});

app.post('/api/auth/login', (req, res) => {
  const { phone, password } = req.body;
  
  // 模拟用户登录
  res.json({
    success: true,
    message: '登录成功',
    data: {
      token: 'mock_jwt_token_' + Date.now(),
      user: {
        id: 'user_123456',
        phone,
        name: '测试用户',
        role: 'patient'
      }
    }
  });
});

// 医院相关路由
app.get('/api/hospitals', (req, res) => {
  const hospitals = [
    {
      id: 'hosp_001',
      name: '上海市第一人民医院',
      level: '三甲',
      address: '上海市虹口区武进路85号',
      departments: ['内科', '外科', '妇产科', '儿科', '眼科']
    },
    {
      id: 'hosp_002',
      name: '华山医院',
      level: '三甲',
      address: '上海市静安区乌鲁木齐中路12号',
      departments: ['神经内科', '皮肤科', '感染科', '骨科', '康复科']
    },
    {
      id: 'hosp_003',
      name: '瑞金医院',
      level: '三甲',
      address: '上海市黄浦区瑞金二路197号',
      departments: ['内分泌科', '血液科', '消化科', '呼吸科', '心血管科']
    }
  ];
  
  res.json({
    success: true,
    data: hospitals,
    total: hospitals.length
  });
});

// 陪诊师相关路由
app.get('/api/companions', (req, res) => {
  const companions = [
    {
      id: 'comp_001',
      name: '张护士',
      experience: '5年',
      specialty: ['内科陪诊', '老年陪护'],
      rating: 4.8,
      price: 200,
      available: true
    },
    {
      id: 'comp_002',
      name: '李医生',
      experience: '8年',
      specialty: ['全科陪诊', '报告解读'],
      rating: 4.9,
      price: 300,
      available: true
    },
    {
      id: 'comp_003',
      name: '王阿姨',
      experience: '3年',
      specialty: ['妇产科陪诊', '儿科陪护'],
      rating: 4.7,
      price: 180,
      available: false
    }
  ];
  
  res.json({
    success: true,
    data: companions,
    total: companions.length
  });
});

// AI问诊路由
app.post('/api/ai/consult', (req, res) => {
  const { symptoms, age, gender } = req.body;
  
  // 模拟AI问诊
  res.json({
    success: true,
    data: {
      analysis: '根据您的症状描述，建议您尽快就医检查。',
      suggestions: [
        '建议挂内科门诊',
        '注意休息，多喝水',
        '避免辛辣刺激食物'
      ],
      emergency: false,
      timestamp: new Date().toISOString()
    }
  });
});

// 404处理
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'API端点不存在',
    path: req.path
  });
});

// 错误处理
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: '服务器内部错误',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`医小伴陪诊API服务运行在端口 ${PORT}`);
  console.log(`健康检查: http://localhost:${PORT}/health`);
  console.log(`API文档: http://localhost:${PORT}/api`);
});