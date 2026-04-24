/**
 * 医小伴APP - 独立支付服务
 * 创建时间：2026年4月19日
 */

const express = require('./backend/node_modules/express');
const mysql = require('./backend/node_modules/mysql2/promise');
const app = express();
const PORT = 3001;

// 数据库配置
const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: 'yixiaoban123',
  database: 'yixiaoban_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

// 创建连接池
const pool = mysql.createPool(dbConfig);

// 中间件
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
});

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: '医小伴支付服务',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// 创建支付订单
app.post('/api/payments/create', async (req, res) => {
  try {
    const { order_id, payment_method, amount, description } = req.body;
    
    if (!order_id || !payment_method || !amount) {
      return res.status(400).json({
        success: false,
        message: '缺少必要参数：order_id, payment_method, amount'
      });
    }
    
    // 验证订单是否存在
    const [orderRows] = await pool.query(
      'SELECT id, total_amount, status FROM orders WHERE id = ?',
      [order_id]
    );
    
    if (orderRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    const order = orderRows[0];
    
    // 生成支付ID
    const payment_id = `pay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 创建支付记录
    await pool.query(
      `INSERT INTO payments (id, order_id, payment_method, amount, description, status, created_at)
       VALUES (?, ?, ?, ?, ?, 'pending', NOW())`,
      [payment_id, order_id, payment_method, amount, description || `订单支付 - ${order_id}`]
    );
    
    res.json({
      success: true,
      data: {
        payment_id,
        order_id,
        payment_method,
        amount,
        status: 'pending',
        payment_url: `/api/payments/simulate/${payment_id}`,
        created_at: new Date().toISOString()
      }
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
app.post('/api/payments/simulate/:payment_id', async (req, res) => {
  try {
    const { payment_id } = req.params;
    const { result = 'success' } = req.body;
    
    // 验证支付订单
    const [paymentRows] = await pool.query(
      'SELECT * FROM payments WHERE id = ?',
      [payment_id]
    );
    
    if (paymentRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: '支付订单不存在'
      });
    }
    
    const payment = paymentRows[0];
    
    // 更新支付状态
    const newStatus = result === 'success' ? 'success' : 'failed';
    const transaction_id = `trans_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
    
    await pool.query(
      `UPDATE payments 
       SET status = ?, 
           transaction_id = ?,
           payment_time = NOW(),
           updated_at = NOW()
       WHERE id = ?`,
      [newStatus, transaction_id, payment_id]
    );
    
    // 更新订单状态
    if (result === 'success') {
      await pool.query(
        `UPDATE orders 
         SET payment_status = 'paid',
             payment_method = ?,
             payment_time = NOW(),
             updated_at = NOW()
         WHERE id = ?`,
        [payment.payment_method, payment.order_id]
      );
    }
    
    res.json({
      success: true,
      message: `模拟支付${result === 'success' ? '成功' : '失败'}`,
      data: {
        payment_id,
        order_id: payment.order_id,
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

// 获取支付详情
app.get('/api/payments/:payment_id', async (req, res) => {
  try {
    const { payment_id } = req.params;
    
    const [rows] = await pool.query(
      `SELECT p.*, o.order_number, o.total_amount, u.name as user_name
       FROM payments p
       LEFT JOIN orders o ON p.order_id = o.id
       LEFT JOIN users u ON o.patient_id = u.id
       WHERE p.id = ?`,
      [payment_id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: '支付订单不存在'
      });
    }
    
    res.json({
      success: true,
      data: rows[0]
    });
    
  } catch (error) {
    console.error('获取支付详情失败:', error);
    res.status(500).json({
      success: false,
      message: '获取支付详情失败',
      error: error.message
    });
  }
});

// 支付统计
app.get('/api/payments/statistics/summary', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT 
         COUNT(*) as total_payments,
         SUM(amount) as total_amount,
         COUNT(CASE WHEN status = 'success' THEN 1 END) as success_payments,
         SUM(CASE WHEN status = 'success' THEN amount ELSE 0 END) as success_amount,
         COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_payments,
         COUNT(CASE WHEN status = 'refunded' THEN 1 END) as refunded_payments
       FROM payments`
    );
    
    const summary = rows[0];
    summary.success_rate = summary.total_payments > 0 
      ? ((summary.success_payments / summary.total_payments) * 100).toFixed(2)
      : '0.00';
    
    res.json({
      success: true,
      data: summary
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

// 启动服务
app.listen(PORT, () => {
  console.log(`🚀 支付服务已启动，端口：${PORT}`);
  console.log(`📊 健康检查：http://localhost:${PORT}/health`);
  console.log(`💳 创建支付：POST http://localhost:${PORT}/api/payments/create`);
  console.log(`🔄 模拟支付：POST http://localhost:${PORT}/api/payments/simulate/:payment_id`);
});