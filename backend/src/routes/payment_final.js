/**
 * 医小伴APP - 支付API（完整版）
 * 创建时间：2026年4月19日
 * 最后更新：2026年4月19日
 */

const express = require('express');
const router = express.Router();
const db = require('../db');

// 支付状态枚举
const PAYMENT_STATUS = {
  PENDING: 'pending',      // 待支付
  PROCESSING: 'processing', // 支付中
  SUCCESS: 'success',      // 支付成功
  FAILED: 'failed',        // 支付失败
  REFUNDED: 'refunded',     // 已退款
  REFUNDING: 'refunding',   // 退款中
  CANCELLED: 'cancelled'   // 已取消
};

// 支付方式枚举
const PAYMENT_METHOD = {
  WECHAT: 'wechat',        // 微信支付
  ALIPAY: 'alipay',        // 支付宝
  BANK_CARD: 'bank_card',  // 银行卡
  BALANCE: 'balance'       // 余额支付
};

/**
 * @api {post} /api/payments/create 创建支付订单
 * @apiName CreatePayment
 * @apiGroup Payment
 * @apiDescription 为订单创建支付记录
 */
router.post('/create', async (req, res) => {
  try {
    const { order_id, payment_method, amount, description } = req.body;
    
    // 参数验证
    if (!order_id || !payment_method || !amount) {
      return res.status(400).json({
        success: false,
        message: '缺少必要参数：order_id, payment_method, amount'
      });
    }
    
    // 验证支付方式
    if (!Object.values(PAYMENT_METHOD).includes(payment_method)) {
      return res.status(400).json({
        success: false,
        message: `无效的支付方式，支持：${Object.values(PAYMENT_METHOD).join(', ')}`
      });
    }
    
    // 验证订单是否存在
    const orderQuery = 'SELECT id, total_amount, status FROM orders WHERE id = ?';
    const [orderRows] = await db.query(orderQuery, [order_id]);
    
    if (orderRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: '订单不存在'
      });
    }
    
    const order = orderRows[0];
    
    // 验证订单状态
    if (order.status !== 'pending_payment') {
      return res.status(400).json({
        success: false,
        message: '订单状态不允许支付'
      });
    }
    
    // 验证支付金额
    if (amount !== order.total_amount) {
      return res.status(400).json({
        success: false,
        message: `支付金额不匹配，订单金额：${order.total_amount}`
      });
    }
    
    // 生成支付订单ID
    const payment_id = `pay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 创建支付记录
    const insertQuery = `
      INSERT INTO payments (
        id, order_id, payment_method, amount, description, 
        status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())
    `;
    
    await db.query(insertQuery, [
      payment_id,
      order_id,
      payment_method,
      amount,
      description || `订单支付 - ${order_id}`,
      PAYMENT_STATUS.PENDING
    ]);
    
    // 生成模拟支付链接
    const payment_url = `/payment/simulate/${payment_id}`;
    
    res.json({
      success: true,
      data: {
        payment_id,
        order_id,
        payment_method,
        amount,
        status: PAYMENT_STATUS.PENDING,
        payment_url,
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

/**
 * @api {get} /api/payments/:payment_id 获取支付订单详情
 */
router.get('/:payment_id', async (req, res) => {
  try {
    const { payment_id } = req.params;
    
    const query = `
      SELECT 
        p.*,
        o.id as order_id,
        o.total_amount,
        o.status as order_status,
        u.name as user_name,
        u.phone as user_phone
      FROM payments p
      LEFT JOIN orders o ON p.order_id = o.id
      LEFT JOIN users u ON o.user_id = u.id
      WHERE p.id = ?
    `;
    
    const [rows] = await db.query(query, [payment_id]);
    
    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: '支付订单不存在'
      });
    }
    
    const payment = rows[0];
    
    // 添加支付状态描述
    payment.status_text = getPaymentStatusText(payment.status);
    payment.payment_method_text = getPaymentMethodText(payment.payment_method);
    
    res.json({
      success: true,
      data: payment
    });
    
  } catch (error) {
    console.error('获取支付订单失败:', error);
    res.status(500).json({
      success: false,
      message: '获取支付订单失败',
      error: error.message
    });
  }
});

/**
 * @api {post} /api/payments/:payment_id/simulate 模拟支付
 */
router.post('/:payment_id/simulate', async (req, res) => {
  try {
    const { payment_id } = req.params;
    const { result = 'success' } = req.body;
    
    // 验证支付订单
    const paymentQuery = 'SELECT * FROM payments WHERE id = ?';
    const [paymentRows] = await db.query(paymentQuery, [payment_id]);
    
    if (paymentRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: '支付订单不存在'
      });
    }
    
    const payment = paymentRows[0];
    
    // 验证支付状态
    if (payment.status !== PAYMENT_STATUS.PENDING) {
      return res.status(400).json({
        success: false,
        message: `支付订单状态为${payment.status}，无法模拟支付`
      });
    }
    
    // 更新支付状态
    const newStatus = result === 'success' ? PAYMENT_STATUS.SUCCESS : PAYMENT_STATUS.FAILED;
    const transaction_id = `trans_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    const updatePaymentQuery = `
      UPDATE payments 
      SET status = ?, 
          transaction_id = ?,
          paid_at = NOW(),
          updated_at = NOW()
      WHERE id = ?
    `;
    
    await db.query(updatePaymentQuery, [newStatus, transaction_id, payment_id]);
    
    // 更新订单状态
    if (result === 'success') {
      const updateOrderQuery = `
        UPDATE orders 
        SET status = 'confirmed',
            payment_status = 'paid',
            payment_method = ?,
            paid_at = NOW(),
            updated_at = NOW()
        WHERE id = ?
      `;
      
      await db.query(updateOrderQuery, [payment.payment_method, payment.order_id]);
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

/**
 * @api {post} /api/payments/:payment_id/refund 申请退款
 */
router.post('/:payment_id/refund', async (req, res) => {
  try {
    const { payment_id } = req.params;
    const { refund_amount, refund_reason } = req.body;
    
    // 验证支付订单
    const paymentQuery = 'SELECT * FROM payments WHERE id = ?';
    const [paymentRows] = await db.query(paymentQuery, [payment_id]);
    
    if (paymentRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: '支付订单不存在'
      });
    }
    
    const payment = paymentRows[0];
    
    // 验证支付状态
    if (payment.status !== PAYMENT_STATUS.SUCCESS) {
      return res.status(400).json({
        success: false,
        message: '只有支付成功的订单才能申请退款'
      });
    }
    
    // 计算退款金额
    const actualRefundAmount = refund_amount || payment.amount;
    
    if (actualRefundAmount > payment.amount) {
      return res.status(400).json({
        success: false,
        message: '退款金额不能超过支付金额'
      });
    }
    
    // 更新支付状态为退款中
    const updatePaymentQuery = `
      UPDATE payments 
      SET status = 'refunding',
          refund_amount = ?,
          refund_reason = ?,
          updated_at = NOW()
      WHERE id = ?
    `;
    
    await db.query(updatePaymentQuery, [
      actualRefundAmount,
      refund_reason || '用户申请退款',
      payment_id
    ]);
    
    // 更新订单状态
    const updateOrderQuery = `
      UPDATE orders 
      SET status = 'refunding',
          updated_at = NOW()
      WHERE id = ?
    `;
    
    await db.query(updateOrderQuery, [payment.order_id]);
    
    res.json({
      success: true,
      message: '退款申请已提交',
      data: {
        payment_id,
        order_id: payment.order_id,
        refund_amount: actualRefundAmount,
        refund_reason: refund_reason || '用户申请退款',
        status: 'refunding'
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

/**
 * @api {get} /api/payments/order/:order_id 获取订单支付记录
 */
router.get('/order/:order_id', async (req, res) => {
  try {
    const { order_id } = req.params;
    
    const query = `
      SELECT * FROM payments 
      WHERE order_id = ? 
      ORDER BY created_at DESC
    `;
    
    const [rows] = await db.query(query, [order_id]);
    
    // 添加状态描述
    const payments = rows.map(payment => ({
      ...payment,
      status_text: getPaymentStatusText(payment.status),
      payment_method_text: getPaymentMethodText(payment.payment_method)
    }));
    
    res.json({
      success: true,
      data: payments
    });
    
  } catch (error) {
    console.error('获取订单支付记录失败:', error);
    res.status(500).json({
      success: false,
      message: '获取订单支付记录失败',
      error: error.message
    });
  }
});

/**
 * @api {get} /api/payments/user/:user_id 获取用户支付记录
 */
router.get('/user/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    
    // 验证用户是否存在
    const userQuery = 'SELECT id FROM users WHERE id = ?';
    const [userRows] = await db.query(userQuery, [user_id]);
    
    if (userRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: '用户不存在'
      });
    }
    
    // 获取总记录数
    const countQuery = `
      SELECT COUNT(*) as total 
      FROM payments p
      JOIN orders o ON p.order_id = o.id
      WHERE o.user_id = ?
    `;
    
    const [countRows] = await db.query(countQuery, [user_id]);
    const total = countRows[0].total;
    
    // 获取支付记录
    const query = `
      SELECT 
        p.*,
        o.id as order_id,
        o.total_amount,
        o.status as order_status,
        o.service_type,
        o.appointment_date
      FROM payments p
      JOIN orders o ON p.order_id = o.id
      WHERE o.user_id = ?
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `;
    
    const [rows] = await db.query(query, [user_id, limit, offset]);
    
    // 添加状态描述
    const payments = rows.map(payment => ({
      ...payment,
      status_text: getPaymentStatusText(payment.status),
      payment_method_text: getPaymentMethodText(payment.payment_method)
    }));
    
    res.json({
      success: true,
      data: payments,
      pagination: {
        total,
        page,
        limit,
        pages: Math.ceil(total / limit)
      }
    });
    
  } catch (error) {
    console.error('获取用户支付记录失败:', error);
    res.status(500).json({
      success: false,
      message: '获取用户支付记录失败',
      error: error.message
    });
  }
});

/**
 * @api {get} /api/payments/statistics/daily 每日支付统计
 */
router.get('/statistics/daily', async (req, res) => {
  try {
    const { start_date, end_date } = req.query;
    
    let dateCondition = '';
    const params = [];
    
    if (start_date && end_date) {
      dateCondition = 'WHERE DATE(p.created_at) BETWEEN ? AND ?';
      params.push(start_date, end_date);
    } else if (start_date) {
      dateCondition = 'WHERE DATE(p.created_at) >= ?';
      params.push(start_date);
    } else if (end_date) {
      dateCondition = 'WHERE DATE(p.created_at) <= ?';
      params.push(end_date);
    }
    
    const query = `
      SELECT 
        DATE(p.created_at) as date,
        p.payment_method,
        COUNT(*) as payment_count,
        SUM(p.amount) as total_amount,
        SUM(CASE WHEN p.status = 'success' THEN p.amount ELSE 0 END) as success_amount,
        COUNT(CASE WHEN p.status = 'success' THEN 1 END) as success_count
      FROM payments p
      ${dateCondition}
      GROUP BY DATE(p.created_at), p.payment_method
      ORDER BY date DESC, p.payment_method
    `;
    
    const [rows] = await db.query(query, params);
    
    res.json({
      success: true,
      data: rows
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

/**
 * @api {get} /api/payments/statistics/summary 支付汇总统计
 */
router.get('/statistics/summary', async (req, res) => {
  try {
    const { start_date, end_date } = req.query;
    
    let dateCondition = '';
    const params = [];
    
    if (start_date && end_date) {
      dateCondition = 'WHERE DATE(created_at) BETWEEN ? AND ?';
      params.push(start_date, end_date);
    } else if (start_date) {
      dateCondition = 'WHERE DATE(created_at) >= ?';
      params.push(start_date);
    } else if (end_date) {
      dateCondition = 'WHERE DATE(created_at) <= ?';
      params.push(end_date);
    }
    
    const query = `
      SELECT 
        COUNT(*) as total_payments,
        SUM(amount) as total_amount,
        AVG(amount) as average_amount,
        COUNT(CASE WHEN status = 'success' THEN 1 END) as success_payments,
        SUM(CASE WHEN status = 'success' THEN amount ELSE 0 END) as success_amount,
        COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_payments,
        SUM(CASE WHEN status = 'failed' THEN amount ELSE 0 END) as failed_amount,
        COUNT(CASE WHEN status = 'refunded' THEN 1 END) as refunded_payments,
        SUM(CASE WHEN status = 'refunded' THEN amount ELSE 0 END) as refunded_amount
      FROM payments
      ${dateCondition}
    `;
    
    const [rows] = await db.query(query, params);
    
    const summary = rows[0];
    
    // 计算成功率
    summary.success_rate = summary.total_payments > 0 
      ? (summary.success_payments / summary.total_payments * 100).toFixed(2)
      : 0;
    
    // 计算退款率
    summary.refund_rate = summary.success_payments > 0
      ? (summary.refunded_payments / summary.success_payments * 100).toFixed(2)
      : 0;
    
    res.json({
      success: true,
      data: summary
    });
    
  } catch (error) {
    console.error('获取支付汇总统计失败:', error);
    res.status(500).json({
      success: false,
      message: '获取支付汇总统计失败',
      error: error.message
    });
  }
});

// 辅助函数：获取支付状态文本描述
function getPaymentStatusText(status) {
  const statusMap = {
    'pending': '待支付',
    'processing': '支付中',
    'success': '支付成功',
    'failed': '支付失败',
    'refunded': '已退款',
    'refunding': '退款中',
    'cancelled': '已取消'
  };
  
  return statusMap[status] || '未知状态';
}

// 辅助函数：获取支付方式文本描述
function getPaymentMethodText(method) {
  const methodMap = {
    'wechat': '微信支付',
    'alipay': '支付宝',
    'bank_card': '银行卡',
    'balance': '余额支付'
  };
  
  return methodMap[method] || '未知支付方式';
}

module.exports = router;
