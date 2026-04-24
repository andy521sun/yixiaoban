/**
 * 医小伴陪诊APP - 实时通信API路由
 */

const express = require('express');
const router = express.Router();
const auth = require('../auth');
const { query, transaction } = require('../db');

/**
 * @api {get} /api/realtime/chat/history 获取聊天历史
 * @apiName GetChatHistory
 * @apiGroup Realtime
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} otherUserId 对方用户ID
 * @apiParam {String} [orderId] 订单ID（可选）
 * @apiParam {Number} [limit=50] 每页数量
 * @apiParam {Number} [page=1] 页码
 */
router.get('/chat/history', auth.authenticateToken, async (req, res) => {
    try {
        const { otherUserId, orderId, limit = 50, page = 1 } = req.query;
        const offset = (page - 1) * limit;
        
        if (!otherUserId) {
            return res.status(400).json({
                success: false,
                message: '缺少对方用户ID'
            });
        }

        // 构建查询条件
        let whereClause = `
            WHERE ((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?))
        `;
        const queryParams = [req.user.id, otherUserId, otherUserId, req.user.id];
        
        if (orderId) {
            whereClause += ' AND order_id = ?';
            queryParams.push(orderId);
        }

        // 获取聊天记录
        const messages = await query(`
            SELECT 
                cm.*,
                u1.name as sender_name,
                u2.name as receiver_name
            FROM chat_messages cm
            LEFT JOIN users u1 ON cm.sender_id = u1.id
            LEFT JOIN users u2 ON cm.receiver_id = u2.id
            ${whereClause}
            ORDER BY cm.created_at DESC
            LIMIT ? OFFSET ?
        `, [...queryParams, parseInt(limit), offset]);

        // 获取总数
        const countResult = await query(`
            SELECT COUNT(*) as total FROM chat_messages ${whereClause}
        `, queryParams);
        
        const total = countResult[0]?.total || 0;

        // 标记已读
        if (messages.length > 0) {
            await query(`
                UPDATE chat_messages 
                SET status = 'read', 
                    read_at = NOW(),
                    updated_at = NOW()
                WHERE receiver_id = ? AND sender_id = ? AND status != 'read'
            `, [req.user.id, otherUserId]);
        }

        res.json({
            success: true,
            data: {
                messages: messages.reverse(), // 按时间正序返回
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('获取聊天历史失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/realtime/chat/conversations 获取对话列表
 * @apiName GetConversations
 * @apiGroup Realtime
 * @apiHeader {String} Authorization Bearer token
 */
router.get('/chat/conversations', auth.authenticateToken, async (req, res) => {
    try {
        // 获取所有对话
        const conversations = await query(`
            SELECT 
                DISTINCT 
                CASE 
                    WHEN sender_id = ? THEN receiver_id
                    ELSE sender_id
                END as other_user_id,
                u.name as other_user_name,
                u.role as other_user_role,
                MAX(cm.created_at) as last_message_time,
                COUNT(CASE WHEN receiver_id = ? AND status != 'read' THEN 1 END) as unread_count,
                SUBSTRING_INDEX(GROUP_CONCAT(cm.content ORDER BY cm.created_at DESC SEPARATOR '||'), '||', 1) as last_message
            FROM chat_messages cm
            LEFT JOIN users u ON (
                CASE 
                    WHEN cm.sender_id = ? THEN cm.receiver_id
                    ELSE cm.sender_id
                END = u.id
            )
            WHERE sender_id = ? OR receiver_id = ?
            GROUP BY other_user_id, u.name, u.role
            ORDER BY last_message_time DESC
        `, [
            req.user.id, req.user.id, 
            req.user.id, req.user.id, req.user.id
        ]);

        // 获取每个对话的订单信息
        const conversationsWithOrders = await Promise.all(
            conversations.map(async (conv) => {
                // 获取与对方的订单
                const orders = await query(`
                    SELECT o.*, h.name as hospital_name
                    FROM orders o
                    LEFT JOIN hospitals h ON o.hospital_id = h.id
                    WHERE (o.patient_id = ? AND o.companion_id = ?)
                       OR (o.patient_id = ? AND o.companion_id = ?)
                    ORDER BY o.created_at DESC
                    LIMIT 3
                `, [
                    req.user.id, conv.other_user_id,
                    conv.other_user_id, req.user.id
                ]);
                
                return {
                    ...conv,
                    orders
                };
            })
        );

        res.json({
            success: true,
            data: conversationsWithOrders
        });
    } catch (error) {
        console.error('获取对话列表失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {post} /api/realtime/chat/send 发送消息（HTTP备用）
 * @apiName SendMessage
 * @apiGroup Realtime
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} receiver_id 接收者ID
 * @apiParam {String} content 消息内容
 * @apiParam {String} [order_id] 订单ID
 * @apiParam {String} [message_type=text] 消息类型
 */
router.post('/chat/send', auth.authenticateToken, async (req, res) => {
    try {
        const { receiver_id, content, order_id = null, message_type = 'text' } = req.body;
        
        if (!receiver_id || !content) {
            return res.status(400).json({
                success: false,
                message: '缺少必要参数'
            });
        }

        // 验证接收者
        const receivers = await query('SELECT id FROM users WHERE id = ?', [receiver_id]);
        if (receivers.length === 0) {
            return res.status(404).json({
                success: false,
                message: '接收者不存在'
            });
        }

        // 生成消息ID
        const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        
        // 保存消息
        await query(`
            INSERT INTO chat_messages (
                id, sender_id, receiver_id, order_id, content, message_type, status
            ) VALUES (?, ?, ?, ?, ?, ?, 'sent')
        `, [messageId, req.user.id, receiver_id, order_id, content, message_type]);

        // 获取消息详情
        const messages = await query(`
            SELECT 
                cm.*,
                u1.name as sender_name,
                u2.name as receiver_name
            FROM chat_messages cm
            LEFT JOIN users u1 ON cm.sender_id = u1.id
            LEFT JOIN users u2 ON cm.receiver_id = u2.id
            WHERE cm.id = ?
        `, [messageId]);

        res.json({
            success: true,
            message: '消息发送成功',
            data: messages[0]
        });
    } catch (error) {
        console.error('发送消息失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {post} /api/realtime/chat/mark-read 标记消息已读
 * @apiName MarkMessagesRead
 * @apiGroup Realtime
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} sender_id 发送者ID
 * @apiParam {String} [message_id] 特定消息ID（可选）
 */
router.post('/chat/mark-read', auth.authenticateToken, async (req, res) => {
    try {
        const { sender_id, message_id } = req.body;
        
        if (!sender_id) {
            return res.status(400).json({
                success: false,
                message: '缺少发送者ID'
            });
        }

        let updateQuery;
        let queryParams;
        
        if (message_id) {
            // 标记特定消息已读
            updateQuery = `
                UPDATE chat_messages 
                SET status = 'read', 
                    read_at = NOW(),
                    updated_at = NOW()
                WHERE id = ? AND receiver_id = ? AND sender_id = ?
            `;
            queryParams = [message_id, req.user.id, sender_id];
        } else {
            // 标记所有来自该发送者的消息已读
            updateQuery = `
                UPDATE chat_messages 
                SET status = 'read', 
                    read_at = NOW(),
                    updated_at = NOW()
                WHERE receiver_id = ? AND sender_id = ? AND status != 'read'
            `;
            queryParams = [req.user.id, sender_id];
        }

        const result = await query(updateQuery, queryParams);
        
        res.json({
            success: true,
            message: '消息已标记为已读',
            data: {
                affected_rows: result.affectedRows
            }
        });
    } catch (error) {
        console.error('标记消息已读失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/realtime/calls/history 获取通话记录
 * @apiName GetCallHistory
 * @apiGroup Realtime
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} [otherUserId] 对方用户ID（可选）
 * @apiParam {String} [orderId] 订单ID（可选）
 * @apiParam {Number} [limit=20] 每页数量
 * @apiParam {Number} [page=1] 页码
 */
router.get('/calls/history', auth.authenticateToken, async (req, res) => {
    try {
        const { otherUserId, orderId, limit = 20, page = 1 } = req.query;
        const offset = (page - 1) * limit;
        
        // 构建查询条件
        let whereClause = 'WHERE (caller_id = ? OR receiver_id = ?)';
        const queryParams = [req.user.id, req.user.id];
        
        if (otherUserId) {
            whereClause += ' AND (caller_id = ? OR receiver_id = ?)';
            queryParams.push(otherUserId, otherUserId);
        }
        
        if (orderId) {
            whereClause += ' AND order_id = ?';
            queryParams.push(orderId);
        }

        // 获取通话记录
        const calls = await query(`
            SELECT 
                cr.*,
                u1.name as caller_name,
                u2.name as receiver_name,
                o.service_type as order_service_type
            FROM call_records cr
            LEFT JOIN users u1 ON cr.caller_id = u1.id
            LEFT JOIN users u2 ON cr.receiver_id = u2.id
            LEFT JOIN orders o ON cr.order_id = o.id
            ${whereClause}
            ORDER BY cr.created_at DESC
            LIMIT ? OFFSET ?
        `, [...queryParams, parseInt(limit), offset]);

        // 获取总数
        const countResult = await query(`
            SELECT COUNT(*) as total FROM call_records ${whereClause}
        `, queryParams);
        
        const total = countResult[0]?.total || 0;

        res.json({
            success: true,
            data: {
                calls,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('获取通话记录失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/realtime/notifications 获取系统通知
 * @apiName GetNotifications
 * @apiGroup Realtime
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {Boolean} [unread_only=false] 只获取未读通知
 * @apiParam {Number} [limit=20] 每页数量
 * @apiParam {Number} [page=1] 页码
 */
router.get('/notifications', auth.authenticateToken, async (req, res) => {
    try {
        const { unread_only = false, limit = 20, page = 1 } = req.query;
        const offset = (page - 1) * limit;
        
        // 构建查询条件
        let whereClause = 'WHERE user_id = ?';
        const queryParams = [req.user.id];
        
        if (unread_only === 'true') {
            whereClause += ' AND is_read = FALSE';
        }

        // 获取通知
        const notifications = await query(`
            SELECT * FROM system_notifications
            ${whereClause}
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
        `, [...queryParams, parseInt(limit), offset]);

        // 获取总数
        const countResult = await query(`
            SELECT COUNT(*) as total FROM system_notifications ${whereClause}
        `, queryParams);
        
        const total = countResult[0]?.total || 0;

        res.json({
            success: true,
            data: {
                notifications,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('获取通知失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {post} /api/realtime/notifications/mark-read 标记通知已读
 * @apiName MarkNotificationsRead
 * @apiGroup Realtime
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} [notification_id] 特定通知ID（可选，不传则标记所有）
 */
router.post('/notifications/mark-read', auth.authenticateToken, async (req, res) => {
    try {
        const { notification_id } = req.body;
        
        let updateQuery;
        let queryParams;
        
        if (notification_id) {
            // 标记特定通知已读
            updateQuery = `
                UPDATE system_notifications 
                SET is_read = TRUE, 
                    read_at = NOW(),
                    updated_at = NOW()
                WHERE id = ? AND user_id = ?
            `;
            queryParams = [notification_id, req.user.id];
        } else {
            // 标记所有通知已读
            updateQuery = `
                UPDATE system_notifications 
                SET is_read = TRUE, 
                    read_at = NOW(),
                    updated_at = NOW()
                WHERE user_id = ? AND is_read = FALSE
            `;
            queryParams = [req.user.id];
        }

        const result = await query(updateQuery, queryParams);
        
        res.json({
            success: true,
            message: notification_id ? '通知已标记为已读' : '所有通知已标记为已读',
            data: {
                affected_rows: result.affectedRows
            }
        });
    } catch (error) {
        console.error('标记通知已读失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/realtime/online-users 获取在线用户列表
 * @apiName GetOnlineUsers
 * @apiGroup Realtime
 * @apiHeader {String} Authorization Bearer token
 */
router.get('/online-users', auth.authenticateToken, async (req, res) => {
    try {
        // 获取在线用户（这里简化处理，实际应该从WebSocket服务器获取）
        const onlineUsers = await query(`
            SELECT 
                u.id, u.name, u.role, u.avatar_url,
                os.status, os.last_active_at, os.device_type
            FROM users u
            LEFT JOIN online_status os ON u.id = os.user_id
            WHERE os.status = 'online' 
                AND os.last_active_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE)
            ORDER BY os.last_active_at DESC
        `);

        // 获取用户总数
        const totalUsers = await query('SELECT COUNT(*) as count FROM users');
        
        res.json({
            success: true,
            data: {
                online_users: onlineUsers,
                total_users: totalUsers[0]?.count || 0,
                online_count: onlineUsers.length
            }
        });
    } catch (error) {
        console.error('获取在线用户失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {post} /api/realtime/chat/recall 撤回消息
 * @apiName RecallMessage
 * @apiGroup Realtime
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} message_id 消息ID
 * @apiParam {String} [reason] 撤回原因
 */
router.post('/chat/recall', auth.authenticateToken, async (req, res) => {
    try {
        const { message_id, reason } = req.body;
        
        if (!message_id) {
            return res.status(400).json({
                success: false,
                message: '缺少消息ID'
            });
        }

        // 获取消息信息
        const messages = await query(`
            SELECT * FROM chat_messages WHERE id = ?
        `, [message_id]);
        
        if (messages.length === 0) {
            return res.status(404).json({
                success: false,
                message: '消息不存在'
            });
        }

        const message = messages[0];
        
        // 检查是否有权限撤回（只能撤回自己发送的消息）
        if (message.sender_id !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: '只能撤回自己发送的消息'
            });
        }

        // 检查消息是否已超过撤回时间（2分钟内）
        const messageTime = new Date(message.created_at);
        const now = new Date();
        const diffMinutes = (now - messageTime) / (1000 * 60);
        
        if (diffMinutes > 2) {
            return res.status(400).json({
                success: false,
                message: '消息已超过2分钟，无法撤回'
            });
        }

        // 记录撤回
        await query(`
            INSERT INTO message_recalls (message_id, user_id, recall_reason)
            VALUES (?, ?, ?)
        `, [message_id, req.user.id, reason || '用户撤回']);

        // 更新消息状态
        await query(`
            UPDATE chat_messages 
            SET status = 'recalled',
                updated_at = NOW()
            WHERE id = ?
        `, [message_id]);

        res.json({
            success: true,
            message: '消息已撤回'
        });
    } catch (error) {
        console.error('撤回消息失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {post} /api/realtime/status/update 更新在线状态
 * @apiName UpdateOnlineStatus
 * @apiGroup Realtime
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} status 状态: online, away, busy, offline
 * @apiParam {String} [device_type] 设备类型
 */
router.post('/status/update', auth.authenticateToken, async (req, res) => {
    try {
        const { status, device_type = 'web' } = req.body;
        
        if (!status) {
            return res.status(400).json({
                success: false,
                message: '缺少状态参数'
            });
        }

        const validStatuses = ['online', 'away', 'busy', 'offline'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                success: false,
                message: '无效的状态值'
            });
        }

        // 更新或插入在线状态
        await query(`
            INSERT INTO online_status (user_id, status, device_type, last_active_at)
            VALUES (?, ?, ?, NOW())
            ON DUPLICATE KEY UPDATE 
                status = VALUES(status),
                device_type = VALUES(device_type),
                last_active_at = NOW(),
                updated_at = NOW()
        `, [req.user.id, status, device_type]);

        res.json({
            success: true,
            message: '状态已更新',
            data: {
                user_id: req.user.id,
                status,
                device_type,
                updated_at: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('更新在线状态失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

module.exports = router;