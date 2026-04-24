import { Router } from 'express';
import db from '../config/database';
import { authenticate } from '../middleware/auth';

const router = Router();

// 获取聊天室列表
router.get('/rooms', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // 获取用户相关的所有聊天室
    const rooms = await db('chat_messages')
      .select('room_id')
      .where('sender_id', userId)
      .orWhere('receiver_id', userId)
      .groupBy('room_id')
      .orderBy('created_at', 'desc');
    
    // 获取每个聊天室的最后一条消息和对方信息
    const roomDetails = await Promise.all(
      rooms.map(async (room) => {
        const lastMessage = await db('chat_messages')
          .where('room_id', room.room_id)
          .orderBy('created_at', 'desc')
          .first();
        
        // 获取对方用户信息
        const otherUserId = lastMessage.sender_id === userId 
          ? lastMessage.receiver_id 
          : lastMessage.sender_id;
        
        const otherUser = await db('users')
          .where('id', otherUserId)
          .select('id', 'name', 'avatar', 'role')
          .first();
        
        // 获取未读消息数
        const unreadCount = await db('chat_messages')
          .where('room_id', room.room_id)
          .where('receiver_id', userId)
          .where('is_read', false)
          .count('* as count')
          .first();
        
        return {
          room_id: room.room_id,
          last_message: {
            content: lastMessage.content,
            message_type: lastMessage.message_type,
            created_at: lastMessage.created_at,
            is_read: lastMessage.is_read
          },
          other_user: otherUser,
          unread_count: parseInt(unreadCount?.count || '0')
        };
      })
    );
    
    res.json({
      success: true,
      data: {
        rooms: roomDetails
      }
    });
  } catch (error) {
    console.error('获取聊天室列表失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '获取聊天室列表失败' 
    });
  }
});

// 获取聊天消息
router.get('/messages/:roomId', authenticate, async (req, res) => {
  try {
    const { roomId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const userId = req.user.id;
    
    // 验证用户是否有权限访问这个聊天室
    const hasAccess = await db('chat_messages')
      .where('room_id', roomId)
      .andWhere(function() {
        this.where('sender_id', userId).orWhere('receiver_id', userId);
      })
      .first();
    
    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        error: '无权访问此聊天室'
      });
    }
    
    // 获取消息
    const offset = (parseInt(page as string) - 1) * parseInt(limit as string);
    
    const messages = await db('chat_messages')
      .where('room_id', roomId)
      .orderBy('created_at', 'desc')
      .offset(offset)
      .limit(parseInt(limit as string));
    
    // 获取对方用户信息
    const otherUserId = messages.find(m => 
      m.sender_id !== userId && m.receiver_id !== userId
    )?.sender_id || messages[0]?.sender_id;
    
    const otherUser = await db('users')
      .where('id', otherUserId)
      .select('id', 'name', 'avatar', 'role')
      .first();
    
    // 标记消息为已读
    await db('chat_messages')
      .where('room_id', roomId)
      .where('receiver_id', userId)
      .where('is_read', false)
      .update({
        is_read: true,
        updated_at: new Date()
      });
    
    res.json({
      success: true,
      data: {
        messages: messages.reverse(), // 按时间正序返回
        other_user: otherUser,
        pagination: {
          page: parseInt(page as string),
          limit: parseInt(limit as string),
          has_more: messages.length === parseInt(limit as string)
        }
      }
    });
  } catch (error) {
    console.error('获取聊天消息失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '获取聊天消息失败' 
    });
  }
});

// 发送消息
router.post('/send', authenticate, async (req, res) => {
  try {
    const { room_id, receiver_id, message_type = 'text', content } = req.body;
    const sender_id = req.user.id;
    
    if (!room_id || !receiver_id || !content) {
      return res.status(400).json({
        success: false,
        error: '缺少必要参数'
      });
    }
    
    // 验证接收者是否存在
    const receiver = await db('users')
      .where('id', receiver_id)
      .first();
    
    if (!receiver) {
      return res.status(404).json({
        success: false,
        error: '接收者不存在'
      });
    }
    
    // 保存消息
    const [messageId] = await db('chat_messages').insert({
      room_id,
      sender_id,
      receiver_id,
      message_type,
      content,
      is_read: false,
      created_at: new Date(),
      updated_at: new Date()
    });
    
    // 获取完整的消息信息
    const message = await db('chat_messages')
      .where('id', messageId)
      .first();
    
    // 获取发送者信息
    const sender = await db('users')
      .where('id', sender_id)
      .select('id', 'name', 'avatar')
      .first();
    
    res.json({
      success: true,
      data: {
        message: {
          ...message,
          sender
        }
      }
    });
  } catch (error) {
    console.error('发送消息失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '发送消息失败' 
    });
  }
});

// 创建聊天室（基于订单）
router.post('/room/create', authenticate, async (req, res) => {
  try {
    const { order_no } = req.body;
    const userId = req.user.id;
    
    if (!order_no) {
      return res.status(400).json({
        success: false,
        error: '缺少订单号'
      });
    }
    
    // 获取订单信息
    const order = await db('orders')
      .where('order_no', order_no)
      .first();
    
    if (!order) {
      return res.status(404).json({
        success: false,
        error: '订单不存在'
      });
    }
    
    // 检查用户是否与订单相关
    const isRelated = order.patient_id === userId || order.companion_id === userId;
    if (!isRelated) {
      return res.status(403).json({
        success: false,
        error: '无权创建此聊天室'
      });
    }
    
    // 生成聊天室ID
    const roomId = `order_${order_no}`;
    
    // 检查聊天室是否已存在
    const existingRoom = await db('chat_messages')
      .where('room_id', roomId)
      .first();
    
    if (existingRoom) {
      return res.json({
        success: true,
        data: {
          room_id: roomId,
          exists: true
        }
      });
    }
    
    // 创建系统欢迎消息
    const systemMessage = {
      room_id: roomId,
      sender_id: 0, // 系统用户
      receiver_id: userId,
      message_type: 'system',
      content: '聊天室已创建，您可以开始与对方沟通了。',
      is_read: false,
      created_at: new Date(),
      updated_at: new Date()
    };
    
    await db('chat_messages').insert(systemMessage);
    
    res.json({
      success: true,
      data: {
        room_id: roomId,
        exists: false
      }
    });
  } catch (error) {
    console.error('创建聊天室失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '创建聊天室失败' 
    });
  }
});

// 上传聊天图片
router.post('/upload/image', authenticate, async (req, res) => {
  try {
    // 这里需要集成文件上传中间件
    // 实际实现时需要使用multer等中间件处理文件上传
    
    res.json({
      success: true,
      data: {
        url: '/uploads/chat/images/example.jpg', // 示例URL
        thumbnail_url: '/uploads/chat/images/example_thumb.jpg'
      }
    });
  } catch (error) {
    console.error('上传图片失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '上传图片失败' 
    });
  }
});

// 上传语音消息
router.post('/upload/voice', authenticate, async (req, res) => {
  try {
    // 语音消息上传处理
    
    res.json({
      success: true,
      data: {
        url: '/uploads/chat/voice/example.mp3',
        duration: 30 // 语音时长（秒）
      }
    });
  } catch (error) {
    console.error('上传语音失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '上传语音失败' 
    });
  }
});

// 删除消息
router.delete('/message/:messageId', authenticate, async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user.id;
    
    // 检查消息是否存在且用户是发送者
    const message = await db('chat_messages')
      .where('id', messageId)
      .where('sender_id', userId)
      .first();
    
    if (!message) {
      return res.status(404).json({
        success: false,
        error: '消息不存在或无权删除'
      });
    }
    
    // 软删除：更新内容为"消息已删除"
    await db('chat_messages')
      .where('id', messageId)
      .update({
        content: '消息已删除',
        message_type: 'system',
        updated_at: new Date()
      });
    
    res.json({
      success: true,
      data: {
        message: '消息已删除'
      }
    });
  } catch (error) {
    console.error('删除消息失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '删除消息失败' 
    });
  }
});

// 清空聊天记录
router.delete('/room/:roomId/clear', authenticate, async (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user.id;
    
    // 检查用户是否有权限访问这个聊天室
    const hasAccess = await db('chat_messages')
      .where('room_id', roomId)
      .andWhere(function() {
        this.where('sender_id', userId).orWhere('receiver_id', userId);
      })
      .first();
    
    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        error: '无权清空此聊天室'
      });
    }
    
    // 实际应用中可能采用软删除或归档
    // 这里示例为更新消息内容
    await db('chat_messages')
      .where('room_id', roomId)
      .where('sender_id', userId)
      .update({
        content: '消息已清空',
        updated_at: new Date()
      });
    
    res.json({
      success: true,
      data: {
        message: '聊天记录已清空'
      }
    });
  } catch (error) {
    console.error('清空聊天记录失败:', error);
    res.status(500).json({ 
      success: false, 
      error: '清空聊天记录失败' 
    });
  }
});

export default router;