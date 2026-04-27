const express = require('express');
const router = express.Router();

// 模拟订单数据
const mockOrders = [
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
    hospital_name: '北京协和医院',
    companion_name: '张医生',
    user_name: '张三',
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
    hospital_name: '上海华山医院',
    companion_name: '李护士',
    user_name: '张三',
  },
  {
    id: 'order_003',
    user_id: 'user_001',
    hospital_id: 'hospital_003',
    companion_id: 'companion_001',
    service_type: '急诊陪诊',
    appointment_time: '2026-04-05T18:00:00Z',
    duration_minutes: 240,
    price: 450.0,
    status: 'completed',
    payment_method: 'alipay',
    payment_status: 'paid',
    created_at: '2026-04-04T15:00:00Z',
    updated_at: '2026-04-05T22:00:00Z',
    hospital_name: '广州中山医院',
    companion_name: '张医生',
    user_name: '张三',
  },
  {
    id: 'order_004',
    user_id: 'user_001',
    hospital_id: 'hospital_001',
    companion_id: 'companion_002',
    service_type: '普通陪诊',
    appointment_time: '2026-04-10T10:00:00Z',
    duration_minutes: 120,
    price: 229.0,
    status: 'cancelled',
    payment_method: null,
    payment_status: 'unpaid',
    created_at: '2026-04-03T12:00:00Z',
    updated_at: '2026-04-03T13:00:00Z',
    hospital_name: '北京协和医院',
    companion_name: '李护士',
    user_name: '张三',
  },
];

// 完全跳过认证
router.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] 测试订单API: ${req.method} ${req.url}`);
  next();
});

// 获取订单列表
router.get('/', (req, res) => {
  try {
    const { user_id, status } = req.query;
    
    let filteredOrders = [...mockOrders];
    
    // 用户ID过滤
    if (user_id) {
      filteredOrders = filteredOrders.filter(o => o.user_id === user_id);
    }
    
    // 状态过滤
    if (status && status !== 'all') {
      filteredOrders = filteredOrders.filter(o => o.status === status);
    }
    
    res.json({
      success: true,
      data: filteredOrders,
      message: '获取订单列表成功',
      timestamp: new Date().toISOString(),
      total: filteredOrders.length,
    });
  } catch (error) {
    console.error('获取订单列表失败:', error);
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
    const order = mockOrders.find(o => o.id === req.params.id);
    
    if (!order) {
      return res.status(404).json({
        success: false,
        message: '订单不存在',
      });
    }
    
    res.json({
      success: true,
      data: order,
      message: '获取订单详情成功',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('获取订单详情失败:', error);
    res.status(500).json({
      success: false,
      message: '获取订单详情失败',
      error: error.message,
    });
  }
});

// 创建订单
router.post('/', (req, res) => {
  try {
    const orderData = req.body;
    
    // 生成订单ID
    const orderId = `order_${Date.now()}`;
    
    const newOrder = {
      id: orderId,
      user_id: orderData.user_id || 'user_001',
      hospital_id: orderData.hospital_id || 'hospital_001',
      companion_id: orderData.companion_id || 'companion_001',
      service_type: orderData.service_type || '普通陪诊',
      appointment_time: orderData.appointment_time || new Date().toISOString(),
      duration_minutes: orderData.duration_minutes || 120,
      price: orderData.price || 229.0,
      status: 'pending',
      payment_method: null,
      payment_status: 'unpaid',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      hospital_name: '测试医院',
      companion_name: '测试陪诊师',
      user_name: '测试用户',
    };
    
    // 添加到模拟数据
    mockOrders.push(newOrder);
    
    res.json({
      success: true,
      data: newOrder,
      message: '创建订单成功',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('创建订单失败:', error);
    res.status(500).json({
      success: false,
      message: '创建订单失败',
      error: error.message,
    });
  }
});

// 更新订单状态
router.put('/:id/status', (req, res) => {
  try {
    const { status } = req.body;
    const orderIndex = mockOrders.findIndex(o => o.id === req.params.id);
    
    if (orderIndex === -1) {
      return res.status(404).json({
        success: false,
        message: '订单不存在',
      });
    }
    
    mockOrders[orderIndex].status = status;
    mockOrders[orderIndex].updated_at = new Date().toISOString();
    
    res.json({
      success: true,
      data: mockOrders[orderIndex],
      message: '更新订单状态成功',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('更新订单状态失败:', error);
    res.status(500).json({
      success: false,
      message: '更新订单状态失败',
      error: error.message,
    });
  }
});

// 订单统计
router.get('/stats/summary', (req, res) => {
  try {
    const totalOrders = mockOrders.length;
    const pendingOrders = mockOrders.filter(o => o.status === 'pending').length;
    const confirmedOrders = mockOrders.filter(o => o.status === 'confirmed').length;
    const inProgressOrders = mockOrders.filter(o => o.status === 'in_progress').length;
    const completedOrders = mockOrders.filter(o => o.status === 'completed').length;
    const cancelledOrders = mockOrders.filter(o => o.status === 'cancelled').length;
    
    const totalRevenue = mockOrders
      .filter(o => o.payment_status === 'paid')
      .reduce((sum, order) => sum + order.price, 0);
    
    res.json({
      success: true,
      data: {
        total_orders: totalOrders,
        pending_orders: pendingOrders,
        confirmed_orders: confirmedOrders,
        in_progress_orders: inProgressOrders,
        completed_orders: completedOrders,
        cancelled_orders: cancelledOrders,
        total_revenue: totalRevenue,
      },
      message: '获取订单统计成功',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('获取订单统计失败:', error);
    res.status(500).json({
      success: false,
      message: '获取订单统计失败',
      error: error.message,
    });
  }
});

module.exports = router;