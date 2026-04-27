const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const http = require('http');
const { testConnection, configQueries } = require('./db');
const auth = require('./auth');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;

// 中间件
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined'));

// 静态文件（管理首页）
// 静态文件，设置不缓存方便调试
app.use(express.static('public', {
  maxAge: 0,
  etag: false,
  setHeaders: (res, path) => {
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.set('Pragma', 'no-cache');
    res.set('Expires', '0');
    // 允许内联脚本和样式
    if (path.endsWith('.html')) {
      res.set('Content-Security-Policy', "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:;");
    }
  }
}));

// 请求日志中间件
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// 健康检查端点
app.get('/health', async (req, res) => {
  try {
    const dbStatus = await testConnection();
    const config = await configQueries.getAllPublic();
    
    const configMap = {};
    config.forEach(item => {
      configMap[item.config_key] = item.config_value;
    });
    
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: '医小伴陪诊API',
      version: configMap.app_version || '1.0.0',
      database: dbStatus ? 'connected' : 'disconnected',
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// 基础API路由
app.get('/api', async (req, res) => {
  try {
    const config = await configQueries.getAllPublic();
    const configMap = {};
    config.forEach(item => {
      configMap[item.config_key] = item.config_value;
    });
    
    res.json({
      message: `欢迎使用${configMap.app_name || '医小伴陪诊'}API`,
      version: configMap.app_version || '1.0.0',
      company: configMap.company_name,
      customer_service: configMap.customer_service_phone,
      endpoints: {
        auth: {
          register: 'POST /api/auth/register',
          login: 'POST /api/auth/login',
          profile: 'GET /api/auth/profile',
          update: 'PUT /api/auth/profile'
        },
        users: {
          get: 'GET /api/users/:id',
          update: 'PUT /api/users/:id'
        },
        hospitals: {
          list: 'GET /api/hospitals',
          detail: 'GET /api/hospitals/:id',
          departments: 'GET /api/hospitals/:id/departments'
        },
        companions: {
          list: 'GET /api/companions',
          detail: 'GET /api/companions/:id'
        },
        orders: {
          create: 'POST /api/orders',
          list: 'GET /api/orders',
          detail: 'GET /api/orders/:id',
          update: 'PUT /api/orders/:id',
          cancel: 'POST /api/orders/:id/cancel'
        },
        ai: {
          consult: 'POST /api/ai/consult'
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '服务器内部错误',
      error: error.message
    });
  }
});

// 支付API路由（使用新版本）
const paymentRouter = require("./routes/payment_simple");
app.use('/api/payment', paymentRouter);

// 实时通信API路由
const realtimeRouter = require('./routes/realtime');
app.use('/api/realtime', realtimeRouter);

// 管理后台API路由
const adminRouter = require('./routes/admin');
app.use('/api/admin', adminRouter);


// 订单管理API路由
const ordersRouter = require('./routes/orders');
app.use('/api/orders', ordersRouter);

// 聊天API路由
const chatRouter = require('./routes/chat');
app.use('/api/chat', chatRouter);

// 增强版医院API路由
const hospitalsEnhancedRouter = require('./routes/hospitals_enhanced');
app.use('/api/hospitals', hospitalsEnhancedRouter);

// 增强版陪诊师API路由
const companionsEnhancedRouter = require('./routes/companions_enhanced');
app.use('/api/companions', companionsEnhancedRouter);

// 测试页面路由
const testPageRouter = require('./routes/test_page_simple');
app.use('/test', testPageRouter);

// 短信验证码路由
const smsRouter = require('./routes/sms');
app.use('/api/sms', smsRouter);

// 陪诊师端订单管理路由（v2 增强版）
const companionOrdersRouter = require('./routes/companion_orders_v2');
app.use('/api/companion', companionOrdersRouter);

// 用户认证路由
app.post('/api/auth/register', async (req, res) => {
  try {
    const result = await auth.register(req.body);
    res.status(201).json(result);
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { phone, password } = req.body;
    const result = await auth.login(phone, password);
    res.json(result);
  } catch (error) {
    res.status(401).json({
      success: false,
      message: error.message
    });
  }
});

// ========== 短信验证码服务（内存存储） ==========
const smsCodes = new Map();

function generateSMSCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// 密码重置：发送验证码
app.post('/api/auth/forgot-password', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ success: false, message: '请输入手机号' });
    }
    const { userQueries } = require('./db');
    const user = await userQueries.findByPhone(phone);
    if (!user) {
      return res.status(404).json({ success: false, message: '该手机号未注册' });
    }
    
    // 生成6位验证码
    const code = generateSMSCode();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5分钟有效
    
    // 存储验证码
    smsCodes.set(`reset:${phone}`, { code, expiresAt, attempts: 0 });
    
    console.log(`[密码重置] ${phone} 验证码: ${code}`);
    
    // 模拟模式：返回验证码方便测试（SMS_MOCK=true 或 NODE_ENV=development）
    if (process.env.NODE_ENV === 'development' || process.env.SMS_MOCK === 'true') {
      return res.json({ success: true, message: '验证码已发送', data: { reset_code: code, expires_in: 300 } });
    }
    
    // TODO: 对接腾讯云/阿里云短信API发送真实短信
    res.json({ success: true, message: '验证码已发送' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 密码重置：验证验证码并修改密码
app.post('/api/auth/reset-password', async (req, res) => {
  try {
    const { phone, reset_code, new_password, confirm_password } = req.body;
    if (!phone || !reset_code || !new_password) {
      return res.status(400).json({ success: false, message: '参数不完整' });
    }
    if (new_password.length < 6) {
      return res.status(400).json({ success: false, message: '密码长度不能少于6位' });
    }
    if (new_password !== confirm_password) {
      return res.status(400).json({ success: false, message: '两次输入的密码不一致' });
    }
    
    // 从存储中查找验证码
    const key = `reset:${phone}`;
    const smsData = smsCodes.get(key);
    
    if (!smsData) {
      return res.status(400).json({ success: false, message: '验证码不存在或已过期' });
    }
    if (Date.now() > smsData.expiresAt) {
      smsCodes.delete(key);
      return res.status(400).json({ success: false, message: '验证码已过期，请重新获取' });
    }
    if (smsData.attempts >= 5) {
      smsCodes.delete(key);
      return res.status(400).json({ success: false, message: '验证码尝试次数过多，请重新获取' });
    }
    if (smsData.code !== reset_code) {
      smsData.attempts++;
      smsCodes.set(key, smsData);
      return res.status(400).json({ success: false, message: '验证码错误', data: { remaining: 5 - smsData.attempts } });
    }
    
    // 验证成功
    smsCodes.delete(key);
    
    const { userQueries } = require('./db');
    const user = await userQueries.findByPhone(phone);
    if (!user) {
      return res.status(404).json({ success: false, message: '用户不存在' });
    }
    const password_hash = await auth.hashPassword(new_password);
    await require('./db').query('UPDATE users SET password_hash = ?, updated_at = NOW() WHERE id = ?', [password_hash, user.id]);
    console.log(`[密码重置] ${phone} 密码已更新`);
    return res.json({ success: true, message: '密码重置成功，请使用新密码登录' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// 需要认证的路由
app.get('/api/auth/profile', auth.authenticateToken, async (req, res) => {
  try {
    const result = await auth.getCurrentUser(req.user.id);
    res.json(result);
  } catch (error) {
    res.status(404).json({
      success: false,
      message: error.message
    });
  }
});

app.put('/api/auth/profile', auth.authenticateToken, async (req, res) => {
  try {
    const result = await auth.updateUser(req.user.id, req.body);
    res.json(result);
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// 医院相关路由
app.get('/api/hospitals', async (req, res) => {
  try {
    const { hospitalQueries } = require('./db');
    const filters = {
      city: req.query.city,
      level: req.query.level
    };
    
    const hospitals = await hospitalQueries.findAll(filters);
    
    res.json({
      success: true,
      data: hospitals,
      total: hospitals.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取医院列表失败',
      error: error.message
    });
  }
});

app.get('/api/hospitals/:id', async (req, res) => {
  try {
    const { hospitalQueries } = require('./db');
    const hospital = await hospitalQueries.findById(req.params.id);
    
    if (!hospital) {
      return res.status(404).json({
        success: false,
        message: '医院不存在'
      });
    }
    
    res.json({
      success: true,
      data: hospital
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取医院信息失败',
      error: error.message
    });
  }
});

app.get('/api/hospitals/:id/departments', async (req, res) => {
  try {
    const { hospitalQueries } = require('./db');
    const departments = await hospitalQueries.getDepartments(req.params.id);
    
    res.json({
      success: true,
      data: departments,
      total: departments.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取科室列表失败',
      error: error.message
    });
  }
});

// 陪诊师相关路由
app.get('/api/companions', async (req, res) => {
  try {
    const { companionQueries } = require('./db');
    const filters = {
      specialty: req.query.specialty,
      minExperience: req.query.min_experience ? parseInt(req.query.min_experience) : undefined,
      maxHourlyRate: req.query.max_hourly_rate ? parseFloat(req.query.max_hourly_rate) : undefined
    };
    
    const companions = await companionQueries.findAvailable(filters);
    
    res.json({
      success: true,
      data: companions,
      total: companions.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取陪诊师列表失败',
      error: error.message
    });
  }
});

app.get('/api/companions/:id', async (req, res) => {
  try {
    const { companionQueries } = require('./db');
    const companion = await companionQueries.findById(req.params.id);
    
    if (!companion) {
      return res.status(404).json({
        success: false,
        message: '陪诊师不存在'
      });
    }
    
    res.json({
      success: true,
      data: companion
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取陪诊师信息失败',
      error: error.message
    });
  }
});

// 订单相关路由（需要认证）
app.post('/api/orders', auth.authenticateToken, async (req, res) => {
  try {
    const { orderQueries, companionQueries } = require('./db');
    
    // 验证输入
    const requiredFields = ['hospital_id', 'appointment_date', 'appointment_time', 'service_hours'];
    for (const field of requiredFields) {
      if (!req.body[field]) {
        return res.status(400).json({
          success: false,
          message: `缺少必要字段: ${field}`
        });
      }
    }
    
    // 计算总金额
    let totalAmount = 0;
    if (req.body.companion_id) {
      const companion = await companionQueries.findById(req.body.companion_id);
      if (!companion) {
        return res.status(404).json({
          success: false,
          message: '陪诊师不存在'
        });
      }
      totalAmount = companion.hourly_rate * req.body.service_hours;
    } else {
      // 使用默认费率
      const defaultRate = await configQueries.get('default_hourly_rate');
      totalAmount = (parseFloat(defaultRate) || 150) * req.body.service_hours;
    }
    
    // 创建订单
    const orderData = {
      patient_id: req.user.id,
      ...req.body,
      total_amount: totalAmount
    };
    
    const order = await orderQueries.create(orderData);
    
    // 通知在线陪诊师有新订单
    try {
      // 获取所有在线陪诊师
      const { query } = require('./db');
      const onlineCompanions = await query(`
        SELECT c.id, c.user_id FROM companions c
        WHERE c.is_available = 1
      `);
      
      const wsModule = require('./websocket');
      if (wsModule && global.wss) {
        for (const comp of onlineCompanions) {
          global.wss.sendSystemNotification(
            comp.user_id,
            '新订单通知',
            `有新的陪诊订单，请查看并接单！`,
            'new_order'
          );
        }
      }
    } catch (wsError) {
      console.log('[通知] 陪诊师通知推送: 跳过 (非致命错误)');
    }
    
    res.status(201).json({
      success: true,
      message: '订单创建成功',
      data: order
    });
  } catch (error) {
    console.error('创建订单错误:', error);
    res.status(500).json({
      success: false,
      message: '创建订单失败',
      error: error.message
    });
  }
});

app.get('/api/orders', auth.authenticateToken, async (req, res) => {
  try {
    const { orderQueries } = require('./db');
    
    const filters = {
      status: req.query.status,
      startDate: req.query.start_date,
      endDate: req.query.end_date,
      limit: req.query.limit ? parseInt(req.query.limit) : 20
    };
    
    const orders = await orderQueries.findByUserId(req.user.id, filters);
    
    res.json({
      success: true,
      data: orders,
      total: orders.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取订单列表失败',
      error: error.message
    });
  }
});

app.get('/api/orders/:id', auth.authenticateToken, auth.authorizeOwnership('order'), async (req, res) => {
  try {
    const { orderQueries } = require('./db');
    const order = await orderQueries.findById(req.params.id);
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    res.json({
      success: true,
      data: order
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取订单信息失败',
      error: error.message
    });
  }
});

app.post('/api/orders/:id/cancel', auth.authenticateToken, auth.authorizeOwnership('order'), async (req, res) => {
  try {
    const { orderQueries } = require('./db');
    
    // 检查订单状态
    const order = await orderQueries.findById(req.params.id);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    if (order.status === 'completed' || order.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: '订单无法取消'
      });
    }
    
    // 更新订单状态
    const updatedOrder = await orderQueries.updateStatus(req.params.id, 'cancelled', {
      cancel_reason: req.body.reason,
      cancelled_by: 'patient'
    });
    
    res.json({
      success: true,
      message: '订单取消成功',
      data: updatedOrder
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '取消订单失败',
      error: error.message
    });
  }
});

// AI问诊路由
app.post('/api/ai/consult', auth.authenticateToken, async (req, res) => {
  try {
    const { symptoms, age, gender } = req.body;
    
    if (!symptoms) {
      return res.status(400).json({
        success: false,
        message: '请输入症状描述'
      });
    }
    
    // 模拟AI分析（实际应调用AI服务）
    const analysis = `根据您的症状描述"${symptoms}"，${age ? `年龄${age}岁` : ''}${gender ? `，性别${gender === 'male' ? '男' : '女'}` : ''}，建议如下：`;
    
    const suggestions = [
      '建议尽快就医进行详细检查',
      '注意休息，避免过度劳累',
      '多喝水，保持充足睡眠',
      '如有发热、呕吐等加重症状，请立即就医'
    ];
    
    // 根据症状关键词给出建议
    if (symptoms.includes('头痛') || symptoms.includes('头晕')) {
      suggestions.push('建议挂神经内科门诊');
      suggestions.push('避免突然站起或剧烈运动');
    }
    
    if (symptoms.includes('发热') || symptoms.includes('发烧')) {
      suggestions.push('建议测量体温，如超过38.5℃请及时就医');
      suggestions.push('可适当使用退热药物，但需遵医嘱');
    }
    
    if (symptoms.includes('咳嗽') || symptoms.includes('咳痰')) {
      suggestions.push('建议挂呼吸内科门诊');
      suggestions.push('避免吸烟和刺激性气体');
    }
    
    res.json({
      success: true,
      data: {
        analysis,
        suggestions,
        emergency: symptoms.includes('胸痛') || symptoms.includes('呼吸困难') || symptoms.includes('意识模糊'),
        recommendation: '建议尽快就医',
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'AI问诊失败',
      error: error.message
    });
  }
});

// 管理员路由（需要管理员权限）
app.get('/api/admin/dashboard', auth.authenticateToken, auth.authorizeRole(['admin']), async (req, res) => {
  try {
    const { query } = require('./db');
    
    // 获取统计数据
    const stats = await Promise.all([
      query('SELECT COUNT(*) as total_users FROM users'),
      query('SELECT COUNT(*) as total_orders FROM orders'),
      query('SELECT COUNT(*) as active_orders FROM orders WHERE status IN ("pending", "confirmed", "in_progress")'),
      query('SELECT SUM(total_amount) as total_revenue FROM orders WHERE payment_status = "paid"'),
      query('SELECT COUNT(*) as total_companions FROM companions WHERE is_certified = TRUE'),
      query('SELECT COUNT(*) as available_companions FROM companions WHERE is_available = TRUE AND is_certified = TRUE')
    ]);
    
    // 获取最近订单
    const recentOrders = await query(`
      SELECT o.*, p.name as patient_name, c.real_name as companion_name, h.name as hospital_name
      FROM orders o
      LEFT JOIN users p ON o.patient_id = p.id
      LEFT JOIN companions c ON o.companion_id = c.id
      LEFT JOIN hospitals h ON o.hospital_id = h.id
      ORDER BY o.created_at DESC
      LIMIT 10
    `);
    
    res.json({
      success: true,
      data: {
        stats: {
          total_users: stats[0][0].total_users,
          total_orders: stats[1][0].total_orders,
          active_orders: stats[2][0].active_orders,
          total_revenue: stats[3][0].total_revenue || 0,
          total_companions: stats[4][0].total_companions,
          available_companions: stats[5][0].available_companions
        },
        recent_orders: recentOrders
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取仪表板数据失败',
      error: error.message
    });
  }
});

// 404处理
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'API端点不存在',
    path: req.path,
    method: req.method
  });
});

// 错误处理
app.use((err, req, res, next) => {
  console.error('服务器错误:', err.stack);
  res.status(500).json({
    success: false,
    message: '服务器内部错误',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 启动服务器
async function startServer() {
  try {
    // 测试数据库连接
    const dbConnected = await testConnection();
    if (!dbConnected) {
      console.warn('⚠️  数据库连接失败，部分功能可能不可用');
    }
    
    // 启动WebSocket服务器
    const WebSocketServer = require('./websocket');
    const wss = new WebSocketServer(server);
    global.wss = wss;
    
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`🏥 医小伴陪诊API服务运行在端口 ${PORT}`);
      console.log(`🩺 健康检查: http://localhost:${PORT}/health`);
      console.log(`📚 API文档: http://localhost:${PORT}/api`);
      console.log(`💿 WebSocket: ws://localhost:${PORT}/ws`);
      console.log(`💾 数据库状态: ${dbConnected ? '✅ 已连接' : '❌ 未连接'}`);
      console.log(`🔐 JWT密钥: ${process.env.JWT_SECRET ? '✅ 已配置' : '❌ 未配置'}`);
      console.log(`🌐 公网访问: http://122.51.179.136:${PORT}`);
      console.log(`🔌 实时通信: ✅ 已启用`);
    });
  } catch (error) {
    console.error('启动服务器失败:', error);
    process.exit(1);
  }
}

// 如果是直接运行此文件，则启动服务器
if (require.main === module) {
  startServer();
}

module.exports = app;