/**
 * 陪诊师端订单管理 API v2
 * 
 * 完整接单流程：
 * 查看待接订单 → 查看详情 → 接单 → 开始服务 → 完成服务
 * 查看历史订单、取消订单
 * 
 * 订单状态流转：
 * pending（待接单）→ accepted/confirmed（已接单）
 * → in_progress（服务中）→ completed（已完成）
 * → cancelled（已取消）
 * 
 * 状态枚举（前后端统一）：
 * pending, confirmed, in_progress, completed, cancelled
 */
const express = require('express');
const router = express.Router();
const auth = require('../auth');
const { query: dbQuery } = require('../db');
const notify = require('../services/notification');

// ==================== 模拟数据（数据库不可用时兜底） ====================
const mockOrders = [
  { id: 'mock_001', patient_id: 'patient_001', patient_name: '张先生', patient_phone: '13800138001',
    hospital_name: '上海市第一人民医院', hospital_address: '上海市虹口区海宁路100号',
    department: '神经内科', doctor_name: '王主任',
    service_type: '普通陪诊', 
    appointment_date: '2026-04-28', appointment_time: '09:00', duration_minutes: 120,
    price: 200, status: 'pending', payment_status: 'paid', companion_id: null,
    symptoms: '头痛头晕持续一周', notes: '患者行动不便，需要轮椅接送',
    created_at: '2026-04-27T08:00:00Z' },
  { id: 'mock_002', patient_id: 'patient_002', patient_name: '李女士', patient_phone: '13800138002',
    hospital_name: '华山医院', hospital_address: '上海市静安区乌鲁木齐中路12号',
    department: '消化内科', doctor_name: '陈医生',
    service_type: '专业陪诊',
    appointment_date: '2026-04-28', appointment_time: '14:00', duration_minutes: 180,
    price: 300, status: 'pending', payment_status: 'paid', companion_id: null,
    symptoms: '需要做胃镜检查', notes: '需要空腹，请提醒患者',
    created_at: '2026-04-27T09:30:00Z' },
  { id: 'mock_003', patient_id: 'patient_003', patient_name: '王阿姨', patient_phone: '13800138003',
    hospital_name: '瑞金医院', hospital_address: '上海市黄浦区瑞金二路197号',
    department: '体检中心', doctor_name: '',
    service_type: '老年陪护',
    appointment_date: '2026-04-29', appointment_time: '08:00', duration_minutes: 240,
    price: 360, status: 'pending', payment_status: 'paid', companion_id: null,
    symptoms: '年度体检，需全程陪同', notes: '老人家82岁，行动缓慢，请耐心陪同',
    created_at: '2026-04-27T10:00:00Z' },
  { id: 'mock_004', patient_id: 'patient_001', patient_name: '张先生', patient_phone: '13800138001',
    hospital_name: '中山医院', hospital_address: '上海市徐汇区枫林路180号',
    department: '心脏内科', doctor_name: '李主任',
    service_type: '普通陪诊',
    appointment_date: '2026-04-27', appointment_time: '15:00', duration_minutes: 120,
    price: 200, status: 'confirmed', payment_status: 'paid', companion_id: 'comp_001',
    symptoms: '心脏复查', notes: '',
    created_at: '2026-04-26T14:00:00Z' },
  { id: 'mock_005', patient_id: 'patient_002', patient_name: '李女士', patient_phone: '13800138002',
    hospital_name: '仁济医院', hospital_address: '上海市浦东新区浦建路160号',
    department: '急诊科', doctor_name: '',
    service_type: '急诊陪诊',
    appointment_date: '2026-04-27', appointment_time: '10:00', duration_minutes: 180,
    price: 300, status: 'in_progress', payment_status: 'paid', companion_id: 'comp_001',
    symptoms: '急性腹痛', notes: '患者疼痛难忍，需要尽快就诊',
    created_at: '2026-04-27T08:00:00Z' },
  { id: 'mock_006', patient_id: 'patient_003', patient_name: '王阿姨', patient_phone: '13800138003',
    hospital_name: '上海市第一人民医院',
    department: '心脏内科', doctor_name: '赵主任',
    service_type: '专业陪诊',
    appointment_date: '2026-04-26', appointment_time: '09:00', duration_minutes: 120,
    price: 300, status: 'completed', payment_status: 'paid', companion_id: 'comp_001',
    symptoms: '心脏复查', notes: '',
    created_at: '2026-04-25T10:00:00Z' },
];

// ==================== 数据库辅助函数 ====================

async function findAvailableOrders() {
  try {
    const rows = await dbQuery(`
      SELECT o.*, u.name as patient_name, u.phone as patient_phone,
             h.name as hospital_name, h.address as hospital_address
      FROM orders o
      LEFT JOIN users u ON o.patient_id = u.id
      LEFT JOIN hospitals h ON o.hospital_id = h.id
      WHERE o.status = 'pending' AND o.payment_status IN ('unpaid', 'paid')
      ORDER BY o.created_at DESC
    `);
    return rows;
  } catch (e) {
    return null;
  }
}

async function findMyOrders(companionId) {
  try {
    const rows = await dbQuery(`
      SELECT o.*, u.name as patient_name, u.phone as patient_phone,
             h.name as hospital_name, h.address as hospital_address
      FROM orders o
      LEFT JOIN users u ON o.patient_id = u.id
      LEFT JOIN hospitals h ON o.hospital_id = h.id
      WHERE o.companion_id = ?
      ORDER BY FIELD(o.status, 'in_progress', 'confirmed', 'completed', 'cancelled'),
               o.appointment_date ASC
    `, [companionId]);
    return rows;
  } catch (e) {
    return null;
  }
}

async function getOrderById(orderId) {
  try {
    const rows = await dbQuery(`
      SELECT o.*, u.name as patient_name, u.phone as patient_phone,
             h.name as hospital_name, h.address as hospital_address
      FROM orders o
      LEFT JOIN users u ON o.patient_id = u.id
      LEFT JOIN hospitals h ON o.hospital_id = h.id
      WHERE o.id = ?
    `, [orderId]);
    return rows[0] || null;
  } catch (e) {
    return null;
  }
}

async function updateOrderStatus(orderId, status, extra = {}) {
  const setClauses = ['status = ?'];
  const params = [status];

  if (extra.companion_id) { setClauses.push('companion_id = ?'); params.push(extra.companion_id); }
  if (extra.reason) { setClauses.push('cancel_reason = ?'); params.push(extra.reason); }
  if (status === 'completed') { setClauses.push('completed_at = NOW()'); }
  setClauses.push('updated_at = NOW()');

  try {
    const result = await dbQuery(
      `UPDATE orders SET ${setClauses.join(', ')} WHERE id = ?`,
      [...params, orderId]
    );
    const affected = result && result.affectedRows > 0;
    if (!affected) {
      console.log('[companion] updateOrderStatus: affected=0 for order', orderId, 'status', status);
    }
    return affected;
  } catch (e) {
    console.error('[companion] updateOrderStatus error:', e.message);
    return false;
  }
}

async function findCompanionByUserId(userId) {
  try {
    const rows = await dbQuery('SELECT * FROM companions WHERE id = ? OR user_id = ?', [userId, userId]);
    return rows[0] || null;
  } catch (e) {
    return null;
  }
}

// ==================== 辅助函数 ====================

function enrichOrder(o) {
  // 兼容 DB 字段（total_amount）和 mock 字段（price）
  const price = o.price || parseFloat(o.total_amount) || 0;
  const duration = o.duration_minutes || o.service_hours * 60 || 120;
  const serviceType = o.service_type || '普通陪诊';
  // 如果是 DB 的 enum 值，转回中文
  const typeMap = { 'accompany': '普通陪诊', 'consult': '专业陪诊', 'report': '陪诊', 'other': '急诊陪诊' };
  const displayType = typeMap[serviceType] || serviceType;
  
  return {
    id: o.id,
    patient_id: o.patient_id,
    patient_name: o.patient_name || '',
    patient_phone: o.patient_phone || '',
    hospital_name: o.hospital_name || '',
    hospital_address: o.hospital_address || '',
    department: o.department || '',
    doctor_name: o.doctor_name || '',
    service_type: displayType,
    appointment_date: o.appointment_date,
    appointment_time: o.appointment_time,
    duration_minutes: duration,
    price: price,
    status: o.status || 'pending',
    payment_status: o.payment_status || 'unpaid',
    symptoms: o.symptoms_description || o.symptoms || '',
    notes: o.special_requirements || o.notes || '',
    companion_id: o.companion_id,
    created_at: o.created_at,
    start_time: o.start_time,
    end_time: o.end_time,
  };
}

// ==================== 中间件 ====================

router.use(auth.authenticateToken);

router.use(async (req, res, next) => {
  try {
    // 先尝试查数据库
    const companion = await findCompanionByUserId(req.user.id);
    if (companion) {
      req.companion = companion;
      req.companionId = companion.id;
    } else {
      // 模拟：陪诊师用户ID的映射
      req.companionId = 'comp_001';
      req.companion = { id: 'comp_001', user_id: req.user.id, name: req.user.name || '陪诊师' };
    }
    next();
  } catch (error) {
    console.error('[companion] 中间件错误:', error.message);
    return res.status(500).json({ success: false, message: '服务器错误' });
  }
});

// ==================== 路由 ====================

/**
 * 获取待接单列表
 * GET /api/companion/orders/available
 */
router.get('/orders/available', async (req, res) => {
  let orders = await findAvailableOrders();

  if (!orders || orders.length === 0) {
    orders = mockOrders
      .filter(o => o.status === 'pending' && o.companion_id === null)
      .map(o => enrichOrder(o));
  } else {
    orders = orders.map(o => enrichOrder(o));
  }

  res.json({ success: true, data: orders, total: orders.length });
});

/**
 * 获取我的任务
 * GET /api/companion/orders/mine
 */
router.get('/orders/mine', async (req, res) => {
  let orders = await findMyOrders(req.companionId);

  if (!orders || orders.length === 0) {
    orders = mockOrders
      .filter(o => o.companion_id === req.companionId)
      .map(o => enrichOrder(o));
  } else {
    orders = orders.map(o => enrichOrder(o));
  }

  res.json({ success: true, data: orders, total: orders.length });
});

/**
 * 获取订单详情
 * GET /api/companion/orders/:id/detail
 */
router.get('/orders/:id/detail', async (req, res) => {
  const { id } = req.params;
  let order = await getOrderById(id);

  if (!order) {
    order = mockOrders.find(o => o.id === id);
  }

  if (!order) {
    return res.status(404).json({ success: false, message: '订单不存在' });
  }

  res.json({ success: true, data: enrichOrder(order) });
});

/**
 * 接单
 * POST /api/companion/orders/:id/accept
 */
router.post('/orders/:id/accept', async (req, res) => {
  const orderId = req.params.id;
  const companionId = req.companionId;

  // 尝试数据库
  let success = await updateOrderStatus(orderId, 'confirmed', { companion_id: companionId });

  if (!success) {
    // 模拟数据
    const order = mockOrders.find(o => o.id === orderId);
    if (order && order.status === 'pending') {
      order.status = 'confirmed';
      order.companion_id = companionId;
      success = true;
    }
  }

  if (success) {
    // 通知患者：已接单
    try {
      const order = await getOrderById(orderId);
      if (order && order.patient_id) {
        await notify.orderStatusChanged(orderId, order.patient_id, 'confirmed', req.companion.real_name || '陪诊师');
      }
    } catch (e) { /* 推送失败不阻塞 */ }

    res.json({
      success: true,
      message: '接单成功！已添加到您的任务列表',
      data: { order_id: orderId, status: 'confirmed' }
    });
  } else {
    res.status(400).json({
      success: false,
      message: '接单失败，该订单可能已被其他陪诊师接走'
    });
  }
});

/**
 * 拒绝接单
 * POST /api/companion/orders/:id/reject
 */
router.post('/orders/:id/reject', async (req, res) => {
  res.json({ success: true, message: '已忽略该订单' });
});

/**
 * 开始服务（须先确认到达医院）
 * POST /api/companion/orders/:id/start
 */
router.post('/orders/:id/start', async (req, res) => {
  const orderId = req.params.id;

  let success = await updateOrderStatus(orderId, 'in_progress');

  if (!success) {
    const order = mockOrders.find(o => o.id === orderId);
    if (order && order.status === 'confirmed') {
      order.status = 'in_progress';
      success = true;
    }
  }

  if (success) {
    // 通知患者：服务开始
    try {
      const order = await getOrderById(orderId);
      if (order && order.patient_id) {
        await notify.orderStatusChanged(orderId, order.patient_id, 'in_progress');
      }
    } catch (e) {}

    res.json({ success: true, message: '已开始服务，请陪伴患者就诊', data: { order_id: orderId, status: 'in_progress' } });
  } else {
    res.status(400).json({ success: false, message: '操作失败，订单状态不正确' });
  }
});

/**
 * 完成服务
 * POST /api/companion/orders/:id/complete
 */
router.post('/orders/:id/complete', async (req, res) => {
  const orderId = req.params.id;

  let success = await updateOrderStatus(orderId, 'completed');

  if (!success) {
    const order = mockOrders.find(o => o.id === orderId);
    if (order && order.status === 'in_progress') {
      order.status = 'completed';
      success = true;
    }
  }

  if (success) {
    // 通知患者：服务完成
    try {
      const order = await getOrderById(orderId);
      if (order && order.patient_id) {
        await notify.orderStatusChanged(orderId, order.patient_id, 'completed');
      }
    } catch (e) {}

    res.json({ success: true, message: '服务已完成，感谢您的付出！', data: { order_id: orderId, status: 'completed' } });

    // 更新收入（异步）
    try {
      const order = await getOrderById(orderId);
      if (order) {
        await dbQuery('UPDATE users SET balance = balance + ? WHERE id = ?',
          [order.price || 0, req.user.id]);
      }
    } catch (e) { /* 非关键错误，忽略 */ }
  } else {
    res.status(400).json({ success: false, message: '操作失败' });
  }
});

/**
 * 取消订单（已接单但尚未开始的订单）
 * POST /api/companion/orders/:id/cancel
 */
router.post('/orders/:id/cancel', async (req, res) => {
  const orderId = req.params.id;
  const { reason = '陪诊师主动取消' } = req.body;

  let success = await updateOrderStatus(orderId, 'cancelled', { reason });

  if (!success) {
    const order = mockOrders.find(o => o.id === orderId);
    if (order && (order.status === 'confirmed' || order.status === 'pending')) {
      order.status = 'cancelled';
      success = true;
    }
  }

  if (success) {
    // 通知患者：订单取消
    try {
      const order = await getOrderById(orderId);
      if (order && order.patient_id) {
        await notify.orderStatusChanged(orderId, order.patient_id, 'cancelled');
      }
    } catch (e) {}

    res.json({ success: true, message: '订单已取消' });
  } else {
    res.status(400).json({ success: false, message: '无法取消，该订单不在可取消状态' });
  }
});

/**
 * 获取统计数据
 * GET /api/companion/stats
 */
router.get('/stats', async (req, res) => {
  const companionId = req.companionId;
  let total = 0, today = 0, inProgress = 0, todayEarnings = 0, completed = 0;

  try {
    const stats = await dbQuery(`
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN DATE(created_at) = CURDATE() THEN 1 ELSE 0 END) as today,
        SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN DATE(created_at) = CURDATE() AND status = 'completed' THEN price ELSE 0 END) as today_earnings
      FROM orders WHERE companion_id = ?
    `, [companionId]);
    if (stats[0]) {
      total = stats[0].total || 0;
      today = stats[0].today || 0;
      inProgress = stats[0].in_progress || 0;
      completed = stats[0].completed || 0;
      todayEarnings = stats[0].today_earnings || 0;
    }
  } catch (e) {
    const myOrders = mockOrders.filter(o => o.companion_id === companionId);
    total = myOrders.length;
    inProgress = myOrders.filter(o => o.status === 'in_progress').length;
    completed = myOrders.filter(o => o.status === 'completed').length;
    todayEarnings = myOrders.filter(o => o.status === 'completed').reduce((s, o) => s + o.price, 0);
  }

  res.json({
    success: true,
    data: {
      total_orders: String(total),
      today_orders: String(today),
      in_progress: String(inProgress),
      completed_orders: String(completed),
      today_earnings: String(todayEarnings),
    }
  });
});

/**
 * 获取个人信息
 * GET /api/companion/profile
 */
router.get('/profile', async (req, res) => {
  res.json({ success: true, data: req.companion });
});

/**
 * 获取陪诊师日程（指定日期）
 * GET /api/companion/schedule?date=2026-04-27
 */
router.get('/schedule', async (req, res) => {
  const { date } = req.query;
  if (!date) {
    return res.status(400).json({ success: false, message: '缺少日期参数' });
  }

  const companionId = req.companionId;
  let events = [];

  try {
    events = await dbQuery(`
      SELECT o.id, o.appointment_date, o.appointment_time, o.status, o.duration_minutes, o.price,
             u.name as patient_name, h.name as hospital_name
      FROM orders o
      LEFT JOIN users u ON o.patient_id = u.id
      LEFT JOIN hospitals h ON o.hospital_id = h.id
      WHERE o.companion_id = ? AND DATE(o.appointment_date) = ?
      ORDER BY o.appointment_time ASC
    `, [companionId, date]);
  } catch (e) {
    // 用mock数据
    events = mockOrders
      .filter(o => o.companion_id === companionId && o.appointment_date === date)
      .map(o => ({
        id: o.id, appointment_date: o.appointment_date, appointment_time: o.appointment_time,
        status: o.status, duration_minutes: o.duration_minutes, price: o.price,
        patient_name: o.patient_name, hospital_name: o.hospital_name
      }));
  }

  res.json({ success: true, data: events, total: events.length });
});

/**
 * 获取月份日程概览（仅含日期的状态标签）
 * GET /api/companion/schedule/month?year=2026&month=4
 */
router.get('/schedule/month', async (req, res) => {
  const { year, month } = req.query;
  const companionId = req.companionId;
  let events = [];

  try {
    events = await dbQuery(`
      SELECT DISTINCT DATE(o.appointment_date) as date, o.status
      FROM orders o
      WHERE o.companion_id = ?
        AND YEAR(o.appointment_date) = ? AND MONTH(o.appointment_date) = ?
    `, [companionId, parseInt(year), parseInt(month)]);
  } catch (e) {
    events = mockOrders
      .filter(o => {
        if (!o.appointment_date) return false;
        const d = new Date(o.appointment_date);
        return o.companion_id === companionId &&
          d.getFullYear() === parseInt(year) &&
          (d.getMonth() + 1) === parseInt(month);
      })
      .map(o => ({ date: o.appointment_date, status: o.status }));
  }

  res.json({ success: true, data: events, total: events.length });
});

module.exports = router;
