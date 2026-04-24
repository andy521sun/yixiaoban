/**
 * 医小伴APP - 支付API
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
 * 
 * @apiParam {String} order_id 订单ID
 * @apiParam {String} payment_method 支付方式 (wechat/alipay/bank_card/balance)
 * @apiParam {Number} amount 支付金额（分）
 * @apiParam {String} [description] 支付描述
 * 
 * @apiSuccess {Boolean} success 是否成功
 * @apiSuccess {Object} data 支付订单信息
 * @apiSuccess {String} data.payment_id 支付订单ID
 * @apiSuccess {String} data.order_id 关联订单ID
 * @apiSuccess {String} data.payment_method 支付方式
 * @apiSuccess {Number} data.amount 支付金额（分）
 * @apiSuccess {String} data.status 支付状态
 * @apiSuccess {String} data.payment_url 支付链接（模拟支付）
 * @apiSuccess {String} data.created_at 创建时间
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
 * @apiName GetPayment
 * @apiGroup Payment
 * @apiDescription 获取支付订单详细信息
 * 
 * @apiParam {String} payment_id 支付订单ID
 * 
 * @apiSuccess {Boolean} success 是否成功
 * @apiSuccess {Object} data 支付订单信息
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
 * @apiName SimulatePayment
 * @apiGroup Payment
 * @apiDescription 模拟支付完成（开发环境使用）
 * 
 * @apiParam {String} payment_id 支付订单ID
 * @apiParam {String} [result] 支付结果 (success/failed) 默认success
 * 
 * @apiSuccess {Boolean} success 是否成功
 * @apiSuccess {String} message 结果消息
 * @apiSuccess {Object} data 支付结果
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
 * @apiName RequestRefund
 * @apiGroup Payment
 * @apiDescription 申请支付退款
 * 
 * @apiParam {String} payment_id 支付订单ID
 * @apiParam {Number} [refund_amount] 退款金额（分），默认全额退款
 * @apiParam {String} [refund_reason] 退款原因
 * 
 * @apiSuccess {Boolean} success 是否成功
 * @apiSuccess {String} message 结果消息
 * @apiSuccess {Object} data 退款信息
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
 * @apiName GetOrderPayments
 * @apiGroup Payment
 * @apiDescription 获取指定订单的所有支付记录
 * 
 * @apiParam {String} order_id 订单ID
 * 
 * @apiSuccess {Boolean} success 是否成功
 * @apiSuccess {Array} data 支付记录列表
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
 * @apiName GetUserPayments
 * @apiGroup Payment
 * @apiDescription 获取指定用户的所有支付记录
 * 
 * @apiParam {String} user_id 用户ID
 * @apiParam {Number} [page=1] 页码
 * @apiParam {Number} [limit=20] 每页数量
 * 
 * @apiSuccess {Boolean} success 是否成功
 * @apiSuccess {Array} data 支付记录列表
 * @apiSuccess {Number} total 总记录数
 * @apiSuccess {Number} page 当前页码
 * @apiSuccess {Number} limit 每页数量
 * @apiSuccess {Number} pages 总页数
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
 * @apiName GetDailyPaymentStatistics
 * @apiGroup Payment
 * @apiDescription 获取每日支付统计信息
 * 
 * @apiParam {String} [start_date] 开始日期 (YYYY-MM-DD)
 * @apiParam {String} [end_date] 结束日期 (YYYY-MM-DD)
 * 
 * @apiSuccess {Boolean} success 是否成功
 * @apiSuccess {Object} data 统计信息
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
