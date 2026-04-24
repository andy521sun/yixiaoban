const express = require('express');
const router = express.Router();
const { query } = require('../db');
const auth = require('../auth');

// 中间件：认证
async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // 允许未认证访问（返回空数据）
      req.user = null;
      return next();
    }
    const token = authHeader.split(' ')[1];
    const user = auth.verifyToken(token);
    req.user = user;
    next();
  } catch (error) {
    req.user = null;
    next();
  }
}

// 获取聊天室列表
router.get('/rooms', authenticate, async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.json({ success: true, data: { rooms: [] } });
    }

    // 获取用户相关的所有聊天室
    const rooms = await query(
      'SELECT DISTINCT room_id FROM chat_messages WHERE sender_id = ? OR receiver_id = ? ORDER BY created_at DESC',
      [userId, userId]
    );

    // 获取每个聊天室的最后一条消息和对方信息
    const roomDetails = await Promise.all(
      rooms.map(async (room) => {
        const lastMessages = await query(
          'SELECT * FROM chat_messages WHERE room_id = ? ORDER BY created_at DESC LIMIT 1',
          [room.room_id]
        );
        
        if (!lastMessages.length) return null;
        const lastMessage = lastMessages[0];
        
        // 获取对方用户信息
        const otherUserId = lastMessage.sender_id === userId 
          ? lastMessage.receiver_id 
          : lastMessage.sender_id;
        
        const otherUsers = await query(
          'SELECT id, name, avatar_url as avatar, role FROM users WHERE id = ?',
          [otherUserId]
        );
        
        // 获取未读消息数
        const unreadCount = await query(
          'SELECT COUNT(*) as count FROM chat_messages WHERE room_id = ? AND receiver_id = ? AND is_read = 0',
          [room.room_id, userId]
        );
        
        return {
          room_id: room.room_id,
          last_message: {
            id: lastMessage.id,
            content: lastMessage.content,
            message_type: lastMessage.message_type,
            created_at: lastMessage.created_at,
            is_read: !!lastMessage.is_read
          },
          other_user: otherUsers[0] || { id: otherUserId, name: `用户${otherUserId}`, role: 'user' },
          unread_count: parseInt(unreadCount[0]?.count || '0')
        };
      })
    );

    res.json({
      success: true,
      data: { rooms: roomDetails.filter(r => r !== null) }
    });
  } catch (error) {
    console.error('获取聊天室列表失败:', error);
    res.status(500).json({ success: false, error: '获取聊天室列表失败' });
  }
});

// 获取聊天消息
router.get('/messages/:roomId', authenticate, async (req, res) => {
  try {
    const { roomId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, error: '未登录' });
    }

    // 获取消息总数
    const totalCount = await query(
      'SELECT COUNT(*) as count FROM chat_messages WHERE room_id = ?',
      [roomId]
    );

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const messages = await query(
      'SELECT * FROM chat_messages WHERE room_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
      [roomId, parseInt(limit), offset]
    );

    // 标记为已读
    await query(
      'UPDATE chat_messages SET is_read = 1, read_at = NOW() WHERE room_id = ? AND receiver_id = ? AND is_read = 0',
      [roomId, userId]
    );

    res.json({
      success: true,
      data: {
        messages: messages.reverse(),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: parseInt(totalCount[0]?.count || '0'),
          total_pages: Math.ceil(parseInt(totalCount[0]?.count || '0') / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('获取聊天消息失败:', error);
    res.status(500).json({ success: false, error: '获取聊天消息失败' });
  }
});

// 发送消息
router.post('/messages', authenticate, async (req, res) => {
  try {
    const { room_id, receiver_id, content, message_type = 'text', order_id } = req.body;
    const sender_id = req.user?.id;
    
    if (!sender_id) return res.status(401).json({ success: false, error: '未登录' });
    if (!room_id || !receiver_id || !content) {
      return res.status(400).json({ success: false, error: '缺少必要参数' });
    }

    const result = await query(
      'INSERT INTO chat_messages (id, room_id, sender_id, receiver_id, content, message_type, order_id, created_at) VALUES (UUID(), ?, ?, ?, ?, ?, ?, NOW())',
      [room_id, sender_id, receiver_id, content, message_type, order_id || null]
    );

    const newMessages = await query(
      'SELECT * FROM chat_messages WHERE id = ?',
      [result.insertId]
    );

    res.json({ success: true, data: { message: newMessages[0] } });
  } catch (error) {
    console.error('发送消息失败:', error);
    res.status(500).json({ success: false, error: '发送消息失败' });
  }
});

// 创建或获取聊天室
router.post('/rooms', authenticate, async (req, res) => {
  try {
    const { other_user_id, order_id } = req.body;
    const current_user_id = req.user?.id;
    
    if (!current_user_id) return res.status(401).json({ success: false, error: '未登录' });
    if (!other_user_id) return res.status(400).json({ success: false, error: '缺少对方用户ID' });

    const otherUsers = await query('SELECT id, name, avatar_url as avatar, role FROM users WHERE id = ?', [other_user_id]);
    if (!otherUsers.length) return res.status(404).json({ success: false, error: '对方用户不存在' });

    const roomId = [current_user_id, other_user_id].sort().join('_');

    const existing = await query('SELECT id FROM chat_messages WHERE room_id = ? LIMIT 1', [roomId]);
    if (!existing.length) {
      await query(
        'INSERT INTO chat_messages (id, room_id, sender_id, receiver_id, content, message_type, order_id, created_at) VALUES (UUID(), ?, ?, ?, ?, ?, ?, NOW())',
        [roomId, current_user_id, other_user_id, '您好，开始聊天吧！', 'text', order_id || null]
      );
    }

    res.json({
      success: true,
      data: {
        room_id: roomId,
        other_user: otherUsers[0],
        order_id: order_id || null
      }
    });
  } catch (error) {
    console.error('创建聊天室失败:', error);
    res.status(500).json({ success: false, error: '创建聊天室失败' });
  }
});

// 标记消息已读
router.put('/messages/:messageId/read', authenticate, async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ success: false, error: '未登录' });

    await query('UPDATE chat_messages SET is_read = 1, read_at = NOW() WHERE id = ? AND receiver_id = ?', [messageId, userId]);
    res.json({ success: true, data: { message_id: messageId, is_read: true } });
  } catch (error) {
    res.status(500).json({ success: false, error: '标记已读失败' });
  }
});

// 未读消息数
router.get('/unread/count', authenticate, async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.json({ success: true, data: { unread_count: 0 } });

    const result = await query('SELECT COUNT(*) as count FROM chat_messages WHERE receiver_id = ? AND is_read = 0', [userId]);
    res.json({ success: true, data: { unread_count: parseInt(result[0]?.count || '0') } });
  } catch (error) {
    res.status(500).json({ success: false, error: '获取未读数失败' });
  }
});

module.exports = router;
