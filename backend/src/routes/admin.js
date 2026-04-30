/**
 * 医小伴陪诊APP - 管理后台API路由
 * 仅管理员可访问
 */

const express = require('express');
const router = express.Router();
const auth = require('../auth');
const { query, execute } = require('../db');

// 管理员中间件 - 只允许管理员访问
const adminOnly = (req, res, next) => {
    if (req.user.role !== 'admin') {
        return res.status(403).json({
            success: false,
            message: '需要管理员权限'
        });
    }
    next();
};

// 所有管理后台路由都需要管理员权限
router.use(auth.authenticateToken, adminOnly);

/**
 * @api {get} /api/admin/dashboard/stats 获取仪表板统计数据
 * @apiName GetDashboardStats
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 */
router.get('/dashboard/stats', async (req, res) => {
    try {
        // 获取今日数据
        const today = new Date().toISOString().split('T')[0];
        
        // 用户统计
        const userStats = await query(`
            SELECT 
                COUNT(*) as total_users,
                SUM(CASE WHEN role = 'patient' THEN 1 ELSE 0 END) as total_patients,
                SUM(CASE WHEN role = 'companion' THEN 1 ELSE 0 END) as total_companions,
                SUM(CASE WHEN role = 'admin' THEN 1 ELSE 0 END) as total_admins,
                SUM(CASE WHEN DATE(created_at) = ? THEN 1 ELSE 0 END) as today_new_users
            FROM users
        `, [today]);

        // 订单统计
        const orderStats = await query(`
            SELECT 
                COUNT(*) as total_orders,
                SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_orders,
                SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END) as confirmed_orders,
                SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_orders,
                SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_orders,
                SUM(CASE WHEN DATE(created_at) = ? THEN 1 ELSE 0 END) as today_orders,
                SUM(total_amount) as total_revenue,
                SUM(CASE WHEN DATE(created_at) = ? THEN total_amount ELSE 0 END) as today_revenue
            FROM orders
        `, [today, today]);

        // 支付统计
        const paymentStats = await query(`
            SELECT 
                COUNT(*) as total_payments,
                SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END) as paid_payments,
                SUM(CASE WHEN payment_status = 'unpaid' THEN 1 ELSE 0 END) as unpaid_payments,
                SUM(CASE WHEN payment_status = 'refunded' THEN 1 ELSE 0 END) as refunded_payments,
                SUM(CASE WHEN DATE(created_at) = ? THEN 1 ELSE 0 END) as today_payments,
                SUM(amount) as total_payment_amount,
                SUM(CASE WHEN DATE(created_at) = ? AND payment_status = 'paid' THEN amount ELSE 0 END) as today_payment_amount
            FROM payments
        `, [today, today]);

        // 医院统计
        const hospitalStats = await query(`
            SELECT 
                COUNT(*) as total_hospitals,
                COUNT(DISTINCT city) as total_cities
            FROM hospitals
        `);

        // 最近7天订单趋势
        const orderTrend = await query(`
            SELECT 
                DATE(created_at) as date,
                COUNT(*) as order_count,
                SUM(total_amount) as revenue
            FROM orders
            WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
            GROUP BY DATE(created_at)
            ORDER BY date
        `);

        // 热门医院
        const popularHospitals = await query(`
            SELECT 
                h.id,
                h.name,
                h.city,
                COUNT(o.id) as order_count,
                SUM(o.total_amount) as total_revenue
            FROM hospitals h
            LEFT JOIN orders o ON h.id = o.hospital_id
            GROUP BY h.id, h.name, h.city
            ORDER BY order_count DESC
            LIMIT 10
        `);

        // 活跃陪诊师
        const activeCompanions = await query(`
            SELECT 
                u.id,
                u.name,
                u.phone,
                COUNT(o.id) as completed_orders,
                AVG(o.patient_rating) as avg_rating,
                SUM(o.total_amount) as total_earnings
            FROM users u
            LEFT JOIN orders o ON u.id = o.companion_id AND o.status = 'completed'
            WHERE u.role = 'companion'
            GROUP BY u.id, u.name, u.phone
            ORDER BY completed_orders DESC
            LIMIT 10
        `);

        res.json({
            success: true,
            data: {
                user_stats: userStats[0] || {},
                order_stats: orderStats[0] || {},
                payment_stats: paymentStats[0] || {},
                hospital_stats: hospitalStats[0] || {},
                order_trend: orderTrend,
                popular_hospitals: popularHospitals,
                active_companions: activeCompanions,
                updated_at: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('获取仪表板统计数据失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/admin/users 获取用户列表
 * @apiName GetUsers
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} [role] 角色过滤
 * @apiParam {String} [status] 状态过滤
 * @apiParam {String} [search] 搜索关键词（姓名/手机号）
 * @apiParam {Number} [limit=20] 每页数量
 * @apiParam {Number} [page=1] 页码
 */
router.get('/users', async (req, res) => {
    try {
        const { role, status, search, limit = 20, page = 1 } = req.query;
        const offset = (page - 1) * limit;
        
        // 构建查询条件
        let whereClause = 'WHERE 1=1';
        const queryParams = [];
        
        if (role) {
            whereClause += ' AND role = ?';
            queryParams.push(role);
        }
        
        if (status) {
            whereClause += ' AND status = ?';
            queryParams.push(status);
        }
        
        if (search) {
            whereClause += ' AND (name LIKE ? OR phone LIKE ?)';
            const searchTerm = `%${search}%`;
            queryParams.push(searchTerm, searchTerm);
        }

        // 获取用户列表
        const users = await query(`
            SELECT 
                u.*,
                w.balance,
                w.total_recharge,
                w.total_consumption
            FROM users u
            LEFT JOIN user_wallets w ON u.id = w.user_id
            ${whereClause}
            ORDER BY u.created_at DESC
            LIMIT ? OFFSET ?
        `, [...queryParams, parseInt(limit), offset]);

        // 获取总数
        const countResult = await query(`
            SELECT COUNT(*) as total FROM users ${whereClause}
        `, queryParams);
        
        const total = countResult[0]?.total || 0;

        // 获取用户订单统计
        const usersWithStats = await Promise.all(
            users.map(async (user) => {
                const stats = await query(`
                    SELECT 
                        COUNT(*) as total_orders,
                        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_orders,
                        SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_orders,
                        SUM(total_amount) as total_spent
                    FROM orders
                    WHERE patient_id = ?
                `, [user.id]);
                
                return {
                    ...user,
                    order_stats: stats[0] || {}
                };
            })
        );

        res.json({
            success: true,
            data: {
                users: usersWithStats,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('获取用户列表失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/admin/users/:id 获取用户详情
 * @apiName GetUserDetail
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 */
router.get('/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        // 获取用户基本信息
        const users = await query(`
            SELECT 
                u.*,
                w.balance,
                w.total_recharge,
                w.total_consumption,
                w.frozen_amount,
                w.last_transaction_at
            FROM users u
            LEFT JOIN user_wallets w ON u.id = w.user_id
            WHERE u.id = ?
        `, [id]);
        
        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: '用户不存在'
            });
        }

        const user = users[0];

        // 获取用户订单
        const orders = await query(`
            SELECT 
                o.*,
                h.name as hospital_name,
                c.name as companion_name
            FROM orders o
            LEFT JOIN hospitals h ON o.hospital_id = h.id
            LEFT JOIN users c ON o.companion_id = c.id
            WHERE o.patient_id = ?
            ORDER BY o.created_at DESC
            LIMIT 20
        `, [id]);

        // 获取用户支付记录
        const payments = await query(`
            SELECT 
                p.*,
                o.service_type
            FROM payments p
            LEFT JOIN orders o ON p.order_id = o.id
            WHERE p.user_id = ?
            ORDER BY p.created_at DESC
            LIMIT 20
        `, [id]);

        // 获取用户聊天统计
        const chatStats = await query(`
            SELECT 
                COUNT(*) as total_messages,
                SUM(CASE WHEN sender_id = ? THEN 1 ELSE 0 END) as sent_messages,
                SUM(CASE WHEN receiver_id = ? THEN 1 ELSE 0 END) as received_messages
            FROM chat_messages
            WHERE sender_id = ? OR receiver_id = ?
        `, [id, id, id, id]);

        res.json({
            success: true,
            data: {
                user,
                orders,
                payments,
                chat_stats: chatStats[0] || {}
            }
        });
    } catch (error) {
        console.error('获取用户详情失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {put} /api/admin/users/:id 更新用户信息
 * @apiName UpdateUser
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} [name] 姓名
 * @apiParam {String} [phone] 手机号
 * @apiParam {String} [role] 角色
 * @apiParam {String} [status] 状态
 * @apiParam {String} [avatar_url] 头像URL
 */
router.put('/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, phone, role, status, avatar_url } = req.body;
        
        // 检查用户是否存在
        const users = await query('SELECT id FROM users WHERE id = ?', [id]);
        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: '用户不存在'
            });
        }

        // 构建更新字段
        const updates = [];
        const updateParams = [];
        
        if (name !== undefined) {
            updates.push('name = ?');
            updateParams.push(name);
        }
        
        if (phone !== undefined) {
            // 检查手机号是否已存在
            const existingPhone = await query(
                'SELECT id FROM users WHERE phone = ? AND id != ?',
                [phone, id]
            );
            
            if (existingPhone.length > 0) {
                return res.status(400).json({
                    success: false,
                    message: '手机号已存在'
                });
            }
            
            updates.push('phone = ?');
            updateParams.push(phone);
        }
        
        if (role !== undefined) {
            const validRoles = ['patient', 'companion', 'admin'];
            if (!validRoles.includes(role)) {
                return res.status(400).json({
                    success: false,
                    message: '无效的角色'
                });
            }
            updates.push('role = ?');
            updateParams.push(role);
        }
        
        if (status !== undefined) {
            const validStatuses = ['active', 'inactive', 'suspended'];
            if (!validStatuses.includes(status)) {
                return res.status(400).json({
                    success: false,
                    message: '无效的状态'
                });
            }
            updates.push('status = ?');
            updateParams.push(status);
        }
        
        if (avatar_url !== undefined) {
            updates.push('avatar_url = ?');
            updateParams.push(avatar_url);
        }
        
        if (updates.length === 0) {
            return res.status(400).json({
                success: false,
                message: '没有提供更新字段'
            });
        }
        
        updateParams.push(id);
        
        // 执行更新
        await execute(`
            UPDATE users 
            SET ${updates.join(', ')}, updated_at = NOW()
            WHERE id = ?
        `, updateParams);
        
        // 获取更新后的用户信息
        const updatedUsers = await query('SELECT * FROM users WHERE id = ?', [id]);
        
        res.json({
            success: true,
            message: '用户信息更新成功',
            data: updatedUsers[0]
        });
    } catch (error) {
        console.error('更新用户信息失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {post} /api/admin/users/:id/wallet/adjust 调整用户钱包余额
 * @apiName AdjustUserWallet
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {Number} amount 调整金额（正数为增加，负数为减少）
 * @apiParam {String} reason 调整原因
 * @apiParam {String} [note] 备注
 */
router.post('/users/:id/wallet/adjust', async (req, res) => {
    try {
        const { id } = req.params;
        const { amount, reason, note } = req.body;
        
        if (!amount || !reason) {
            return res.status(400).json({
                success: false,
                message: '缺少必要参数'
            });
        }
        
        const adjustmentAmount = parseFloat(amount);
        if (isNaN(adjustmentAmount) || adjustmentAmount === 0) {
            return res.status(400).json({
                success: false,
                message: '无效的调整金额'
            });
        }
        
        // 检查用户是否存在
        const users = await query('SELECT id, name FROM users WHERE id = ?', [id]);
        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: '用户不存在'
            });
        }
        
        const user = users[0];
        
        // 检查用户钱包
        const wallets = await query('SELECT * FROM user_wallets WHERE user_id = ?', [id]);
        if (wallets.length === 0) {
            return res.status(400).json({
                success: false,
                message: '用户钱包不存在'
            });
        }
        
        const wallet = wallets[0];
        
        // 检查余额是否足够（如果是减少）
        if (adjustmentAmount < 0 && wallet.balance + adjustmentAmount < 0) {
            return res.status(400).json({
                success: false,
                message: '余额不足'
            });
        }
        
        // 开始事务
        await execute('START TRANSACTION');
        
        try {
            // 更新钱包余额
            const updateField = adjustmentAmount > 0 ? 'total_recharge' : 'total_withdraw';
            const updateAmount = Math.abs(adjustmentAmount);
            
            await execute(`
                UPDATE user_wallets 
                SET balance = balance + ?,
                    ${updateField} = ${updateField} + ?,
                    last_transaction_at = NOW(),
                    updated_at = NOW()
                WHERE user_id = ?
            `, [adjustmentAmount, updateAmount, id]);
            
            // 获取更新后的钱包信息
            const updatedWallets = await query('SELECT * FROM user_wallets WHERE user_id = ?', [id]);
            const updatedWallet = updatedWallets[0];
            
            // 记录调整流水
            const transactionId = `adjust_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            
            await execute(`
                INSERT INTO wallet_transactions (
                    wallet_id, user_id, transaction_type, amount,
                    balance_before, balance_after, related_id, related_type,
                    description, status, admin_id
                ) VALUES (?, ?, 'adjustment', ?, ?, ?, ?, 'admin_adjustment', ?, 'completed', ?)
            `, [
                wallet.id,
                id,
                adjustmentAmount,
                wallet.balance,
                updatedWallet.balance,
                transactionId,
                `管理员调整 - ${reason}${note ? ' - ' + note : ''}`,
                req.user.id
            ]);
            
            // 记录操作日志
            await execute(`
                INSERT INTO operation_logs (
                    user_id, action, target_type, target_id, details, ip_address
                ) VALUES (?, ?, ?, ?, ?, ?)
            `, [
                req.user.id,
                'wallet_adjustment',
                'user',
                id,
                JSON.stringify({
                    user_name: user.name,
                    adjustment_amount: adjustmentAmount,
                    reason: reason,
                    note: note,
                    balance_before: wallet.balance,
                    balance_after: updatedWallet.balance
                }),
                req.ip || 'unknown'
            ]);
            
            await execute('COMMIT');
            
            res.json({
                success: true,
                message: `钱包调整成功，${adjustmentAmount > 0 ? '增加' : '减少'} ${Math.abs(adjustmentAmount)}元`,
                data: {
                    user_id: id,
                    user_name: user.name,
                    adjustment_amount: adjustmentAmount,
                    balance_before: wallet.balance,
                    balance_after: updatedWallet.balance,
                    transaction_id: transactionId
                }
            });
            
        } catch (error) {
            await execute('ROLLBACK');
            throw error;
        }
        
    } catch (error) {
        console.error('调整用户钱包失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/admin/orders 获取订单列表
 * @apiName GetOrders
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} [status] 状态过滤
 * @apiParam {String} [payment_status] 支付状态过滤
 * @apiParam {String} [patient_id] 患者ID过滤
 * @apiParam {String} [companion_id] 陪诊师ID过滤
 * @apiParam {String} [hospital_id] 医院ID过滤
 * @apiParam {String} [start_date] 开始日期
 * @apiParam {String} [end_date] 结束日期
 * @apiParam {Number} [limit=20] 每页数量
 * @apiParam {Number} [page=1] 页码
 */
router.get('/orders', async (req, res) => {
    try {
        const { 
            status, payment_status, patient_id, companion_id, hospital_id,
            start_date, end_date, limit = 20, page = 1 
        } = req.query;
        
        const offset = (page - 1) * limit;
        
        // 构建查询条件
        let whereClause = 'WHERE 1=1';
        const queryParams = [];
        
        if (status) {
            whereClause += ' AND o.status = ?';
            queryParams.push(status);
        }
        
        if (payment_status) {
            whereClause += ' AND o.payment_status = ?';
            queryParams.push(payment_status);
        }
        
        if (patient_id) {
            whereClause += ' AND o.patient_id = ?';
            queryParams.push(patient_id);
        }
        
        if (companion_id) {
            whereClause += ' AND o.companion_id = ?';
            queryParams.push(companion_id);
        }
        
        if (hospital_id) {
            whereClause += ' AND o.hospital_id = ?';
            queryParams.push(hospital_id);
        }
        
        if (start_date) {
            whereClause += ' AND DATE(o.created_at) >= ?';
            queryParams.push(start_date);
        }
        
        if (end_date) {
            whereClause += ' AND DATE(o.created_at) <= ?';
            queryParams.push(end_date);
        }

        // 获取订单列表
        const orders = await query(`
            SELECT 
                o.*,
                p.name as patient_name,
                p.phone as patient_phone,
                c.name as companion_name,
                c.phone as companion_phone,
                h.name as hospital_name,
                h.city as hospital_city
            FROM orders o
            LEFT JOIN users p ON o.patient_id = p.id
            LEFT JOIN users c ON o.companion_id = c.id
            LEFT JOIN hospitals h ON o.hospital_id = h.id
            ${whereClause}
            ORDER BY o.created_at DESC
            LIMIT ? OFFSET ?
        `, [...queryParams, parseInt(limit), offset]);

        // 获取总数
        const countResult = await query(`
            SELECT COUNT(*) as total FROM orders o ${whereClause}
        `, queryParams);
        
        const total = countResult[0]?.total || 0;

        res.json({
            success: true,
            data: {
                orders,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('获取订单列表失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/admin/orders/:id 获取订单详情
 * @apiName GetOrderDetail
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 */
router.get('/orders/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        // 获取订单基本信息
        const orders = await query(`
            SELECT 
                o.*,
                p.name as patient_name,
                p.phone as patient_phone,
                p.avatar_url as patient_avatar,
                c.name as companion_name,
                c.phone as companion_phone,
                c.avatar_url as companion_avatar,
                h.name as hospital_name,
                h.address as hospital_address,
                h.city as hospital_city,
                d.name as department_name
            FROM orders o
            LEFT JOIN users p ON o.patient_id = p.id
            LEFT JOIN users c ON o.companion_id = c.id
            LEFT JOIN hospitals h ON o.hospital_id = h.id
            LEFT JOIN departments d ON o.department_id = d.id
            WHERE o.id = ?
        `, [id]);
        
        if (orders.length === 0) {
            return res.status(404).json({
                success: false,
                message: '订单不存在'
            });
        }

        const order = orders[0];

        // 获取支付记录
        const payments = await query(`
            SELECT * FROM payments WHERE order_id = ? ORDER BY created_at DESC
        `, [id]);

        // 获取聊天记录
        const chatMessages = await query(`
            SELECT 
                cm.*,
                u.name as sender_name
            FROM chat_messages cm
            LEFT JOIN users u ON cm.sender_id = u.id
            WHERE cm.order_id = ?
            ORDER BY cm.created_at ASC
            LIMIT 50
        `, [id]);

        // 获取操作日志
        const operationLogs = await query(`
            SELECT 
                ol.*,
                u.name as operator_name
            FROM operation_logs ol
            LEFT JOIN users u ON ol.user_id = u.id
            WHERE ol.target_type = 'order' AND ol.target_id = ?
            ORDER BY ol.created_at DESC
            LIMIT 20
        `, [id]);

        res.json({
            success: true,
            data: {
                order,
                payments,
                chat_messages: chatMessages,
                operation_logs: operationLogs
            }
        });
    } catch (error) {
        console.error('获取订单详情失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {put} /api/admin/orders/:id/status 更新订单状态
 * @apiName UpdateOrderStatus
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} status 新状态
 * @apiParam {String} [reason] 状态变更原因
 */
router.put('/orders/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { status, reason } = req.body;
        
        if (!status) {
            return res.status(400).json({
                success: false,
                message: '缺少状态参数'
            });
        }
        
        const validStatuses = ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                success: false,
                message: '无效的状态值'
            });
        }
        
        // 检查订单是否存在
        const orders = await query('SELECT * FROM orders WHERE id = ?', [id]);
        if (orders.length === 0) {
            return res.status(404).json({
                success: false,
                message: '订单不存在'
            });
        }
        
        const order = orders[0];
        
        // 检查状态转换是否有效
        const validTransitions = {
            'pending': ['confirmed', 'cancelled'],
            'confirmed': ['in_progress', 'cancelled'],
            'in_progress': ['completed', 'cancelled'],
            'completed': [],
            'cancelled': []
        };
        
        if (!validTransitions[order.status]?.includes(status)) {
            return res.status(400).json({
                success: false,
                message: `无法从${order.status}状态转换为${status}状态`
            });
        }
        
        // 更新订单状态
        await execute(`
            UPDATE orders 
            SET status = ?, updated_at = NOW()
            WHERE id = ?
        `, [status, id]);
        
        // 记录操作日志
        await execute(`
            INSERT INTO operation_logs (
                user_id, action, target_type, target_id, details, ip_address
            ) VALUES (?, ?, ?, ?, ?, ?)
        `, [
            req.user.id,
            'update_order_status',
            'order',
            id,
            JSON.stringify({
                old_status: order.status,
                new_status: status,
                reason: reason || '管理员操作',
                order_id: id
            }),
            req.ip || 'unknown'
        ]);
        
        // 如果是取消订单且已支付，需要退款
        if (status === 'cancelled' && order.payment_status === 'paid') {
            // 这里可以触发自动退款逻辑
            // 暂时只记录日志
            await execute(`
                INSERT INTO operation_logs (
                    user_id, action, target_type, target_id, details, ip_address
                ) VALUES (?, ?, ?, ?, ?, ?)
            `, [
                req.user.id,
                'order_cancelled_refund_required',
                'order',
                id,
                JSON.stringify({
                    order_id: id,
                    total_amount: order.total_amount,
                    note: '订单取消，需要手动处理退款'
                }),
                req.ip || 'unknown'
            ]);
        }
        
        // 获取更新后的订单信息
        const updatedOrders = await query('SELECT * FROM orders WHERE id = ?', [id]);
        
        res.json({
            success: true,
            message: '订单状态更新成功',
            data: updatedOrders[0]
        });
        
    } catch (error) {
        console.error('更新订单状态失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {put} /api/admin/orders/:id/assign 分配陪诊师
 * @apiName AssignCompanion
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} companion_id 陪诊师ID
 */
router.put('/orders/:id/assign', async (req, res) => {
    try {
        const { id } = req.params;
        const { companion_id } = req.body;
        
        if (!companion_id) {
            return res.status(400).json({
                success: false,
                message: '缺少陪诊师ID'
            });
        }
        
        // 检查订单是否存在
        const orders = await query('SELECT * FROM orders WHERE id = ?', [id]);
        if (orders.length === 0) {
            return res.status(404).json({
                success: false,
                message: '订单不存在'
            });
        }
        
        const order = orders[0];
        
        // 检查陪诊师是否存在且角色正确
        const companions = await query(`
            SELECT id, name FROM users WHERE id = ? AND role = 'companion'
        `, [companion_id]);
        
        if (companions.length === 0) {
            return res.status(404).json({
                success: false,
                message: '陪诊师不存在或角色不正确'
            });
        }
        
        const companion = companions[0];
        
        // 检查陪诊师是否可用（这里可以添加更复杂的检查逻辑）
        const busyCheck = await query(`
            SELECT COUNT(*) as busy_count FROM orders 
            WHERE companion_id = ? AND status IN ('confirmed', 'in_progress')
            AND appointment_date = ? AND appointment_time = ?
        `, [companion_id, order.appointment_date, order.appointment_time]);
        
        if (busyCheck[0]?.busy_count > 0) {
            return res.status(400).json({
                success: false,
                message: '陪诊师在该时间段已有其他预约'
            });
        }
        
        // 更新订单陪诊师
        await execute(`
            UPDATE orders 
            SET companion_id = ?, updated_at = NOW()
            WHERE id = ?
        `, [companion_id, id]);
        
        // 记录操作日志
        await execute(`
            INSERT INTO operation_logs (
                user_id, action, target_type, target_id, details, ip_address
            ) VALUES (?, ?, ?, ?, ?, ?)
        `, [
            req.user.id,
            'assign_companion',
            'order',
            id,
            JSON.stringify({
                order_id: id,
                old_companion_id: order.companion_id,
                new_companion_id: companion_id,
                companion_name: companion.name
            }),
            req.ip || 'unknown'
        ]);
        
        // 发送系统通知给陪诊师
        await execute(`
            INSERT INTO system_notifications (
                id, user_id, title, content, notification_type, related_id, related_type
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        `, [
            `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            companion_id,
            '新订单分配',
            `您已被分配新的陪诊订单 #${id.substring(0, 8)}，请及时查看`,
            'order',
            id,
            'order_assignment'
        ]);
        
        // 获取更新后的订单信息
        const updatedOrders = await query('SELECT * FROM orders WHERE id = ?', [id]);
        
        res.json({
            success: true,
            message: '陪诊师分配成功',
            data: updatedOrders[0]
        });
        
    } catch (error) {
        console.error('分配陪诊师失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/admin/payments 获取支付记录
 * @apiName GetPayments
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} [payment_status] 支付状态过滤
 * @apiParam {String} [payment_method] 支付方式过滤
 * @apiParam {String} [user_id] 用户ID过滤
 * @apiParam {String} [start_date] 开始日期
 * @apiParam {String} [end_date] 结束日期
 * @apiParam {Number} [limit=20] 每页数量
 * @apiParam {Number} [page=1] 页码
 */
router.get('/payments', async (req, res) => {
    try {
        const { 
            payment_status, payment_method, user_id,
            start_date, end_date, limit = 20, page = 1 
        } = req.query;
        
        const offset = (page - 1) * limit;
        
        // 构建查询条件
        let whereClause = 'WHERE 1=1';
        const queryParams = [];
        
        if (payment_status) {
            whereClause += ' AND p.payment_status = ?';
            queryParams.push(payment_status);
        }
        
        if (payment_method) {
            whereClause += ' AND p.payment_method = ?';
            queryParams.push(payment_method);
        }
        
        if (user_id) {
            whereClause += ' AND p.user_id = ?';
            queryParams.push(user_id);
        }
        
        if (start_date) {
            whereClause += ' AND DATE(p.created_at) >= ?';
            queryParams.push(start_date);
        }
        
        if (end_date) {
            whereClause += ' AND DATE(p.created_at) <= ?';
            queryParams.push(end_date);
        }

        // 获取支付记录
        const payments = await query(`
            SELECT 
                p.*,
                u.name as user_name,
                u.phone as user_phone,
                o.service_type,
                o.total_amount as order_amount
            FROM payments p
            LEFT JOIN users u ON p.user_id = u.id
            LEFT JOIN orders o ON p.order_id = o.id
            ${whereClause}
            ORDER BY p.created_at DESC
            LIMIT ? OFFSET ?
        `, [...queryParams, parseInt(limit), offset]);

        // 获取总数
        const countResult = await query(`
            SELECT COUNT(*) as total FROM payments p ${whereClause}
        `, queryParams);
        
        const total = countResult[0]?.total || 0;

        // 计算统计信息
        const stats = await query(`
            SELECT 
                SUM(CASE WHEN payment_status = 'paid' THEN amount ELSE 0 END) as total_paid,
                SUM(CASE WHEN payment_status = 'refunded' THEN amount ELSE 0 END) as total_refunded,
                COUNT(CASE WHEN payment_status = 'paid' THEN 1 END) as paid_count,
                COUNT(CASE WHEN payment_status = 'unpaid' THEN 1 END) as unpaid_count,
                COUNT(CASE WHEN payment_status = 'refunded' THEN 1 END) as refunded_count
            FROM payments p ${whereClause}
        `, queryParams);

        res.json({
            success: true,
            data: {
                payments,
                stats: stats[0] || {},
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('获取支付记录失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {post} /api/admin/payments/:id/refund 处理退款
 * @apiName ProcessRefund
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {Number} refund_amount 退款金额
 * @apiParam {String} refund_reason 退款原因
 */
router.post('/payments/:id/refund', async (req, res) => {
    try {
        const { id } = req.params;
        const { refund_amount, refund_reason } = req.body;
        
        if (!refund_amount || !refund_reason) {
            return res.status(400).json({
                success: false,
                message: '缺少必要参数'
            });
        }
        
        const refundAmount = parseFloat(refund_amount);
        if (isNaN(refundAmount) || refundAmount <= 0) {
            return res.status(400).json({
                success: false,
                message: '无效的退款金额'
            });
        }
        
        // 获取支付记录
        const payments = await query(`
            SELECT p.*, u.name as user_name, o.total_amount as order_amount
            FROM payments p
            LEFT JOIN users u ON p.user_id = u.id
            LEFT JOIN orders o ON p.order_id = o.id
            WHERE p.id = ?
        `, [id]);
        
        if (payments.length === 0) {
            return res.status(404).json({
                success: false,
                message: '支付记录不存在'
            });
        }
        
        const payment = payments[0];
        
        // 检查支付状态
        if (payment.payment_status !== 'paid') {
            return res.status(400).json({
                success: false,
                message: '只有已支付的订单才能退款'
            });
        }
        
        // 检查退款金额是否超过支付金额
        if (refundAmount > payment.amount) {
            return res.status(400).json({
                success: false,
                message: `退款金额不能超过支付金额 ${payment.amount}元`
            });
        }
        
        // 检查是否已有退款记录
        const existingRefunds = await query(`
            SELECT SUM(refund_amount) as total_refunded 
            FROM refund_records 
            WHERE payment_id = ?
        `, [id]);
        
        const totalRefunded = existingRefunds[0]?.total_refunded || 0;
        const remainingAmount = payment.amount - totalRefunded;
        
        if (refundAmount > remainingAmount) {
            return res.status(400).json({
                success: false,
                message: `退款金额不能超过剩余可退金额 ${remainingAmount}元`
            });
        }
        
        // 开始事务
        await execute('START TRANSACTION');
        
        try {
            // 创建退款记录
            const refundId = `refund_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            
            await execute(`
                INSERT INTO refund_records (
                    id, payment_id, order_id, user_id, refund_amount, 
                    refund_reason, status, processed_by
                ) VALUES (?, ?, ?, ?, ?, ?, 'completed', ?)
            `, [
                refundId,
                id,
                payment.order_id,
                payment.user_id,
                refundAmount,
                refund_reason,
                req.user.id
            ]);
            
            // 如果是余额支付，退还到用户钱包
            if (payment.payment_method_code === 'balance') {
                await execute(`
                    UPDATE user_wallets 
                    SET balance = balance + ?,
                        total_withdraw = total_withdraw + ?,
                        last_transaction_at = NOW(),
                        updated_at = NOW()
                    WHERE user_id = ?
                `, [refundAmount, refundAmount, payment.user_id]);
                
                // 记录钱包交易
                const wallet = await query('SELECT * FROM user_wallets WHERE user_id = ?', [payment.user_id]);
                if (wallet.length > 0) {
                    await execute(`
                        INSERT INTO wallet_transactions (
                            wallet_id, user_id, transaction_type, amount,
                            balance_before, balance_after, related_id, related_type,
                            description, status
                        ) VALUES (?, ?, 'refund', ?, ?, ?, ?, 'refund', ?, 'completed')
                    `, [
                        wallet[0].id,
                        payment.user_id,
                        refundAmount,
                        wallet[0].balance,
                        wallet[0].balance + refundAmount,
                        refundId,
                        `订单退款 - ${refund_reason}`
                    ]);
                }
            }
            
            // 更新支付状态（如果是全额退款）
            const newTotalRefunded = totalRefunded + refundAmount;
            let newPaymentStatus = payment.payment_status;
            
            if (Math.abs(newTotalRefunded - payment.amount) < 0.01) { // 全额退款
                newPaymentStatus = 'refunded';
                
                await execute(`
                    UPDATE payments 
                    SET payment_status = 'refunded',
                        refunded_at = NOW(),
                        updated_at = NOW()
                    WHERE id = ?
                `, [id]);
                
                // 更新订单支付状态
                await execute(`
                    UPDATE orders 
                    SET payment_status = 'refunded',
                        updated_at = NOW()
                    WHERE id = ?
                `, [payment.order_id]);
            } else {
                // 部分退款，更新支付记录备注
                await execute(`
                    UPDATE payments 
                    SET refund_amount = ?,
                        updated_at = NOW()
                    WHERE id = ?
                `, [newTotalRefunded, id]);
            }
            
            // 记录操作日志
            await execute(`
                INSERT INTO operation_logs (
                    user_id, action, target_type, target_id, details, ip_address
                ) VALUES (?, ?, ?, ?, ?, ?)
            `, [
                req.user.id,
                'process_refund',
                'payment',
                id,
                JSON.stringify({
                    payment_id: id,
                    order_id: payment.order_id,
                    user_id: payment.user_id,
                    user_name: payment.user_name,
                    refund_amount: refundAmount,
                    refund_reason: refund_reason,
                    payment_amount: payment.amount,
                    total_refunded: newTotalRefunded
                }),
                req.ip || 'unknown'
            ]);
            
            // 发送系统通知给用户
            await execute(`
                INSERT INTO system_notifications (
                    id, user_id, title, content, notification_type, related_id, related_type
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            `, [
                `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                payment.user_id,
                '退款处理完成',
                `您的订单 #${payment.order_id?.substring(0, 8) || ''} 退款 ${refundAmount}元 已处理完成，原因：${refund_reason}`,
                'payment',
                id,
                'refund_completed'
            ]);
            
            await execute('COMMIT');
            
            res.json({
                success: true,
                message: '退款处理成功',
                data: {
                    refund_id: refundId,
                    payment_id: id,
                    order_id: payment.order_id,
                    refund_amount: refundAmount,
                    total_refunded: newTotalRefunded,
                    payment_status: newPaymentStatus
                }
            });
            
        } catch (error) {
            await execute('ROLLBACK');
            throw error;
        }
        
    } catch (error) {
        console.error('处理退款失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/admin/hospitals 获取医院列表
 * @apiName GetHospitals
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} [city] 城市过滤
 * @apiParam {String} [search] 搜索关键词
 * @apiParam {Number} [limit=20] 每页数量
 * @apiParam {Number} [page=1] 页码
 */
router.get('/hospitals', async (req, res) => {
    try {
        const { city, search, limit = 20, page = 1 } = req.query;
        const offset = (page - 1) * limit;
        
        // 构建查询条件
        let whereClause = 'WHERE 1=1';
        const queryParams = [];
        
        if (city) {
            whereClause += ' AND city = ?';
            queryParams.push(city);
        }
        
        if (search) {
            whereClause += ' AND (name LIKE ? OR address LIKE ?)';
            const searchTerm = `%${search}%`;
            queryParams.push(searchTerm, searchTerm);
        }

        // 获取医院列表
        const hospitals = await query(`
            SELECT 
                h.*,
                COUNT(DISTINCT d.id) as department_count,
                COUNT(o.id) as order_count,
                SUM(CASE WHEN o.status = 'completed' THEN o.total_amount ELSE 0 END) as total_revenue
            FROM hospitals h
            LEFT JOIN departments d ON h.id = d.hospital_id
            LEFT JOIN orders o ON h.id = o.hospital_id
            ${whereClause}
            GROUP BY h.id, h.name, h.city, h.address, h.phone, h.description, h.created_at, h.updated_at
            ORDER BY h.created_at DESC
            LIMIT ? OFFSET ?
        `, [...queryParams, parseInt(limit), offset]);

        // 获取总数
        const countResult = await query(`
            SELECT COUNT(DISTINCT h.id) as total 
            FROM hospitals h
            ${whereClause}
        `, queryParams);
        
        const total = countResult[0]?.total || 0;

        res.json({
            success: true,
            data: {
                hospitals,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('获取医院列表失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {post} /api/admin/hospitals 创建医院
 * @apiName CreateHospital
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} name 医院名称
 * @apiParam {String} city 城市
 * @apiParam {String} address 地址
 * @apiParam {String} phone 联系电话
 * @apiParam {String} [description] 描述
 */
router.post('/hospitals', async (req, res) => {
    try {
        const { name, city, address, phone, description } = req.body;
        
        if (!name || !city || !address || !phone) {
            return res.status(400).json({
                success: false,
                message: '缺少必要参数'
            });
        }
        
        // 生成医院ID
        const hospitalId = `hosp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        
        // 创建医院
        await execute(`
            INSERT INTO hospitals (id, name, city, address, phone, description)
            VALUES (?, ?, ?, ?, ?, ?)
        `, [hospitalId, name, city, address, phone, description || '']);
        
        // 记录操作日志
        await execute(`
            INSERT INTO operation_logs (
                user_id, action, target_type, target_id, details, ip_address
            ) VALUES (?, ?, ?, ?, ?, ?)
        `, [
            req.user.id,
            'create_hospital',
            'hospital',
            hospitalId,
            JSON.stringify({
                hospital_id: hospitalId,
                name: name,
                city: city,
                address: address,
                phone: phone
            }),
            req.ip || 'unknown'
        ]);
        
        // 获取创建的医院信息
        const hospitals = await query('SELECT * FROM hospitals WHERE id = ?', [hospitalId]);
        
        res.json({
            success: true,
            message: '医院创建成功',
            data: hospitals[0]
        });
        
    } catch (error) {
        console.error('创建医院失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {put} /api/admin/hospitals/:id 更新医院信息
 * @apiName UpdateHospital
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} [name] 医院名称
 * @apiParam {String} [city] 城市
 * @apiParam {String} [address] 地址
 * @apiParam {String} [phone] 联系电话
 * @apiParam {String} [description] 描述
 */
router.put('/hospitals/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, city, address, phone, description } = req.body;
        
        // 检查医院是否存在
        const hospitals = await query('SELECT * FROM hospitals WHERE id = ?', [id]);
        if (hospitals.length === 0) {
            return res.status(404).json({
                success: false,
                message: '医院不存在'
            });
        }
        
        const hospital = hospitals[0];
        
        // 构建更新字段
        const updates = [];
        const updateParams = [];
        
        if (name !== undefined) {
            updates.push('name = ?');
            updateParams.push(name);
        }
        
        if (city !== undefined) {
            updates.push('city = ?');
            updateParams.push(city);
        }
        
        if (address !== undefined) {
            updates.push('address = ?');
            updateParams.push(address);
        }
        
        if (phone !== undefined) {
            updates.push('phone = ?');
            updateParams.push(phone);
        }
        
        if (description !== undefined) {
            updates.push('description = ?');
            updateParams.push(description);
        }
        
        if (updates.length === 0) {
            return res.status(400).json({
                success: false,
                message: '没有提供更新字段'
            });
        }
        
        updateParams.push(id);
        
        // 执行更新
        await execute(`
            UPDATE hospitals 
            SET ${updates.join(', ')}, updated_at = NOW()
            WHERE id = ?
        `, updateParams);
        
        // 记录操作日志
        await execute(`
            INSERT INTO operation_logs (
                user_id, action, target_type, target_id, details, ip_address
            ) VALUES (?, ?, ?, ?, ?, ?)
        `, [
            req.user.id,
            'update_hospital',
            'hospital',
            id,
            JSON.stringify({
                hospital_id: id,
                old_data: hospital,
                new_data: { name, city, address, phone, description }
            }),
            req.ip || 'unknown'
        ]);
        
        // 获取更新后的医院信息
        const updatedHospitals = await query('SELECT * FROM hospitals WHERE id = ?', [id]);
        
        res.json({
            success: true,
            message: '医院信息更新成功',
            data: updatedHospitals[0]
        });
        
    } catch (error) {
        console.error('更新医院信息失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/admin/system/logs 获取系统日志
 * @apiName GetSystemLogs
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} [action] 操作类型过滤
 * @apiParam {String} [target_type] 目标类型过滤
 * @apiParam {String} [user_id] 操作员ID过滤
 * @apiParam {String} [start_date] 开始日期
 * @apiParam {String} [end_date] 结束日期
 * @apiParam {Number} [limit=50] 每页数量
 * @apiParam {Number} [page=1] 页码
 */
router.get('/system/logs', async (req, res) => {
    try {
        const { 
            action, target_type, user_id,
            start_date, end_date, limit = 50, page = 1 
        } = req.query;
        
        const offset = (page - 1) * limit;
        
        // 构建查询条件
        let whereClause = 'WHERE 1=1';
        const queryParams = [];
        
        if (action) {
            whereClause += ' AND ol.action = ?';
            queryParams.push(action);
        }
        
        if (target_type) {
            whereClause += ' AND ol.target_type = ?';
            queryParams.push(target_type);
        }
        
        if (user_id) {
            whereClause += ' AND ol.user_id = ?';
            queryParams.push(user_id);
        }
        
        if (start_date) {
            whereClause += ' AND DATE(ol.created_at) >= ?';
            queryParams.push(start_date);
        }
        
        if (end_date) {
            whereClause += ' AND DATE(ol.created_at) <= ?';
            queryParams.push(end_date);
        }

        // 获取系统日志
        const logs = await query(`
            SELECT 
                ol.*,
                u.name as operator_name
            FROM operation_logs ol
            LEFT JOIN users u ON ol.user_id = u.id
            ${whereClause}
            ORDER BY ol.created_at DESC
            LIMIT ? OFFSET ?
        `, [...queryParams, parseInt(limit), offset]);

        // 获取总数
        const countResult = await query(`
            SELECT COUNT(*) as total FROM operation_logs ol ${whereClause}
        `, queryParams);
        
        const total = countResult[0]?.total || 0;

        // 解析日志详情（JSON字符串转对象）
        const logsWithParsedDetails = logs.map(log => ({
            ...log,
            details: log.details ? JSON.parse(log.details) : null
        }));

        res.json({
            success: true,
            data: {
                logs: logsWithParsedDetails,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('获取系统日志失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {get} /api/admin/system/config 获取系统配置
 * @apiName GetSystemConfig
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 */
router.get('/system/config', async (req, res) => {
    try {
        // 获取系统配置
        const configs = await query(`
            SELECT * FROM system_configs 
            ORDER BY config_key
        `);

        // 按类别分组
        const groupedConfigs = {};
        configs.forEach(config => {
            const category = config.category || 'general';
            if (!groupedConfigs[category]) {
                groupedConfigs[category] = [];
            }
            groupedConfigs[category].push(config);
        });

        res.json({
            success: true,
            data: {
                configs: groupedConfigs,
                last_updated: configs.length > 0 ? 
                    new Date(Math.max(...configs.map(c => new Date(c.updated_at).getTime()))).toISOString() : 
                    null
            }
        });
    } catch (error) {
        console.error('获取系统配置失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/**
 * @api {put} /api/admin/system/config/:key 更新系统配置
 * @apiName UpdateSystemConfig
 * @apiGroup Admin
 * @apiHeader {String} Authorization Bearer token
 * 
 * @apiParam {String} config_value 配置值
 * @apiParam {String} [description] 配置描述
 */
router.put('/system/config/:key', async (req, res) => {
    try {
        const { key } = req.params;
        const { config_value, description } = req.body;
        
        if (config_value === undefined) {
            return res.status(400).json({
                success: false,
                message: '缺少配置值'
            });
        }
        
        // 检查配置是否存在
        const configs = await query('SELECT * FROM system_configs WHERE config_key = ?', [key]);
        
        if (configs.length === 0) {
            // 创建新配置
            await execute(`
                INSERT INTO system_configs (config_key, config_value, description)
                VALUES (?, ?, ?)
            `, [key, config_value, description || '']);
        } else {
            // 更新现有配置
            await execute(`
                UPDATE system_configs 
                SET config_value = ?, 
                    description = ?,
                    updated_at = NOW()
                WHERE config_key = ?
            `, [config_value, description || configs[0].description, key]);
        }
        
        // 记录操作日志
        await execute(`
            INSERT INTO operation_logs (
                user_id, action, target_type, target_id, details, ip_address
            ) VALUES (?, ?, ?, ?, ?, ?)
        `, [
            req.user.id,
            'update_system_config',
            'system_config',
            key,
            JSON.stringify({
                config_key: key,
                old_value: configs.length > 0 ? configs[0].config_value : null,
                new_value: config_value,
                description: description
            }),
            req.ip || 'unknown'
        ]);
        
        // 获取更新后的配置
        const updatedConfigs = await query('SELECT * FROM system_configs WHERE config_key = ?', [key]);
        
        res.json({
            success: true,
            message: '系统配置更新成功',
            data: updatedConfigs[0]
        });
        
    } catch (error) {
        console.error('更新系统配置失败:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============= 医生认证审核 =============

/**
 * GET /api/admin/doctors/certifications - 获取医生认证列表
 */
router.get('/doctors/certifications', async (req, res) => {
  try {
    const { status, page = 1, page_size = 20 } = req.query;
    const offset = (page - 1) * page_size;

    let sql = `
      SELECT dc.*, u.name as user_name, u.phone, u.avatar_url
      FROM doctor_certifications dc
      JOIN users u ON u.id = dc.user_id
    `;
    const params = [];
    const validStatuses = ['pending', 'approved', 'rejected'];
    if (status && validStatuses.includes(status)) {
      sql += ' WHERE dc.status = ?';
      params.push(status);
    }
    sql += ' ORDER BY dc.created_at DESC LIMIT ? OFFSET ?';
    params.push(Number(page_size), offset);

    const rows = await query(sql, params);
    const [{ total }] = await query(
      'SELECT COUNT(*) as total FROM doctor_certifications' +
      (status && validStatuses.includes(status) ? ' WHERE status = ?' : ''),
      status && validStatuses.includes(status) ? [status] : []
    );

    res.json({ success: true, data: rows, total, page: Number(page), page_size: Number(page_size) });
  } catch (error) {
    console.error('获取医生认证列表失败:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * POST /api/admin/doctors/certifications/:id/review - 审核医生认证
 */
router.post('/doctors/certifications/:id/review', async (req, res) => {
  try {
    const { action, reject_reason } = req.body; // action: 'approve' | 'reject'
    if (!['approve', 'reject'].includes(action)) {
      return res.status(400).json({ success: false, message: '操作类型无效' });
    }

    const certs = await query('SELECT * FROM doctor_certifications WHERE id = ?', [req.params.id]);
    if (certs.length === 0) return res.status(404).json({ success: false, message: '认证记录不存在' });
    if (certs[0].status !== 'pending') return res.status(400).json({ success: false, message: '该申请已处理' });

    const cert = certs[0];
    const newStatus = action === 'approve' ? 'approved' : 'rejected';

    await query(
      `UPDATE doctor_certifications SET status = ?, reject_reason = ?, reviewed_by = ?, reviewed_at = NOW() WHERE id = ?`,
      [newStatus, action === 'reject' ? (reject_reason || '') : null, req.user.id, req.params.id]
    );

    if (action === 'approve') {
      // 更新用户角色为 doctor，标记已认证
      await query(
        `UPDATE users SET role = 'doctor', is_verified = 1, 
         title = ?, department = ?, hospital_affiliation = ? WHERE id = ?`,
        [cert.title, cert.department, cert.hospital_name, cert.user_id]
      );
      // 插入默认服务价格
      await query(
        `INSERT INTO doctor_service_pricing (doctor_id, service_type, price) VALUES
         (?, 'text_consult', 50.00), (?, 'image_consult', 80.00), (?, 'video_consult', 150.00)
         ON DUPLICATE KEY UPDATE price = VALUES(price)`,
        [cert.user_id, cert.user_id, cert.user_id]
      );
    }

    res.json({ success: true, message: action === 'approve' ? '已通过认证' : '已驳回' });
  } catch (error) {
    console.error('审核医生认证失败:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
