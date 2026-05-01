/**
 * 医小伴 v2.0 - 问诊消息 API
 * 患者与医生之间的问诊消息收发
 */

const express = require('express');
const router = express.Router();
const { query, transaction } = require('../db');
const auth = require('../auth');

// 所有接口需要登录
router.use(auth.authenticateToken);

/**
 * POST /api/consultations/:id/messages - 发送消息
 */
router.post('/:id/messages', async (req, res) => {
  try {
    const { id } = req.params;
    const { msg_type, content, media_url, media_thumbnail, file_name, file_size } = req.body;

    // 验证问诊存在且用户有权限
    const [consult] = await query(
      'SELECT * FROM consultations WHERE id = ?',
      [id]
    );
    if (!consult) return res.status(404).json({ error: '问诊记录不存在' });

    // 检查权限：只有患者和医生可以发消息
    const userId = req.user.id;
    if (consult.patient_id !== userId && consult.doctor_id !== userId) {
      return res.status(403).json({ error: '无权限发送消息' });
    }

    // 判断发送者角色（兼容 companion 和 doctor）
    let sender_role;
    if (userId === consult.patient_id) sender_role = 'patient';
    else if (userId === consult.doctor_id) sender_role = 'doctor';

    // 检查问诊状态（等待/进行中/已完成都可以发，但已取消不行）
    if (consult.status === 'cancelled') {
      return res.status(400).json({ error: '问诊已取消，无法发送消息' });
    }

    // 如果问诊还在 waiting 状态，医生接诊时自动改为 accepted
    if (consult.status === 'waiting' && consult.doctor_id === userId) {
      await query(
        "UPDATE consultations SET status = 'accepted', started_at = NOW() WHERE id = ?",
        [id]
      );
    }

    // 自动将问诊状态改为 in_progress（当医生回复且状态为 accepted 时）
    if (consult.status === 'accepted' && consult.doctor_id === userId) {
      await query(
        "UPDATE consultations SET status = 'in_progress' WHERE id = ?",
        [id]
      );
    }

    // 插入消息
    const validMsgTypes = ['text', 'image', 'voice', 'file', 'system'];
    const type = validMsgTypes.includes(msg_type) ? msg_type : 'text';

    const result = await query(
      `INSERT INTO consultation_messages 
       (consultation_id, sender_id, sender_role, msg_type, content, media_url, media_thumbnail, file_name, file_size)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, userId, sender_role, type, content || '', media_url || null, media_thumbnail || null, file_name || null, file_size || null]
    );

    // 获取刚插入的消息 ID
    const [newMsg] = await query(
      'SELECT id FROM consultation_messages WHERE consultation_id = ? AND sender_id = ? ORDER BY created_at DESC LIMIT 1',
      [id, userId]
    );
    const messageId = newMsg ? newMsg.id : (result.insertId || '');

    // 构建返回消息
    const message = {
      id: messageId,
      consultation_id: id,
      sender_id: userId,
      sender_role,
      msg_type: type,
      content: content || '',
      media_url: media_url || null,
      media_thumbnail: media_thumbnail || null,
      file_name: file_name || null,
      file_size: file_size || null,
      is_read: 0,
      created_at: new Date().toISOString()
    };

    // 获取接收者 ID
    const receiverId = userId === consult.patient_id ? consult.doctor_id : consult.patient_id;

    // WebSocket 实时推送
    if (global.wss && typeof global.wss.sendToUser === 'function') {
      global.wss.sendToUser(receiverId, {
        type: 'consultation_message',
        data: message
      });
      global.wss.sendToUser(receiverId, {
        type: 'system_notification',
        data: {
          title: '新问诊消息',
          content: content ? content.substring(0, 50) : `[${type === 'image' ? '图片' : type === 'voice' ? '语音' : '文件'}]`,
          type: 'consultation',
          related_id: id,
          timestamp: new Date().toISOString()
        }
      });
    }

    // 保存通知到 system_notifications 表
    try {
      await query(
        `INSERT INTO system_notifications 
         (user_id, title, content, notification_type, related_id, is_read)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [
          receiverId,
          '新问诊消息',
          sender_role === 'patient' ? '患者发来新消息' : '医生回复了新消息',
          'consultation',
          id,
          0
        ]
      );
    } catch (e) {
      // 非关键错误
    }

    res.status(201).json({ message: '发送成功', data: message });
  } catch (error) {
    console.error('发送问诊消息失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/consultations/:id/messages - 获取问诊消息列表
 */
router.get('/:id/messages', async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, page_size = 50 } = req.query;
    const offset = (page - 1) * page_size;

    // 验证问诊存在且用户有权限
    const [consult] = await query('SELECT * FROM consultations WHERE id = ?', [id]);
    if (!consult) return res.status(404).json({ error: '问诊记录不存在' });

    const userId = req.user.id;
    if (consult.patient_id !== userId && consult.doctor_id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ error: '无权限查看' });
    }

    // 获取消息（早到晚）
    const messages = await query(
      `SELECT * FROM consultation_messages 
       WHERE consultation_id = ? 
       ORDER BY created_at ASC
       LIMIT ? OFFSET ?`,
      [id, Number(page_size), offset]
    );

    // 获取总数
    const [{ total }] = await query(
      'SELECT COUNT(*) as total FROM consultation_messages WHERE consultation_id = ?',
      [id]
    );

    // 将未读消息标记为已读（当前用户是接收者时）
    const unreadIds = messages
      .filter(m => m.sender_id !== userId && !m.is_read)
      .map(m => m.id);

    if (unreadIds.length > 0) {
      await query(
        `UPDATE consultation_messages SET is_read = 1, read_at = NOW() 
         WHERE id IN (${unreadIds.map(() => '?').join(',')})`,
        unreadIds
      );
    }

    res.json({ messages, total, page: Number(page), page_size: Number(page_size) });
  } catch (error) {
    console.error('获取问诊消息失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * POST /api/consultations/:id/messages/read - 标记全部已读
 */
router.post('/:id/messages/read', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    await query(
      `UPDATE consultation_messages SET is_read = 1, read_at = NOW()
       WHERE consultation_id = ? AND sender_id != ? AND is_read = 0`,
      [id, userId]
    );

    res.json({ message: '已标记为已读' });
  } catch (error) {
    console.error('标记已读失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/consultations/:id/messages/unread-count - 获取未读数
 */
router.get('/:id/messages/unread-count', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const [{ count }] = await query(
      'SELECT COUNT(*) as count FROM consultation_messages WHERE consultation_id = ? AND sender_id != ? AND is_read = 0',
      [id, userId]
    );

    res.json({ unread_count: count });
  } catch (error) {
    console.error('获取未读数失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

module.exports = router;
