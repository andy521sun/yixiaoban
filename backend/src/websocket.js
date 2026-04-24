/**
 * 医小伴陪诊APP - WebSocket实时通信服务器
 * 支持：在线聊天、订单通知、状态更新、系统消息
 */

const WebSocket = require('ws');
const jwt = require('jsonwebtoken');
const { query, transaction } = require('./db');

class WebSocketServer {
    constructor(server) {
        this.wss = new WebSocket.Server({ server, path: '/ws' });
        this.clients = new Map(); // userId -> WebSocket
        this.userSockets = new Map(); // userId -> Set of socketIds
        this.socketUsers = new Map(); // socketId -> userId
        
        this.setupEventHandlers();
        console.log('✅ WebSocket服务器已启动');
    }

    setupEventHandlers() {
        this.wss.on('connection', (ws, req) => {
            console.log('🔌 新的WebSocket连接建立');
            
            // 生成唯一的socket ID
            const socketId = this.generateSocketId();
            ws.socketId = socketId;
            
            // 解析URL获取token
            const token = this.extractTokenFromRequest(req);
            
            if (!token) {
                this.sendError(ws, '未提供认证令牌');
                ws.close();
                return;
            }

            // 验证JWT token
            try {
                const decoded = jwt.verify(token, process.env.JWT_SECRET);
                const userId = decoded.id;
                
                // 关联用户和socket
                this.associateUserSocket(userId, socketId, ws);
                
                // 发送连接成功消息
                this.sendMessage(ws, {
                    type: 'connection_established',
                    data: {
                        userId,
                        socketId,
                        timestamp: new Date().toISOString()
                    }
                });

                // 广播用户上线通知（给相关用户）
                this.broadcastUserStatus(userId, 'online');

                // 设置消息处理器
                ws.on('message', (data) => this.handleMessage(ws, userId, data));
                
                // 设置关闭处理器
                ws.on('close', () => this.handleDisconnect(socketId, userId));
                
                // 设置错误处理器
                ws.on('error', (error) => this.handleError(ws, error));

            } catch (error) {
                console.error('WebSocket认证失败:', error.message);
                this.sendError(ws, '认证失败: ' + error.message);
                ws.close();
            }
        });
    }

    /**
     * 生成唯一的socket ID
     */
    generateSocketId() {
        return `socket_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    /**
     * 从请求中提取token
     */
    extractTokenFromRequest(req) {
        // 从URL查询参数获取
        const url = new URL(req.url, `http://${req.headers.host}`);
        const tokenFromQuery = url.searchParams.get('token');
        
        if (tokenFromQuery) {
            return tokenFromQuery;
        }
        
        // 从Authorization头获取
        const authHeader = req.headers['authorization'];
        if (authHeader && authHeader.startsWith('Bearer ')) {
            return authHeader.substring(7);
        }
        
        return null;
    }

    /**
     * 关联用户和socket
     */
    associateUserSocket(userId, socketId, ws) {
        // 存储socket到用户映射
        if (!this.userSockets.has(userId)) {
            this.userSockets.set(userId, new Set());
        }
        this.userSockets.get(userId).add(socketId);
        
        // 存储用户到socket映射
        this.socketUsers.set(socketId, userId);
        
        // 存储WebSocket连接
        this.clients.set(socketId, ws);
        
        console.log(`👤 用户 ${userId} 连接，socketId: ${socketId}`);
    }

    /**
     * 处理接收到的消息
     */
    async handleMessage(ws, userId, data) {
        try {
            const message = JSON.parse(data.toString());
            console.log(`📨 收到消息 from ${userId}:`, message.type);
            
            switch (message.type) {
                case 'ping':
                    this.handlePing(ws, message);
                    break;
                    
                case 'chat_message':
                    await this.handleChatMessage(userId, message);
                    break;
                    
                case 'typing':
                    await this.handleTyping(userId, message);
                    break;
                    
                case 'read_receipt':
                    await this.handleReadReceipt(userId, message);
                    break;
                    
                case 'call_request':
                    await this.handleCallRequest(userId, message);
                    break;
                    
                case 'call_response':
                    await this.handleCallResponse(userId, message);
                    break;
                    
                default:
                    this.sendError(ws, `未知的消息类型: ${message.type}`);
            }
        } catch (error) {
            console.error('处理消息失败:', error);
            this.sendError(ws, '消息格式错误');
        }
    }

    /**
     * 处理ping消息（心跳）
     */
    handlePing(ws, message) {
        this.sendMessage(ws, {
            type: 'pong',
            data: {
                timestamp: new Date().toISOString(),
                server_time: Date.now()
            }
        });
    }

    /**
     * 处理聊天消息
     */
    async handleChatMessage(senderId, message) {
        const { receiverId, content, messageType = 'text', orderId = null } = message.data;
        
        if (!receiverId || !content) {
            throw new Error('缺少必要参数');
        }

        // 验证接收者是否存在
        const users = await query('SELECT id, name FROM users WHERE id = ?', [receiverId]);
        if (users.length === 0) {
            throw new Error('接收者不存在');
        }

        // 生成消息ID
        const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        
        // 保存到数据库
        await query(`
            INSERT INTO chat_messages (
                id, sender_id, receiver_id, order_id, content, message_type, status
            ) VALUES (?, ?, ?, ?, ?, ?, 'sent')
        `, [messageId, senderId, receiverId, orderId, content, messageType]);

        // 获取发送者信息
        const sender = await query('SELECT name FROM users WHERE id = ?', [senderId]);
        const senderName = sender[0]?.name || '未知用户';

        // 构建消息对象
        const chatMessage = {
            id: messageId,
            sender_id: senderId,
            sender_name: senderName,
            receiver_id: receiverId,
            order_id: orderId,
            content: content,
            message_type: messageType,
            timestamp: new Date().toISOString(),
            status: 'sent'
        };

        // 发送给接收者
        this.sendToUser(receiverId, {
            type: 'chat_message',
            data: chatMessage
        });

        // 发送回执给发送者
        this.sendToUser(senderId, {
            type: 'message_sent',
            data: {
                messageId,
                timestamp: new Date().toISOString()
            }
        });

        // 如果是订单相关消息，通知相关方
        if (orderId) {
            await this.notifyOrderParticipants(orderId, senderId, 'new_chat_message');
        }
    }

    /**
     * 处理输入状态
     */
    async handleTyping(senderId, message) {
        const { receiverId, orderId = null, isTyping } = message.data;
        
        if (!receiverId) {
            throw new Error('缺少接收者ID');
        }

        this.sendToUser(receiverId, {
            type: 'typing',
            data: {
                senderId,
                orderId,
                isTyping,
                timestamp: new Date().toISOString()
            }
        });
    }

    /**
     * 处理已读回执
     */
    async handleReadReceipt(userId, message) {
        const { messageId } = message.data;
        
        if (!messageId) {
            throw new Error('缺少消息ID');
        }

        // 更新数据库中的消息状态
        await query(`
            UPDATE chat_messages 
            SET status = 'read', 
                read_at = NOW(),
                updated_at = NOW()
            WHERE id = ? AND receiver_id = ?
        `, [messageId, userId]);

        // 获取消息信息
        const messages = await query(`
            SELECT sender_id FROM chat_messages WHERE id = ?
        `, [messageId]);
        
        if (messages.length > 0) {
            const senderId = messages[0].sender_id;
            
            // 通知发送者消息已读
            this.sendToUser(senderId, {
                type: 'message_read',
                data: {
                    messageId,
                    readerId: userId,
                    timestamp: new Date().toISOString()
                }
            });
        }
    }

    /**
     * 处理通话请求
     */
    async handleCallRequest(callerId, message) {
        const { receiverId, orderId = null, callType = 'audio' } = message.data;
        
        if (!receiverId) {
            throw new Error('缺少接收者ID');
        }

        // 获取呼叫者信息
        const caller = await query('SELECT name FROM users WHERE id = ?', [callerId]);
        const callerName = caller[0]?.name || '未知用户';

        // 生成通话ID
        const callId = `call_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        // 发送通话请求给接收者
        this.sendToUser(receiverId, {
            type: 'call_request',
            data: {
                callId,
                callerId,
                callerName,
                orderId,
                callType,
                timestamp: new Date().toISOString()
            }
        });

        // 保存通话记录
        await query(`
            INSERT INTO call_records (
                id, caller_id, receiver_id, order_id, call_type, status
            ) VALUES (?, ?, ?, ?, ?, 'requested')
        `, [callId, callerId, receiverId, orderId, callType]);
    }

    /**
     * 处理通话响应
     */
    async handleCallResponse(userId, message) {
        const { callId, accepted, reason = '' } = message.data;
        
        if (!callId) {
            throw new Error('缺少通话ID');
        }

        // 获取通话记录
        const calls = await query(`
            SELECT caller_id, receiver_id FROM call_records WHERE id = ?
        `, [callId]);
        
        if (calls.length === 0) {
            throw new Error('通话记录不存在');
        }

        const call = calls[0];
        const isCaller = call.caller_id === userId;
        const otherUserId = isCaller ? call.receiver_id : call.caller_id;

        // 更新通话状态
        const status = accepted ? 'accepted' : 'rejected';
        await query(`
            UPDATE call_records 
            SET status = ?,
                ended_at = NOW(),
                updated_at = NOW()
            WHERE id = ?
        `, [status, callId]);

        // 通知对方
        this.sendToUser(otherUserId, {
            type: 'call_response',
            data: {
                callId,
                accepted,
                reason,
                timestamp: new Date().toISOString()
            }
        });

        // 如果接受通话，建立通话连接
        if (accepted) {
            // 生成房间ID
            const roomId = `room_${callId}`;
            
            // 通知双方加入房间
            this.sendToUser(userId, {
                type: 'call_established',
                data: {
                    callId,
                    roomId,
                    otherUserId,
                    timestamp: new Date().toISOString()
                }
            });
            
            this.sendToUser(otherUserId, {
                type: 'call_established',
                data: {
                    callId,
                    roomId,
                    otherUserId: userId,
                    timestamp: new Date().toISOString()
                }
            });
        }
    }

    /**
     * 处理连接断开
     */
    handleDisconnect(socketId, userId) {
        console.log(`🔌 连接断开: socketId=${socketId}, userId=${userId}`);
        
        // 清理映射关系
        if (this.socketUsers.has(socketId)) {
            this.socketUsers.delete(socketId);
        }
        
        if (this.userSockets.has(userId)) {
            const sockets = this.userSockets.get(userId);
            sockets.delete(socketId);
            
            // 如果用户没有其他连接，广播离线状态
            if (sockets.size === 0) {
                this.userSockets.delete(userId);
                this.broadcastUserStatus(userId, 'offline');
            }
        }
        
        // 清理WebSocket连接
        if (this.clients.has(socketId)) {
            this.clients.delete(socketId);
        }
    }

    /**
     * 处理错误
     */
    handleError(ws, error) {
        console.error('WebSocket错误:', error);
        this.sendError(ws, '内部服务器错误');
    }

    /**
     * 发送消息给WebSocket客户端
     */
    sendMessage(ws, message) {
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify(message));
        }
    }

    /**
     * 发送错误消息
     */
    sendError(ws, errorMessage) {
        this.sendMessage(ws, {
            type: 'error',
            data: {
                message: errorMessage,
                timestamp: new Date().toISOString()
            }
        });
    }

    /**
     * 发送消息给指定用户的所有连接
     */
    sendToUser(userId, message) {
        if (this.userSockets.has(userId)) {
            const sockets = this.userSockets.get(userId);
            sockets.forEach(socketId => {
                const ws = this.clients.get(socketId);
                if (ws && ws.readyState === WebSocket.OPEN) {
                    this.sendMessage(ws, message);
                }
            });
        }
    }

    /**
     * 广播用户状态变化
     */
    broadcastUserStatus(userId, status) {
        // 获取用户信息
        query('SELECT name, role FROM users WHERE id = ?', [userId])
            .then(users => {
                if (users.length > 0) {
                    const user = users[0];
                    
                    // 广播给所有在线用户（实际应该只广播给相关用户）
                    this.broadcastToAll({
                        type: 'user_status',
                        data: {
                            userId,
                            userName: user.name,
                            userRole: user.role,
                            status,
                            timestamp: new Date().toISOString()
                        }
                    });
                }
            })
            .catch(error => {
                console.error('广播用户状态失败:', error);
            });
    }

    /**
     * 广播给所有连接的用户
     */
    broadcastToAll(message) {
        this.clients.forEach((ws, socketId) => {
            if (ws.readyState === WebSocket.OPEN) {
                this.sendMessage(ws, message);
            }
        });
    }

    /**
     * 通知订单相关参与者
     */
    async notifyOrderParticipants(orderId, excludeUserId, eventType) {
        // 获取订单信息
        const orders = await query(`
            SELECT patient_id, companion_id FROM orders WHERE id = ?
        `, [orderId]);
        
        if (orders.length > 0) {
            const order = orders[0];
            const participants = [order.patient_id, order.companion_id].filter(id => id && id !== excludeUserId);
            
            participants.forEach(userId => {
                this.sendToUser(userId, {
                    type: 'order_notification',
                    data: {
                        orderId,
                        eventType,
                        timestamp: new Date().toISOString()
                    }
                });
            });
        }
    }

    /**
     * 发送系统通知
     */
    sendSystemNotification(userId, title, content, notificationType = 'info') {
        const notificationId = `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        
        this.sendToUser(userId, {
            type: 'system_notification',
            data: {
                id: notificationId,
                title,
                content,
                type: notificationType,
                timestamp: new Date().toISOString(),
                read: false
            }
        });
    }

    /**
     * 检查用户是否在线
     */
    isUserOnline(userId) {
        return this.userSockets.has(userId) && this.userSockets.get(userId).size > 0;
    }

    /**
     * 获取在线用户列表
     */
    getOnlineUsers() {
        const onlineUsers = [];
        
        this.userSockets.forEach((sockets, userId) => {
            if (sockets.size > 0) {
                onlineUsers.push(userId);
            }
        });
        
        return onlineUsers;
    }

    /**
     * 获取用户连接数
     */
    getUserConnectionCount(userId) {
        if (this.userSockets.has(userId)) {
            return this.userSockets.get(userId).size;
        }
        return 0;
    }
}

module.exports = WebSocketServer;