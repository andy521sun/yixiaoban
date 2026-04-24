const express = require('express');
const router = express.Router();

// 模拟数据库
const orders = [
  {
    id: 'order_001',
    user_id: 'user_001',
    hospital_id: 'hospital_001',
    companion_id: 'companion_001',
    service_type: '普通陪诊',
    appointment_time: '2026-04-08T09:00:00Z',
    duration_minutes: 120,
    price: 229.0,
    status: 'pending',
    payment_method: null,
    payment_status: 'unpaid',
    created_at: '2026-04-07T08:00:00Z',
    updated_at: '2026-04-07T08:00:00Z',
  },
  {
    id: 'order_002',
    user_id: 'user_001',
    hospital_id: 'hospital_002',
    companion_id: 'companion_002',
    service_type: '专业陪诊',
    appointment_time: '2026-04-09T14:00:00Z',
    duration_minutes: 180,
    price: 320.0,
    status: 'confirmed',
    payment_method: 'wechat',
    payment_status: 'paid',
    created_at: '2026-04-06T10:00:00Z',
    updated_at: '2026-04-06T10:05:00Z',
  },
];

// 模拟数据
const users = [{ id: 'user_001', name: '张三' }];
const hospitals = [
  { id: 'hospital_001', name: '北京协和医院' },
  { id: 'hospital_002', name: '上海华山医院' },
];
const companions = [
  { id: 'companion_001', name: '张医生' },
  { id: 'companion_002', name: '李护士' },
];

// 完全跳过认证
router.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// 获取订单列表
router.get('/', (req, res) => {
  try {
    const { user_id } = req.query;
    
    let filteredOrders = [...orders];
    if (user_id) {
      filteredOrders = filteredOrders.filter(o => o.user_id === user_id);
    }
    
    const enrichedOrders = filteredOrders.map(order => ({
      ...order,
      user_name: users.find(u => u.id === order.user_id)?.name || '未知用户',
      hospital_name: hospitals.find(h => h.id === order.hospital_id)?.name || '未知医院',
      companion_name: companions.find(c => c.id === order.companion_id)?.name || '未知陪诊师',
    }));
    
    res.json({
      success: true,
      data: enrichedOrders,
      message: '获取订单列表成功',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取订单列表失败',
      error: error.message,
    });
  }
});

// 获取订单详情
router.get('/:id', (req, res) => {
  try {
    const order = orders.find(o => o.id === req.params.id);
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在',
      });
    }
    
    const enrichedOrder = {
      ...order,
      user_name: users.find(u => u.id === order.user_id)?.name || '未知用户',
      hospital_name: hospitals.find(h => h.id === order.hospital_id)?.name || '未知医院',
      companion_name: companions.find(c => c.id === order.companion_id)?.name || '未知陪诊师',
    };
    
    res.json({
      success: true,
      data: enrichedOrder,
      message: '获取订单详情成功',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取订单详情失败',
      error: error.message,
    });
  }
});

// 订单统计
router.get('/stats', (req, res) => {
  try {
    const { user_id } = req.query;
    
    let filteredOrders = [...orders];
    if (user_id) {
      filteredOrders = filteredOrders.filter(o => o.user_id === user_id);
    }
    
    const stats = {
      total_orders: filteredOrders.length,
      total_amount: filteredOrders.reduce((sum, o) => sum + o.price, 0),
      status_counts: {
        pending: filteredOrders.filter(o => o.status === 'pending').length,
        confirmed: filteredOrders.filter(o => o.status === 'confirmed').length,
        completed: filteredOrders.filter(o => o.status === 'completed').length,
        cancelled: filteredOrders.filter(o => o.status === 'cancelled').length,
      }
    };
    
    res.json({
      success: true,
      data: stats,
      message: '获取订单统计成功',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '获取订单统计失败',
      error: error.message,
    });
  }
});

// 创建订单
router.post('/', (req, res) => {
  try {
    const newOrder = {
      id: `order_${Date.now()}`,
      ...req.body,
      status: 'pending',
      payment_status: 'unpaid',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    orders.push(newOrder);
    
    res.json({
      success: true,
      data: newOrder,
      message: '创建订单成功',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '创建订单失败',
      error: error.message,
    });
  }
});

module.exports = router;