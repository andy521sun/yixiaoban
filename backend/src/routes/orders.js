/**
 * 患者端订单管理 API
 * 依赖数据库 orders / users / hospitals / companions 表
 *
 * 订单状态: pending → paid → confirmed → in_progress → completed → cancelled
 *
 * 患者端流程：
 * 创建订单（pending） → 支付（paid） → 等待陪诊师接单
 *   → 陪诊师接单（confirmed） → 服务中（in_progress） → 完成（completed）
 */
const express = require('express');
const router = express.Router();
const auth = require('../auth');
const { query: dbQuery } = require('../db');
const notify = require('../services/notification');

// 所有订单接口需要认证
router.use(auth.authenticateToken);

/**
 * 创建订单
 * POST /api/orders
 */
router.post('/', async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      hospital_id,
      department_id = null,
      appointment_date,
      appointment_time,
      service_type = 'accompany',
      service_hours = 2,
      symptoms_description = '',
      special_requirements = '',
      total_amount,
    } = req.body;

    // 必填校验
    if (!hospital_id || !appointment_date || !appointment_time) {
      return res.status(400).json({
        success: false, message: '缺少必填参数: hospital_id, appointment_date, appointment_time'
      });
    }

    // 生成订单号
    const orderNumber = 'YB' + new Date().toISOString().replace(/[-:T.Z]/g, '').slice(0, 14) +
      String(Math.floor(Math.random() * 10000)).padStart(4, '0');

    // 计算价格
    const hours = parseFloat(service_hours) || 2;
    let rate = 150;
    if (service_type === '专业陪诊') rate = 200;
    else if (service_type === '急诊陪诊') rate = 250;
    else if (service_type === '长期陪护') rate = 180;

    const amount = parseFloat(total_amount) || (rate * hours);

    // 映射 service_type 到数据库枚举
    const typeMap = {
      '普通陪诊': 'accompany',
      '专业陪诊': 'consult',
      '急诊陪诊': 'other',
      '长期陪护': 'other',
    };
    const dbServiceType = typeMap[service_type] || 'accompany';

    // 创建订单
    const uuid = require('uuid');
    const id = uuid.v4();
    const sql = `
      INSERT INTO orders
      (id, order_number, patient_id, hospital_id, department_id,
       appointment_date, appointment_time, service_type, service_hours,
       symptoms_description, special_requirements, total_amount)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    await dbQuery(sql, [
      id, orderNumber, userId, hospital_id, department_id,
      appointment_date, appointment_time, dbServiceType, hours,
      symptoms_description, special_requirements, amount,
    ]);

    // 获取创建的订单
    const order = await dbQuery('SELECT * FROM orders WHERE id = ?', [id]);

    if (!order[0]) {
      return res.status(500).json({ success: false, message: '创建订单失败' });
    }

    // 通知在线陪诊师有新订单
    try {
      await notify.newOrderAvailable(id, order[0].hospital_name || order[0].hospital_id, dbServiceType);
    } catch (e) {
      console.log('[通知] 陪诊师通知推送: 跳过（非关键错误）');
    }

    res.status(201).json({
      success: true,
      message: '订单创建成功，请及时支付',
      data: order[0]
    });
  } catch (error) {
    console.error('[orders] 创建订单失败:', error);
    res.status(500).json({
      success: false,
      message: '创建订单失败: ' + error.message
    });
  }
});

/**
 * 获取我的订单列表
 * GET /api/orders?status=pending&page=1&limit=20
 */
router.get('/', async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, limit = 20 } = req.query;

    let sql = `
      SELECT o.*, h.name as hospital_name, h.address as hospital_address,
             c.real_name as companion_name
      FROM orders o
      LEFT JOIN hospitals h ON o.hospital_id = h.id
      LEFT JOIN companions c ON o.companion_id = c.id
      WHERE o.patient_id = ?
    `;
    const params = [userId];

    if (status) {
      sql += ' AND o.status = ?';
      params.push(status);
    }

    sql += ' ORDER BY o.created_at DESC LIMIT ?';
    params.push(parseInt(limit));

    const orders = await dbQuery(sql, params);

    res.json({
      success: true,
      data: orders,
      total: orders.length
    });
  } catch (error) {
    console.error('[orders] 获取列表失败:', error);
    res.status(500).json({ success: false, message: '获取订单列表失败' });
  }
});

/**
 * 获取订单详情
 * GET /api/orders/:id
 */
router.get('/:id', async (req, res) => {
  try {
    const userId = req.user.id;
    const orderId = req.params.id;

    const orders = await dbQuery(`
      SELECT o.*, h.name as hospital_name, h.address as hospital_address,
             c.real_name as companion_name,
             u.phone as companion_phone,
             c.average_rating as companion_rating, c.hourly_rate,
             d.name as department_name
      FROM orders o
      LEFT JOIN hospitals h ON o.hospital_id = h.id
      LEFT JOIN companions c ON o.companion_id = c.id
      LEFT JOIN users u ON c.user_id = u.id
      LEFT JOIN departments d ON o.department_id = d.id
      WHERE o.id = ? AND o.patient_id = ?
    `, [orderId, userId]);

    if (!orders[0]) {
      return res.status(404).json({ success: false, message: '订单不存在' });
    }

    res.json({ success: true, data: orders[0] });
  } catch (error) {
    console.error('[orders] 获取详情失败:', error);
    res.status(500).json({ success: false, message: '获取订单详情失败' });
  }
});

/**
 * 取消订单
 * POST /api/orders/:id/cancel
 * 仅允许 pending 或 paid 状态的订单取消
 */
router.post('/:id/cancel', async (req, res) => {
  try {
    const userId = req.user.id;
    const orderId = req.params.id;
    const { reason = '' } = req.body;

    const orders = await dbQuery(
      'SELECT id, status FROM orders WHERE id = ? AND patient_id = ?',
      [orderId, userId]
    );

    if (!orders[0]) {
      return res.status(404).json({ success: false, message: '订单不存在' });
    }

    const order = orders[0];
    if (!['pending', 'paid', 'confirmed'].includes(order.status)) {
      return res.status(400).json({
        success: false,
        message: `当前状态(${order.status})无法取消`
      });
    }

    await dbQuery(
      "UPDATE orders SET status = 'cancelled', cancel_reason = ?, updated_at = NOW() WHERE id = ?",
      [reason, orderId]
    );

    res.json({ success: true, message: '订单已取消' });
  } catch (error) {
    console.error('[orders] 取消订单失败:', error);
    res.status(500).json({ success: false, message: '取消订单失败' });
  }
});

module.exports = router;
