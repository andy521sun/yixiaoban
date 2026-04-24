/**
 * 医小伴陪诊APP - 支付系统模块
 * 支持微信支付、支付宝、余额支付、现金支付
 */

const { query, transaction } = require('./db');

class PaymentSystem {
    /**
     * 获取可用支付方式
     */
    static async getAvailablePaymentMethods(userId = null) {
        try {
            const methods = await query(`
                SELECT id, name, code, description, icon_url, sort_order, config
                FROM payment_methods 
                WHERE is_active = TRUE
                ORDER BY sort_order ASC
            `);
            
            // 如果用户已登录，检查余额支付是否可用
            if (userId) {
                const wallet = await this.getUserWallet(userId);
                const methodsWithStatus = methods.map(method => {
                    if (method.code === 'balance') {
                        return {
                            ...method,
                            available: wallet.balance > 0,
                            balance: wallet.balance
                        };
                    }
                    return { ...method, available: true };
                });
                return methodsWithStatus;
            }
            
            return methods;
        } catch (error) {
            console.error('获取支付方式失败:', error);
            throw new Error('获取支付方式失败');
        }
    }

    /**
     * 获取用户钱包信息
     */
    static async getUserWallet(userId) {
        try {
            const wallets = await query(`
                SELECT * FROM user_wallets WHERE user_id = ?
            `, [userId]);
            
            if (wallets.length === 0) {
                // 如果钱包不存在，创建默认钱包
                return await this.createUserWallet(userId);
            }
            
            return wallets[0];
        } catch (error) {
            console.error('获取用户钱包失败:', error);
            throw new Error('获取用户钱包失败');
        }
    }

    /**
     * 创建用户钱包
     */
    static async createUserWallet(userId) {
        try {
            const result = await query(`
                INSERT INTO user_wallets (user_id, balance, total_recharge)
                VALUES (?, 0.00, 0.00)
            `, [userId]);
            
            return {
                id: result.insertId,
                user_id: userId,
                balance: 0.00,
                frozen_amount: 0.00,
                total_recharge: 0.00,
                total_withdraw: 0.00,
                total_consumption: 0.00
            };
        } catch (error) {
            console.error('创建用户钱包失败:', error);
            throw new Error('创建用户钱包失败');
        }
    }

    /**
     * 创建支付订单
     */
    static async createPayment(orderData) {
        const {
            order_id,
            user_id,
            amount,
            payment_method_code,
            description = '医小伴陪诊服务'
        } = orderData;

        try {
            // 验证支付方式
            const methods = await query(`
                SELECT * FROM payment_methods WHERE code = ? AND is_active = TRUE
            `, [payment_method_code]);
            
            if (methods.length === 0) {
                throw new Error('支付方式不可用');
            }

            // 验证订单
            const orders = await query(`
                SELECT * FROM orders WHERE id = ? AND patient_id = ?
            `, [order_id, user_id]);
            
            if (orders.length === 0) {
                throw new Error('订单不存在或无权访问');
            }

            const order = orders[0];
            
            // 检查订单是否已支付
            if (order.payment_status === 'paid') {
                throw new Error('订单已支付');
            }

            // 创建支付记录
            const paymentId = `pay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            const tradeNo = `T${Date.now()}${Math.random().toString(36).substr(2, 6).toUpperCase()}`;
            
            const paymentResult = await query(`
                INSERT INTO payments (
                    id, order_id, user_id, amount, payment_method, 
                    payment_method_code, trade_no, status, payment_status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', 'unpaid')
            `, [
                paymentId,
                order_id,
                user_id,
                amount,
                payment_method_code,
                payment_method_code,
                tradeNo
            ]);

            // 根据支付方式处理
            let paymentData = {
                payment_id: paymentId,
                trade_no: tradeNo,
                amount: amount,
                payment_method: payment_method_code
            };

            switch (payment_method_code) {
                case 'balance':
                    // 余额支付
                    paymentData = await this.processBalancePayment(user_id, amount, paymentId, order_id);
                    break;
                    
                case 'wechat':
                    // 微信支付（模拟）
                    paymentData = await this.processWechatPayment(amount, paymentId, description);
                    break;
                    
                case 'alipay':
                    // 支付宝支付（模拟）
                    paymentData = await this.processAlipayPayment(amount, paymentId, description);
                    break;
                    
                case 'cash':
                    // 现金支付
                    paymentData.status = 'pending_cash';
                    paymentData.message = '请等待工作人员确认现金支付';
                    break;
                    
                default:
                    throw new Error('不支持的支付方式');
            }

            return {
                success: true,
                payment_id: paymentId,
                trade_no: tradeNo,
                data: paymentData
            };

        } catch (error) {
            console.error('创建支付订单失败:', error);
            throw error;
        }
    }

    /**
     * 处理余额支付
     */
    static async processBalancePayment(userId, amount, paymentId, orderId) {
        try {
            // 检查余额
            const wallet = await this.getUserWallet(userId);
            if (wallet.balance < amount) {
                throw new Error('余额不足');
            }

            // 开始事务
            await query('START TRANSACTION');

            try {
                // 扣除余额
                await query(`
                    UPDATE user_wallets 
                    SET balance = balance - ?, 
                        total_consumption = total_consumption + ?,
                        last_transaction_at = NOW(),
                        updated_at = NOW()
                    WHERE user_id = ? AND balance >= ?
                `, [amount, amount, userId, amount]);

                // 更新支付状态
                await query(`
                    UPDATE payments 
                    SET status = 'completed', 
                        payment_status = 'paid',
                        paid_at = NOW(),
                        updated_at = NOW()
                    WHERE id = ?
                `, [paymentId]);

                // 更新订单状态
                await query(`
                    UPDATE orders 
                    SET payment_status = 'paid',
                        updated_at = NOW()
                    WHERE id = ?
                `, [orderId]);

                // 记录交易流水
                await query(`
                    INSERT INTO wallet_transactions (
                        wallet_id, user_id, transaction_type, amount,
                        balance_before, balance_after, related_id, related_type,
                        description, status
                    ) VALUES (?, ?, 'consume', ?, ?, ?, ?, 'order', ?, 'completed')
                `, [
                    wallet.id,
                    userId,
                    amount,
                    wallet.balance,
                    wallet.balance - amount,
                    orderId,
                    `医小伴陪诊订单支付 - 订单号: ${orderId}`
                ]);

                await query('COMMIT');

                return {
                    status: 'paid',
                    message: '余额支付成功',
                    balance_after: wallet.balance - amount
                };

            } catch (error) {
                await query('ROLLBACK');
                throw error;
            }

        } catch (error) {
            console.error('余额支付失败:', error);
            throw new Error('余额支付失败: ' + error.message);
        }
    }

    /**
     * 处理微信支付（模拟）
     */
    static async processWechatPayment(amount, paymentId, description) {
        // 模拟微信支付返回
        const prepayId = `wx${Date.now()}${Math.random().toString(36).substr(2, 8)}`;
        const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=wechat://pay/${prepayId}`;
        
        // 更新支付记录
        await query(`
            UPDATE payments 
            SET prepay_id = ?, 
                qr_code_url = ?,
                payment_url = ?,
                updated_at = NOW()
            WHERE id = ?
        `, [
            prepayId,
            qrCodeUrl,
            `weixin://wxpay/bizpayurl?pr=${prepayId}`,
            paymentId
        ]);

        return {
            status: 'pending',
            prepay_id: prepayId,
            qr_code_url: qrCodeUrl,
            payment_url: `weixin://wxpay/bizpayurl?pr=${prepayId}`,
            message: '请使用微信扫描二维码完成支付',
            expires_in: 1800 // 30分钟过期
        };
    }

    /**
     * 处理支付宝支付（模拟）
     */
    static async processAlipayPayment(amount, paymentId, description) {
        // 模拟支付宝支付返回
        const tradeNo = `alipay${Date.now()}${Math.random().toString(36).substr(2, 8)}`;
        const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=alipay://platformapi/startapp?appId=20000067&url=${encodeURIComponent(`https://mclient.alipay.com/cashier/mobilepay?tradeNo=${tradeNo}`)}`;
        
        // 更新支付记录
        await query(`
            UPDATE payments 
            SET trade_no = ?, 
                qr_code_url = ?,
                payment_url = ?,
                updated_at = NOW()
            WHERE id = ?
        `, [
            tradeNo,
            qrCodeUrl,
            `alipays://platformapi/startapp?appId=20000067&url=${encodeURIComponent(`https://mclient.alipay.com/cashier/mobilepay?tradeNo=${tradeNo}`)}`,
            paymentId
        ]);

        return {
            status: 'pending',
            trade_no: tradeNo,
            qr_code_url: qrCodeUrl,
            payment_url: `alipays://platformapi/startapp?appId=20000067&url=${encodeURIComponent(`https://mclient.alipay.com/cashier/mobilepay?tradeNo=${tradeNo}`)}`,
            message: '请使用支付宝扫描二维码完成支付',
            expires_in: 1800 // 30分钟过期
        };
    }

    /**
     * 查询支付状态
     */
    static async getPaymentStatus(paymentId, userId) {
        try {
            const payments = await query(`
                SELECT p.*, o.payment_status as order_payment_status
                FROM payments p
                LEFT JOIN orders o ON p.order_id = o.id
                WHERE p.id = ? AND p.user_id = ?
            `, [paymentId, userId]);
            
            if (payments.length === 0) {
                throw new Error('支付记录不存在');
            }
            
            const payment = payments[0];
            
            // 如果是模拟的微信/支付宝支付，随机返回成功状态（测试用）
            if ((payment.payment_method_code === 'wechat' || payment.payment_method_code === 'alipay') && 
                payment.status === 'pending' && Math.random() > 0.7) {
                // 模拟支付成功
                await query(`
                    UPDATE payments 
                    SET status = 'completed', 
                        payment_status = 'paid',
                        paid_at = NOW(),
                        updated_at = NOW()
                    WHERE id = ?
                `, [paymentId]);
                
                await query(`
                    UPDATE orders 
                    SET payment_status = 'paid',
                        updated_at = NOW()
                    WHERE id = ?
                `, [payment.order_id]);
                
                payment.status = 'completed';
                payment.payment_status = 'paid';
            }
            
            return payment;
        } catch (error) {
            console.error('查询支付状态失败:', error);
            throw new Error('查询支付状态失败');
        }
    }

    /**
     * 用户充值
     */
    static async recharge(userId, amount, paymentMethodCode) {
        try {
            // 验证支付方式
            const methods = await query(`
                SELECT * FROM payment_methods 
                WHERE code = ? AND is_active = TRUE
            `, [paymentMethodCode]);
            
            if (methods.length === 0) {
                throw new Error('支付方式不可用');
            }

            // 创建充值记录
            const rechargeId = `recharge_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            const tradeNo = `R${Date.now()}${Math.random().toString(36).substr(2, 6).toUpperCase()}`;
            
            await query(`
                INSERT INTO recharge_records (
                    id, user_id, amount, payment_method_code, trade_no, status
                ) VALUES (?, ?, ?, ?, ?, 'pending')
            `, [rechargeId, userId, amount, paymentMethodCode, tradeNo]);

            // 根据支付方式处理
            let paymentData = {
                recharge_id: rechargeId,
                trade_no: tradeNo,
                amount: amount
            };

            if (paymentMethodCode === 'wechat') {
                paymentData = await this.processWechatPayment(amount, rechargeId, '账户充值');
            } else if (paymentMethodCode === 'alipay') {
                paymentData = await this.processAlipayPayment(amount, rechargeId, '账户充值');
            } else {
                throw new Error('该支付方式不支持充值');
            }

            return {
                success: true,
                recharge_id: rechargeId,
                data: paymentData
            };

        } catch (error) {
            console.error('创建充值订单失败:', error);
            throw error;
        }
    }

    /**
     * 处理充值回调
     */
    static async handleRechargeCallback(rechargeId) {
        try {
            await query('START TRANSACTION');

            try {
                // 获取充值记录
                const records = await query(`
                    SELECT * FROM recharge_records 
                    WHERE id = ? AND status = 'pending'
                `, [rechargeId]);
                
                if (records.length === 0) {
                    throw new Error('充值记录不存在或已处理');
                }

                const record = records[0];

                // 更新充值状态
                await query(`
                    UPDATE recharge_records 
                    SET status = 'paid',
                        completed_at = NOW(),
                        updated_at = NOW()
                    WHERE id = ?
                `, [rechargeId]);

                // 更新用户钱包
                await query(`
                    UPDATE user_wallets 
                    SET balance = balance + ?,
                        total_recharge = total_recharge + ?,
                        last_transaction_at = NOW(),
                        updated_at = NOW()
                    WHERE user_id = ?
                `, [record.amount, record.amount, record.user_id]);

                // 获取钱包信息记录交易
                const wallets = await query(`
                    SELECT * FROM user_wallets WHERE user_id = ?
                `, [record.user_id]);
                
                if (wallets.length > 0) {
                    const wallet = wallets[0];
                    await query(`
                        INSERT INTO wallet_transactions (
                            wallet_id, user_id, transaction_type, amount,
                            balance_before, balance_after, related_id, related_type,
                            description, status
                        ) VALUES (?, ?, 'recharge', ?, ?, ?, ?, 'recharge', ?, 'completed')
                    `, [
                        wallet.id,
                        record.user_id,
                        record.amount,
                        wallet.balance - record.amount,
                        wallet.balance,
                        rechargeId,
                        `账户充值 - 金额: ${record.amount}元`
                    ]);
                }

                await query('COMMIT');

                return {
                    success: true,
                    message: '充值成功',
                    amount: record.amount,
                    new_balance: wallets[0] ? wallets[0].balance + record.amount : record.amount
                };

            } catch (error) {
                await query('ROLLBACK');
                throw error;
            }

        } catch (error) {
            console.error('处理充值回调失败:', error);
            throw new Error('处理充值回调失败');
        }
    }

    /**
     * 获取用户交易记录
     */
    static async getUserTransactions(userId, limit = 20, offset = 0) {
        try {
            // 获取支付记录
            const payments = await query(`
                SELECT 
                    p.id, p.order_id, p.amount, p.payment_method_code,
                    p.status, p.payment_status, p.created_at,
                    'payment' as type,
                    CONCAT('订单支付 - ', o.service_type) as description
                FROM payments p
                LEFT JOIN orders o ON p.order_id = o.id
                WHERE p.user_id = ?
                ORDER BY p.created_at DESC
                LIMIT ? OFFSET ?
            `, [userId, limit, offset]);

            // 获取充值记录
            const recharges = await query(`
                SELECT 
                    id, NULL as order_id, amount, payment_method_code,
                    status, NULL as payment_status, created_at,
                    'recharge' as type,
                    '账户充值' as description
                FROM recharge_records
                WHERE user_id = ?
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
            `, [userId, limit, offset]);

            // 合并并排序
            const allTransactions = [...payments, ...recharges]
                .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
                .slice(0, limit);

            return allTransactions;
        } catch (error) {
            console.error('获取交易记录失败:', error);
            throw new Error('获取交易记录失败');
        }
    }
}

module.exports = PaymentSystem;