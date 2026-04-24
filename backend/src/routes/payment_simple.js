/**
 * 医小伴APP - 简化支付API
 * 创建时间：2026年4月19日
 */

const express = require('express');
const router = express.Router();
const db = require('../db');

// 创建支付订单
router.post('/create', async (req, res) => {
  try {
    const { order_id, payment_method, amount } = req.body;
    
    if (!order_id || !payment_method || !amount) {
      return res.status(400).json({
        success: false,
        message: '缺少必要参数'
      });
    }
    
    // 生成支付ID
    const payment_id = `pay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 创建支付记录
    const query = `
      INSERT INTO payments (id, order_id, payment_method, amount, status, created_at)
      VALUES (?, ?, ?, ?, 'pending', NOW())
    `;
    
    await db.query(query, [payment_id, order_id, payment_method, amount]);
    
    res.json({
      success: true,
      data: {
        payment_id,
        order_id,
        payment_method,
        amount,
        status: 'pending',
        payment_url: `/payment/simulate/${payment_id}`,
        created_at: new Date().toISOString()
      }
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
router.post('/simulate/:payment_id', async (req, res) => {
  try {
    const { payment_id } = req.params;
    const { result = 'success' } = req.body;
    
    // 更新支付状态
    const newStatus = result === 'success' ? 'success' : 'failed';
    const transaction_id = `trans_${Date.now()}`;
    
    const updateQuery = `
      UPDATE payments 
      SET status = ?, 
          transaction_id = ?,
          payment_time = NOW(),
          updated_at = NOW()
      WHERE id = ?
    `;
    
    await db.query(updateQuery, [newStatus, transaction_id, payment_id]);
    
    // 获取支付信息
    const paymentQuery = 'SELECT order_id FROM payments WHERE id = ?';
    const [rows] = await db.query(paymentQuery, [payment_id]);
    
    if (rows.length > 0 && result === 'success') {
      const order_id = rows[0].order_id;
      
      // 更新订单状态
      const orderQuery = `
        UPDATE orders 
        SET payment_status = 'paid',
            payment_method = (SELECT payment_method FROM payments WHERE id = ?),
            payment_time = NOW(),
            updated_at = NOW()
        WHERE id = ?
      `;
      
      await db.query(orderQuery, [payment_id, order_id]);
    }
    
    res.json({
      success: true,
      message: `模拟支付${result === 'success' ? '成功' : '失败'}`,
      data: {
        payment_id,
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
router.get('/:payment_id', async (req, res) => {
  try {
    const { payment_id } = req.params;
    
    const query = `
      SELECT p.*, o.order_number, o.total_amount, u.name as user_name
      FROM payments p
      LEFT JOIN orders o ON p.order_id = o.id
      LEFT JOIN users u ON o.patient_id = u.id
      WHERE p.id = ?
    `;
    
    const [rows] = await db.query(query, [payment_id]);
    
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

// 获取订单支付记录
router.get('/order/:order_id', async (req, res) => {
  try {
    const { order_id } = req.params;
    
    const query = `
      SELECT * FROM payments 
      WHERE order_id = ? 
      ORDER BY created_at DESC
    `;
    
    const [rows] = await db.query(query, [order_id]);
    
    res.json({
      success: true,
      data: rows
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

// 支付统计
router.get('/statistics/summary', async (req, res) => {
  try {
    const query = `
      SELECT 
        COUNT(*) as total_payments,
        SUM(amount) as total_amount,
        COUNT(CASE WHEN status = 'success' THEN 1 END) as success_payments,
        SUM(CASE WHEN status = 'success' THEN amount ELSE 0 END) as success_amount,
        COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_payments
      FROM payments
    `;
    
    const [rows] = await db.query(query);
    
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

module.exports = router;