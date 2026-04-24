const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

// 模拟数据
let orders = [
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
  }
];

const users = [
  { id: 'user_001', name: '张三', phone: '13800138000' }
];

const hospitals = [
  { id: 'hospital_001', name: '北京协和医院', level: '三甲' }
];

const companions = [
  { id: 'companion_001', name: '李医生', level: '高级' }
];

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: '医小伴测试API',
    version: '1.0.0',
    environment: 'development'
  });
});

// 获取订单列表
app.get('/api/orders', (req, res) => {
  try {
    const { user_id, status, page = 1, limit = 10 } = req.query;
    
    let filteredOrders = [...orders];
    
    if (user_id) {
      filteredOrders = filteredOrders.filter(order => order.user_id === user_id);
    }
    
    if (status) {
      filteredOrders = filteredOrders.filter(order => order.status === status);
    }
    
    const startIndex = (page - 1) * limit;
    const endIndex = page * limit;
    const paginatedOrders = filteredOrders.slice(startIndex, endIndex);
    
    const enrichedOrders = paginatedOrders.map(order => {
      const user = users.find(u => u.id === order.user_id);
      const hospital = hospitals.find(h => h.id === order.hospital_id);
      const companion = companions.find(c => c.id === order.companion_id);
      
      return {
        ...order,
        user_name: user?.name || '未知用户',
        hospital_name: hospital?.name || '未知医院',
        companion_name: companion?.name || '未知陪诊师',
      };
    });
    
    res.json({
      success: true,
      data: enrichedOrders,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: filteredOrders.length,
        total_pages: Math.ceil(filteredOrders.length / limit),
      },
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

// 创建订单
app.post('/api/orders', (req, res) => {
  try {
    const {
      user_id,
      hospital_id,
      companion_id,
      service_type = '普通陪诊',
      appointment_time,
      duration_minutes = 120,
    } = req.body;
    
    if (!user_id || !hospital_id || !companion_id || !appointment_time) {
      return res.status(400).json({
        success: false,
        message: '缺少必填字段',
        required_fields: ['user_id', 'hospital_id', 'companion_id', 'appointment_time'],
      });
    }
    
    const user = users.find(u => u.id === user_id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: '用户不存在',
      });
    }
    
    const hospital = hospitals.find(h => h.id === hospital_id);
    if (!hospital) {
      return res.status(404).json({
        success: false,
        message: '医院不存在',
      });
    }
    
    const companion = companions.find(c => c.id === companion_id);
    if (!companion) {
      return res.status(404).json({
        success: false,
        message: '陪诊师不存在',
      });
    }
    
    // 计算价格
    const price = calculatePrice(service_type, duration_minutes, companion.level);
    
    const newOrder = {
      id: `order_${uuidv4().substring(0, 8)}`,
      user_id,
      hospital_id,
      companion_id,
      service_type,
      appointment_time,
      duration_minutes,
      price,
      status: 'pending',
      payment_method: null,
      payment_status: 'unpaid',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    orders.push(newOrder);
    
    const enrichedOrder = {
      ...newOrder,
      user_name: user.name,
      hospital_name: hospital.name,
      companion_name: companion.name,
    };
    
    res.status(201).json({
      success: true,
      message: '订单创建成功',
      data: enrichedOrder,
      payment_info: {
        order_id: newOrder.id,
        amount: price,
        currency: 'CNY',
        payment_url: `https://payment.example.com/pay/${newOrder.id}`,
      },
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

// 支付订单
app.post('/api/orders/:id/pay', (req, res) => {
  try {
    const { id } = req.params;
    const { payment_method, payment_amount } = req.body;
    
    const orderIndex = orders.findIndex(o => o.id === id);
    
    if (orderIndex === -1) {
      return res.status(404).json({
        success: false,
        message: '订单不存在',
      });
    }
    
    const order = orders[orderIndex];
    
    if (order.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: '订单状态不允许支付',
        current_status: order.status,
      });
    }
    
    if (payment_amount !== order.price) {
      return res.status(400).json({
        success: false,
        message: '支付金额不正确',
        expected_amount: order.price,
        provided_amount: payment_amount,
      });
    }
    
    orders[orderIndex].payment_method = payment_method;
    orders[orderIndex].payment_status = 'paid';
    orders[orderIndex].status = 'confirmed';
    orders[orderIndex].updated_at = new Date().toISOString();
    
    res.json({
      success: true,
      message: '支付成功',
      data: {
        order_id: order.id,
        payment_status: 'paid',
        order_status: 'confirmed',
        payment_time: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error('支付订单失败:', error);
    res.status(500).json({
      success: false,
      message: '支付订单失败',
      error: error.message,
    });
  }
});

// 计算价格函数
function calculatePrice(serviceType, durationMinutes, companionLevel) {
  let basePrice = 199.0;
  const serviceFee = 30.0;
  
  switch (serviceType) {
    case '专业陪诊':
      basePrice *= 1.5;
      break;
    case '急诊陪诊':
      basePrice *= 2.0;
      break;
    case '长期陪护':
      basePrice *= 3.0;
      break;
  }
  
  const hours = durationMinutes / 60;
  basePrice *= hours;
  
  switch (companionLevel) {
    case '高级':
      basePrice *= 1.3;
      break;
    case '专家':
      basePrice *= 1.5;
      break;
  }
  
  return parseFloat((basePrice + serviceFee).toFixed(2));
}

app.listen(PORT, () => {
  console.log(`🧪 医小伴测试API运行在端口 ${PORT}`);
  console.log(`🩺 健康检查: http://localhost:${PORT}/health`);
  console.log(`📋 订单API: http://localhost:${PORT}/api/orders`);
  console.log(`🚀 测试服务器已启动！`);
});