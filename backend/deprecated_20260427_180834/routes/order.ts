import { Router } from 'express';
import db from '../config/database';
import { authenticate } from '../middleware/auth';
import { validateOrderCreate } from '../validators/order';

const router = Router();

// 创建订单
router.post('/', authenticate, validateOrderCreate, async (req, res) => {
  try {
    const { 
      hospital_id, 
      department, 
      doctor_name, 
      appointment_time, 
      address,
      requirements,
      service_type,
      hours 
    } = req.body;
    
    const patient_id = req.user.id;
    
    // 计算费用
    const hourly_rate = 80; // 时薪
    const platform_fee_rate = 0.15; // 平台费15%
    
    const base_amount = hours * hourly_rate;
    const platform_fee = base_amount * platform_fee_rate;
    const amount = base_amount + platform_fee;
    const companion_income = base_amount;
    
    // 生成订单号
    const order_no = `ORD${Date.now()}${Math.floor(Math.random() * 1000)}`;
    
    const [orderId] = await db('orders').insert({
      order_no,
      patient_id,
      hospital_id,
      department,
      doctor_name,
      appointment_time,
      address,
      requirements,
      service_type,
      hours,
      amount,
      platform_fee,
      companion_income,
      status: 'pending'
    });
    
    res.status(201).json({
      success: true,
      data: {
        order_no,
        amount,
        status: 'pending'
      }
    });
  } catch (error) {
    console.error('创建订单失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '创建订单失败' 
    });
  }
});

// 获取订单列表
router.get('/', authenticate, async (req, res) => {
  try {
    const { role } = req.user;
    const { status, page = 1, limit = 10 } = req.query;
    
    let query = db('orders')
      .select('*')
      .orderBy('created_at', 'desc');
    
    // 根据用户角色过滤
    if (role === 'patient') {
      query = query.where('patient_id', req.user.id);
    } else if (role === 'companion') {
      query = query.where('companion_id', req.user.id);
    }
    
    // 状态过滤
    if (status) {
      query = query.where('status', status);
    }
    
    // 分页
    const offset = (parseInt(page as string) - 1) * parseInt(limit as string);
    const total = await query.clone().count('* as count').first();
    
    const orders = await query
      .offset(offset)
      .limit(parseInt(limit as string));
    
    // 关联医院信息
    const ordersWithDetails = await Promise.all(
      orders.map(async (order) => {
        const hospital = await db('hospitals')
          .where('id', order.hospital_id)
          .first();
        
        const patient = await db('users')
          .where('id', order.patient_id)
          .select('id', 'name', 'avatar', 'phone')
          .first();
        
        let companion = null;
        if (order.companion_id) {
          companion = await db('users')
            .where('id', order.companion_id)
            .select('id', 'name', 'avatar', 'phone', 'rating')
            .first();
        }
        
        return {
          ...order,
          hospital,
          patient,
          companion
        };
      })
    );
    
    res.json({
      success: true,
      data: {
        orders: ordersWithDetails,
        pagination: {
          page: parseInt(page as string),
          limit: parseInt(limit as string),
          total: total?.count || 0
        }
      }
    });
  } catch (error) {
    console.error('获取订单列表失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '获取订单列表失败' 
    });
  }
});

// 获取订单详情
router.get('/:order_no', authenticate, async (req, res) => {
  try {
    const { order_no } = req.params;
    
    const order = await db('orders')
      .where('order_no', order_no)
      .first();
    
    if (!order) {
      return res.status(404).json({
        success: false,
        error: '订单不存在'
      });
    }
    
    // 检查权限
    if (req.user.role === 'patient' && order.patient_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: '无权访问此订单'
      });
    }
    
    if (req.user.role === 'companion' && order.companion_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: '无权访问此订单'
      });
    }
    
    // 获取关联信息
    const hospital = await db('hospitals')
      .where('id', order.hospital_id)
      .first();
    
    const patient = await db('users')
      .where('id', order.patient_id)
      .select('id', 'name', 'avatar', 'phone')
      .first();
    
    let companion = null;
    if (order.companion_id) {
      companion = await db('users')
        .where('id', order.companion_id)
        .select('id', 'name', 'avatar', 'phone', 'rating')
        .first();
    }
    
    // 获取支付信息
    const payment = await db('payments')
      .where('order_no', order_no)
      .orderBy('created_at', 'desc')
      .first();
    
    // 获取评价
    const review = await db('reviews')
      .where('order_no', order_no)
      .first();
    
    res.json({
      success: true,
      data: {
        order: {
          ...order,
          hospital,
          patient,
          companion,
          payment,
          review
        }
      }
    });
  } catch (error) {
    console.error('获取订单详情失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '获取订单详情失败' 
    });
  }
});

// 陪诊师接单
router.post('/:order_no/accept', authenticate, async (req, res) => {
  try {
    const { order_no } = req.params;
    
    // 检查用户是否为陪诊师
    if (req.user.role !== 'companion') {
      return res.status(403).json({
        success: false,
        error: '只有陪诊师可以接单'
      });
    }
    
    const order = await db('orders')
      .where('order_no', order_no)
      .where('status', 'pending')
      .first();
    
    if (!order) {
      return res.status(404).json({
        success: false,
        error: '订单不存在或已被接单'
      });
    }
    
    // 更新订单状态
    await db('orders')
      .where('order_no', order_no)
      .update({
        companion_id: req.user.id,
        status: 'accepted',
        updated_at: new Date()
      });
    
    res.json({
      success: true,
      data: {
        message: '接单成功'
      }
    });
  } catch (error) {
    console.error('接单失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '接单失败' 
    });
  }
});

// 开始服务
router.post('/:order_no/start', authenticate, async (req, res) => {
  try {
    const { order_no } = req.params;
    
    const order = await db('orders')
      .where('order_no', order_no)
      .where('companion_id', req.user.id)
      .where('status', 'accepted')
      .first();
    
    if (!order) {
      return res.status(404).json({
        success: false,
        error: '订单不存在或状态不正确'
      });
    }
    
    await db('orders')
      .where('order_no', order_no)
      .update({
        status: 'ongoing',
        start_time: new Date(),
        updated_at: new Date()
      });
    
    res.json({
      success: true,
      data: {
        message: '服务开始'
      }
    });
  } catch (error) {
    console.error('开始服务失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '开始服务失败' 
    });
  }
});

// 完成服务
router.post('/:order_no/complete', authenticate, async (req, res) => {
  try {
    const { order_no } = req.params;
    
    const order = await db('orders')
      .where('order_no', order_no)
      .where('companion_id', req.user.id)
      .where('status', 'ongoing')
      .first();
    
    if (!order) {
      return res.status(404).json({
        success: false,
        error: '订单不存在或状态不正确'
      });
    }
    
    await db('orders')
      .where('order_no', order_no)
      .update({
        status: 'completed',
        end_time: new Date(),
        updated_at: new Date()
      });
    
    // 更新陪诊师收入
    await db('users')
      .where('id', req.user.id)
      .increment('balance', order.companion_income);
    
    res.json({
      success: true,
      data: {
        message: '服务完成',
        income: order.companion_income
      }
    });
  } catch (error) {
    console.error('完成服务失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '完成服务失败' 
    });
  }
});

// 取消订单
router.post('/:order_no/cancel', authenticate, async (req, res) => {
  try {
    const { order_no } = req.params;
    const { reason } = req.body;
    
    const order = await db('orders')
      .where('order_no', order_no)
      .whereIn('status', ['pending', 'accepted'])
      .first();
    
    if (!order) {
      return res.status(404).json({
        success: false,
        error: '订单不存在或无法取消'
      });
    }
    
    // 检查权限
    const canCancel = order.patient_id === req.user.id || 
                     order.companion_id === req.user.id;
    
    if (!canCancel) {
      return res.status(403).json({
        success: false,
        error: '无权取消此订单'
      });
    }
    
    await db('orders')
      .where('order_no', order_no)
      .update({
        status: 'cancelled',
        cancellation_reason: reason,
        updated_at: new Date()
      });
    
    // 如果有支付，处理退款
    if (order.status === 'accepted') {
      // TODO: 调用支付退款接口
    }
    
    res.json({
      success: true,
      data: {
        message: '订单已取消'
      }
    });
  } catch (error) {
    console.error('取消订单失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '取消订单失败' 
    });
  }
});

export default router;