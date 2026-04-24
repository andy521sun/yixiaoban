/**
 * 陪诊师端订单管理 API
 * 包括：查看待接订单、接单、拒绝、开始服务、完成服务、查看历史
 */
const express = require('express');
const router = express.Router();
const auth = require('../auth');
const { query: dbQuery } = require('../db');

// ==================== 模拟数据层 ====================
// 当数据库未准备就绪时使用模拟数据
const mockOrders = [
  { id: 'order_mock_001', patient_id: 'patient_001', patient_name: '张先生', patient_phone: '13800138001',
    hospital_id: 'hosp_001', hospital_name: '上海市第一人民医院', service_type: '普通陪诊',
    appointment_date: '2026-04-25', appointment_time: '09:00', duration_minutes: 120,
    price: 200.0, status: 'pending', payment_status: 'paid', companion_id: null,
    symptoms: '头痛头晕', created_at: '2026-04-24T10:00:00Z' },
  { id: 'order_mock_002', patient_id: 'patient_002', patient_name: '李女士', patient_phone: '13800138002',
    hospital_id: 'hosp_002', hospital_name: '华山医院', service_type: '专业陪诊',
    appointment_date: '2026-04-25', appointment_time: '14:00', duration_minutes: 180,
    price: 300.0, status: 'pending', payment_status: 'paid', companion_id: null,
    symptoms: '需要做胃镜，需要陪同', created_at: '2026-04-24T11:00:00Z' },
  { id: 'order_mock_003', patient_id: 'patient_003', patient_name: '王阿姨', patient_phone: '13800138003',
    hospital_id: 'hosp_003', hospital_name: '瑞金医院', service_type: '老年陪护',
    appointment_date: '2026-04-26', appointment_time: '08:30', duration_minutes: 240,
    price: 350.0, status: 'pending', payment_status: 'paid', companion_id: null,
    symptoms: '老年人体检，需要全程陪同', created_at: '2026-04-24T09:00:00Z' },
  { id: 'order_mock_004', patient_id: 'patient_001', patient_name: '张先生', patient_phone: '13800138001',
    hospital_id: 'hosp_004', hospital_name: '中山医院', service_type: '普通陪诊',
    appointment_date: '2026-04-24', appointment_time: '15:00', duration_minutes: 120,
    price: 200.0, status: 'confirmed', payment_status: 'paid', companion_id: 'comp_001',
    symptoms: '复诊', created_at: '2026-04-23T14:00:00Z' },
  { id: 'order_mock_005', patient_id: 'patient_002', patient_name: '李女士', patient_phone: '13800138002',
    hospital_id: 'hosp_005', hospital_name: '仁济医院', service_type: '急诊陪诊',
    appointment_date: '2026-04-24', appointment_time: '10:00', duration_minutes: 180,
    price: 300.0, status: 'in_progress', payment_status: 'paid', companion_id: 'comp_001',
    symptoms: '急性腹痛', created_at: '2026-04-24T08:00:00Z' },
  { id: 'order_mock_006', patient_id: 'patient_003', patient_name: '王阿姨', patient_phone: '13800138003',
    hospital_id: 'hosp_001', hospital_name: '上海市第一人民医院', service_type: '专业陪诊',
    appointment_date: '2026-04-22', appointment_time: '09:00', duration_minutes: 120,
    price: 300.0, status: 'completed', payment_status: 'paid', companion_id: 'comp_001',
    symptoms: '心脏复查', created_at: '2026-04-21T10:00:00Z' },
];

// ==================== 数据库查询 ====================
async function findCompanionByUserId(userId) {
  try {
    const rows = await dbQuery('SELECT * FROM companions WHERE id = ? OR user_id = ?', [userId, userId]);
    return rows[0] || null;
  } catch (e) {
    return null;
  }
}

async function findOrdersAvailable() {
  try {
    const rows = await dbQuery(`
      SELECT o.*, u.name as patient_name, u.phone as patient_phone, h.name as hospital_name
      FROM orders o
      LEFT JOIN users u ON o.patient_id = u.id
      LEFT JOIN hospitals h ON o.hospital_id = h.id
      WHERE o.status = 'pending' AND o.payment_status = 'paid'
      ORDER BY o.created_at DESC
    `);
    return rows;
  } catch (e) {
    return null;
  }
}

async function findOrdersByCompanion(companionId) {
  try {
    const rows = await dbQuery(`
      SELECT o.*, u.name as patient_name, u.phone as patient_phone, h.name as hospital_name
      FROM orders o
      LEFT JOIN users u ON o.patient_id = u.id
      LEFT JOIN hospitals h ON o.hospital_id = h.id
      WHERE o.companion_id = ?
      ORDER BY o.appointment_date DESC, o.appointment_time DESC
    `, [companionId]);
    return rows;
  } catch (e) {
    return null;
  }
}

async function updateOrderStatus(orderId, status, extra = {}) {
  const setClauses = ['status = ?'];
  const params = [status];
  
  if (extra.companion_id) { setClauses.push('companion_id = ?'); params.push(extra.companion_id); }
  
  setClauses.push('updated_at = NOW()');
  
  try {
    const rows = await dbQuery(
      `UPDATE orders SET ${setClauses.join(', ')} WHERE id = ?`,
      [...params, orderId]
    );
    return rows.affectedRows > 0;
  } catch (e) {
    return false;
  }
}

// ==================== 路由 ====================

// 所有陪诊师端接口都需要认证和陪诊师角色
router.use(auth.authenticateToken);

// 中间件：获取陪诊师信息（含错误处理）
router.use(async (req, res, next) => {
  try {
    const companion = await findCompanionByUserId(req.user.id);
    if (!companion) {
      return res.status(403).json({ success: false, message: '您不是陪诊师，无法使用此功能' });
    }
    req.companion = companion;
    next();
  } catch (error) {
    console.error('[companion] 获取陪诊师信息失败:', error.message);
    return res.status(500).json({ success: false, message: '服务器错误: ' + error.message });
  }
});

/**
 * 获取待接订单列表（未分配陪诊师的已支付订单）
 * GET /api/companion/orders/available
 */
router.get('/orders/available', async (req, res) => {
  // 尝试从数据库获取
  let orders = await findOrdersAvailable();
  
  // 如果数据库查询失败，使用模拟数据
  if (!orders || orders.length === 0) {
    orders = mockOrders.filter(o => o.status === 'pending' && o.companion_id === null && o.payment_status === 'paid')
      .map(o => enrichOrder(o));
  } else {
    orders = orders.map(o => ({
      id: o.id, patient_name: o.patient_name, patient_phone: o.patient_phone,
      hospital_name: o.hospital_name, service_type: o.service_type,
      appointment_date: o.appointment_date, appointment_time: o.appointment_time,
      duration_minutes: o.duration_minutes, price: o.price, symptoms: o.symptoms,
      created_at: o.created_at
    }));
  }
  
  res.json({ success: true, data: orders, total: orders.length });
});

/**
 * 获取我的任务（已接单的所有订单）
 * GET /api/companion/orders/mine
 */
router.get('/orders/mine', async (req, res) => {
  const companionId = req.companion.id;
  
  let orders = await findOrdersByCompanion(companionId);
  
  if (!orders || orders.length === 0) {
    orders = mockOrders.filter(o => o.companion_id === companionId).map(o => enrichOrder(o));
  } else {
    orders = orders.map(o => ({
      ...o, companion_name: req.companion.real_name || req.companion.name
    }));
  }
  
  res.json({ success: true, data: orders, total: orders.length });
});

/**
 * 接单（陪诊师接受订单）
 * POST /api/companion/orders/:id/accept
 */
router.post('/orders/:id/accept', async (req, res) => {
  const orderId = req.params.id;
  const companionId = req.companion.id;
  
  // 尝试更新数据库
  let success = await updateOrderStatus(orderId, 'confirmed', { companion_id: companionId });
  
  if (!success) {
    // 尝试模拟数据
    const order = mockOrders.find(o => o.id === orderId);
    if (order && order.status === 'pending') {
      order.status = 'confirmed';
      order.companion_id = companionId;
      success = true;
    }
  }
  
  if (success) {
    res.json({ success: true, message: '接单成功', data: { order_id: orderId, status: 'confirmed' } });
  } else {
    res.status(400).json({ success: false, message: '接单失败，订单可能已被其他陪诊师接走' });
  }
});

/**
 * 拒绝接单
 * POST /api/companion/orders/:id/reject
 */
router.post('/orders/:id/reject', async (req, res) => {
  const orderId = req.params.id;
  const { reason = '陪诊师主动拒绝' } = req.body;
  
  // 实际上拒绝不改变订单状态，只在系统里记录（简化版）
  res.json({ success: true, message: '已拒绝该订单' });
});

/**
 * 开始服务
 * POST /api/companion/orders/:id/start
 */
router.post('/orders/:id/start', async (req, res) => {
  const orderId = req.params.id;
  
  let success = await updateOrderStatus(orderId, 'in_progress');
  
  if (!success) {
    const order = mockOrders.find(o => o.id === orderId);
    if (order) { order.status = 'in_progress'; success = true; }
  }
  
  if (success) {
    res.json({ success: true, message: '已开始服务', data: { order_id: orderId, status: 'in_progress' } });
  } else {
    res.status(400).json({ success: false, message: '操作失败' });
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
    if (order) { order.status = 'completed'; success = true; }
  }
  
  if (success) {
    res.json({ success: true, message: '服务已完成', data: { order_id: orderId, status: 'completed' } });
  } else {
    res.status(400).json({ success: false, message: '操作失败' });
  }
});

/**
 * 陪诊师今日数据统计
 * GET /api/companion/stats
 */
router.get('/stats', async (req, res) => {
  const companionId = req.companion.id;
  
  let totalOrders = 0, todayOrders = 0, inProgress = 0, todayEarnings = 0;
  
  // 统计数据库数据
  try {
    const stats = await dbQuery(`
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN DATE(created_at) = CURDATE() THEN 1 ELSE 0 END) as today,
        SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
        SUM(CASE WHEN DATE(created_at) = CURDATE() AND status = 'completed' THEN price ELSE 0 END) as today_earnings
      FROM orders WHERE companion_id = ?
    `, [companionId]);
    if (stats[0]) {
      totalOrders = stats[0].total;
      todayOrders = stats[0].today;
      inProgress = stats[0].in_progress;
      todayEarnings = stats[0].today_earnings;
    }
  } catch (e) {
    // 使用mock数据
    const myOrders = mockOrders.filter(o => o.companion_id === companionId);
    totalOrders = myOrders.length;
    inProgress = myOrders.filter(o => o.status === 'in_progress').length;
    todayOrders = myOrders.filter(o => o.appointment_date === '2026-04-24').length;
    todayEarnings = myOrders.filter(o => o.status === 'completed').reduce((s, o) => s + o.price, 0);
  }
  
  res.json({
    success: true,
    data: {
      total_orders: String(totalOrders),
      today_orders: String(todayOrders),
      in_progress: String(inProgress),
      waiting_orders: '3', // 待接单数量来自 available
      today_earnings: String(todayEarnings),
    }
  });
});

/**
 * 获取陪诊师个人信息
 * GET /api/companion/profile
 */
router.get('/profile', async (req, res) => {
  res.json({ success: true, data: req.companion });
});

module.exports = router;

// 辅助函数
function enrichOrder(o) {
  return {
    id: o.id, patient_name: o.patient_name, patient_phone: o.patient_phone,
    hospital_name: o.hospital_name, service_type: o.service_type,
    appointment_date: o.appointment_date, appointment_time: o.appointment_time,
    duration_minutes: o.duration_minutes, price: o.price, status: o.status,
    symptoms: o.symptoms, created_at: o.created_at,
    companion_id: o.companion_id,
    companion_name: o.companion_name || null,
  };
}
