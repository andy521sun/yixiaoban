/**
 * 医小伴APP - 支付服务模块
 * 提供完整的支付、充值、退款功能
 */

const { query, transaction } = require('../db');

class PaymentService {
    /**
     * 生成充值单号
     */
    static generateRechargeNumber() {
        const date = new Date();
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
        return `RC${year}${month}${day}${random}`;
    }

    /**
     * 生成交易ID
     */
    static generateTransactionId() {
        return `trans_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    /**
     * 获取用户钱包
     */
    static async getUserWallet(userId) {
        try {
            const wallets = await query(
                'SELECT * FROM user_wallets WHERE user_id = ?',
                [userId]
            );
            
            if (wallets.length === 0) {
                // 创建默认钱包
                const walletId = `wallet_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
                await query(
                    'INSERT INTO user_wallets (id, user_id, balance, total_recharge) VALUES (?, ?, 0.00, 0.00)',
                    [walletId, userId]
                );
                
                return {
                    id: walletId,
                    user_id: userId,
                    balance: 0.00,
                    frozen_amount: 0.00,
                    total_recharge: 0.00,
                    total_withdraw: 0.00,
                    total_consumption: 0.00
                };
            }
            
            return wallets[0];
        } catch (error) {
            console.error('获取用户钱包失败:', error);
            throw new Error('获取用户钱包失败');
        }
    }

    /**
     * 获取可用支付方式
     */
    static async getPaymentMethods(userId = null) {
        try {
            const methods = await query(
                'SELECT * FROM payment_methods WHERE is_active = TRUE ORDER BY sort_order ASC'
            );
            
            // 如果用户已登录，检查余额支付是否可用
            if (userId) {
                const wallet = await this.getUserWallet(userId);
                return methods.map(method => {
                    if (method.code === 'balance') {
                        return {
                            ...method,
                            available: wallet.balance > 0,
                            balance: wallet.balance
                        };
                    }
                    return { ...method, available: true };
                });
            }
            
            return methods;
        } catch (error) {
            console.error('获取支付方式失败:', error);
            throw new Error('获取支付方式失败');
        }
    }

    /**
     * 创建充值订单
     */
    static async createRecharge(userId, amount, paymentMethodCode) {
        try {
            // 验证金额
            if (amount < 10 || amount > 5000) {
                throw new Error('充值金额必须在10元到5000元之间');
            }

            // 获取用户钱包
            const wallet = await this.getUserWallet(userId);
            
            // 获取支付方式
            const methods = await query(
                'SELECT * FROM payment_methods WHERE code = ? AND is_active = TRUE',
                [paymentMethodCode]
            );
            
            if (methods.length === 0) {
                throw new Error('支付方式不可用');
            }

            const paymentMethod = methods[0];

            // 生成充值单号
            const rechargeNumber = this.generateRechargeNumber();
            const rechargeId = `recharge_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

            // 创建充值记录
            await query(
                `INSERT INTO recharge_records 
                (id, recharge_number, user_id, wallet_id, amount, payment_method_code, description) 
                VALUES (?, ?, ?, ?, ?, ?, ?)`,
                [
                    rechargeId,
                    rechargeNumber,
                    userId,
                    wallet.id,
                    amount,
                    paymentMethodCode,
                    `充值${amount}元`
                ]
            );

            // 模拟支付处理（实际应该调用第三方支付接口）
            // 这里模拟支付成功
            setTimeout(async () => {
                try {
                    await this.processRechargeSuccess(rechargeId);
                } catch (error) {
                    console.error('模拟支付回调失败:', error);
                }
            }, 3000); // 3秒后模拟支付成功

            return {
                recharge_id: rechargeId,
                recharge_number: rechargeNumber,
                amount,
                payment_method: paymentMethod.name,
                qr_code_url: `/api/payment/qrcode/${rechargeId}`, // 模拟二维码
                expires_at: new Date(Date.now() + 30 * 60 * 1000) // 30分钟过期
            };
        } catch (error) {
            console.error('创建充值订单失败:', error);
            throw error;
        }
    }

    /**
     * 处理充值成功
     */
    static async processRechargeSuccess(rechargeId) {
        try {
            // 获取充值记录
            const recharges = await query(
                'SELECT * FROM recharge_records WHERE id = ?',
                [rechargeId]
            );
            
            if (recharges.length === 0) {
                throw new Error('充值记录不存在');
            }

            const recharge = recharges[0];

            // 检查是否已处理
            if (recharge.payment_status === 'paid') {
                return { success: true, message: '充值已处理' };
            }

            // 开始事务
            await query('START TRANSACTION');

            try {
                // 更新充值记录状态
                await query(
                    `UPDATE recharge_records 
                    SET payment_status = 'paid', 
                        paid_amount = ?,
                        paid_time = NOW(),
                        updated_at = NOW()
                    WHERE id = ?`,
                    [recharge.amount, rechargeId]
                );

                // 获取当前钱包余额
                const wallets = await query(
                    'SELECT * FROM user_wallets WHERE id = ? FOR UPDATE',
                    [recharge.wallet_id]
                );
                
                if (wallets.length === 0) {
                    throw new Error('钱包不存在');
                }

                const wallet = wallets[0];
                const newBalance = parseFloat(wallet.balance) + parseFloat(recharge.amount);

                // 更新钱包余额
                await query(
                    `UPDATE user_wallets 
                    SET balance = ?,
                        total_recharge = total_recharge + ?,
                        updated_at = NOW()
                    WHERE id = ?`,
                    [newBalance, recharge.amount, recharge.wallet_id]
                );

                // 创建钱包交易记录
                const transactionId = this.generateTransactionId();
                await query(
                    `INSERT INTO wallet_transactions 
                    (id, wallet_id, user_id, transaction_type, amount, 
                     balance_before, balance_after, related_id, related_type, 
                     description, status) 
                    VALUES (?, ?, ?, 'recharge', ?, ?, ?, ?, ?, ?, 'success')`,
                    [
                        transactionId,
                        recharge.wallet_id,
                        recharge.user_id,
                        recharge.amount,
                        wallet.balance,
                        newBalance,
                        rechargeId,
                        'recharge',
                        `充值${recharge.amount}元`
                    ]
                );

                await query('COMMIT');

                console.log(`✅ 充值成功: ${recharge.recharge_number}, 金额: ${recharge.amount}元`);
                
                return {
                    success: true,
                    recharge_id: rechargeId,
                    amount: recharge.amount,
                    new_balance: newBalance
                };
            } catch (error) {
                await query('ROLLBACK');
                throw error;
            }
        } catch (error) {
            console.error('处理充值成功失败:', error);
            throw error;
        }
    }

    /**
     * 支付订单
     */
    static async payOrder(orderId, userId, paymentMethodCode) {
        try {
            // 获取订单信息
            const orders = await query(
                'SELECT * FROM orders WHERE id = ?',
                [orderId]
            );
            
            if (orders.length === 0) {
                throw new Error('订单不存在');
            }

            const order = orders[0];

            // 检查订单是否属于当前用户
            if (order.patient_id !== userId) {
                throw new Error('无权支付此订单');
            }

            // 检查订单状态
            if (order.payment_status === 'paid') {
                throw new Error('订单已支付');
            }

            if (order.status === 'cancelled') {
                throw new Error('订单已取消，无法支付');
            }

            // 获取支付方式
            const methods = await query(
                'SELECT * FROM payment_methods WHERE code = ? AND is_active = TRUE',
                [paymentMethodCode]
            );
            
            if (methods.length === 0) {
                throw new Error('支付方式不可用');
            }

            const paymentMethod = methods[0];

            // 根据支付方式处理
            if (paymentMethod.code === 'balance') {
                return await this.payWithBalance(order, userId);
            } else if (['wechat', 'alipay'].includes(paymentMethod.code)) {
                return await this.payWithThirdParty(order, userId, paymentMethod);
            } else if (paymentMethod.code === 'cash') {
                return await this.payWithCash(order, userId);
            } else {
                throw new Error('不支持的支付方式');
            }
        } catch (error) {
            console.error('支付订单失败:', error);
            throw error;
        }
    }

    /**
     * 余额支付
     */
    static async payWithBalance(order, userId) {
        try {
            // 获取用户钱包
            const wallet = await this.getUserWallet(userId);

            // 检查余额是否足够
            if (parseFloat(wallet.balance) < parseFloat(order.total_amount)) {
                throw new Error('余额不足，请先充值');
            }

            // 开始事务
            await query('START TRANSACTION');

            try {
                // 更新订单支付状态
                await query(
                    `UPDATE orders 
                    SET payment_status = 'paid',
                        payment_method = 'balance',
                        payment_time = NOW(),
                        updated_at = NOW()
                    WHERE id = ?`,
                    [order.id]
                );

                // 计算新余额
                const newBalance = parseFloat(wallet.balance) - parseFloat(order.total_amount);

                // 更新钱包余额
                await query(
                    `UPDATE user_wallets 
                    SET balance = ?,
                        total_consumption = total_consumption + ?,
                        updated_at = NOW()
                    WHERE id = ?`,
                    [newBalance, order.total_amount, wallet.id]
                );

                // 创建钱包交易记录
                const transactionId = this.generateTransactionId();
                await query(
                    `INSERT INTO wallet_transactions 
                    (id, wallet_id, user_id, transaction_type, amount, 
                     balance_before, balance_after, related_id, related_type, 
                     description, status) 
                    VALUES (?, ?, ?, 'payment', ?, ?, ?, ?, ?, ?, 'success')`,
                    [
                        transactionId,
                        wallet.id,
                        userId,
                        -order.total_amount, // 负数表示支出
                        wallet.balance,
                        newBalance,
                        order.id,
                        'order',
                        `支付订单${order.order_number}`
                    ]
                );

                // 创建支付记录
                const paymentId = `payment_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
                await query(
                    `INSERT INTO payments 
                    (id, order_id, payment_number, amount, payment_method, 
                     payment_status, payer_id, payer_name, receiver_id, 
                     receiver_name, payment_time) 
                    VALUES (?, ?, ?, ?, ?, 'success', ?, ?, ?, ?, NOW())`,
                    [
                        paymentId,
                        order.id,
                        `PAY${Date.now()}`,
                        order.total_amount,
                        'balance',
                        userId,
                        '用户',
                        'system',
                        '系统'
                    ]
                );

                await query('COMMIT');

                return {
                    success: true,
                    payment_id: paymentId,
                    order_id: order.id,
                    amount: order.total_amount,
                    new_balance: newBalance,
                    message: '支付成功'
                };
            } catch (error) {
                await query('ROLLBACK');
                throw error;
            }
        } catch (error) {
            console.error('余额支付失败:', error);
            throw error;
        }
    }

    /**
     * 第三方支付（微信/支付宝）
     */
    static async payWithThirdParty(order, userId, paymentMethod) {
        try {
            // 生成支付参数（模拟）
            const paymentId = `payment_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            
            // 创建支付记录（待支付状态）
            await query(
                `INSERT INTO payments 
                (id, order_id, payment_number, amount, payment_method, 
                 payment_status, payer_id, payer_name) 
                VALUES (?, ?, ?, ?, ?, 'pending', ?, ?)`,
                [
                    paymentId,
                    order.id,
                    `PAY${Date.now()}`,
                    order.total_amount,
                    paymentMethod.code,
                    userId,
                    '用户'
                ]
            );

            // 模拟第三方支付参数
            const paymentData = {
                payment_id: paymentId,
                order_id: order.id,
                amount: order.total_amount,
                payment_method: paymentMethod.name,
                qr_code_url: `/api/payment/qrcode/${paymentId}`,
                payment_url: `/api/payment/redirect/${paymentId}`,
                expires_at: new Date(Date.now() + 30 * 60 * 1000) // 30分钟过期
            };

            // 模拟支付成功回调（实际应该由第三方支付平台回调）
            setTimeout(async () => {
                try {
                    await this.processThirdPartyPaymentSuccess(paymentId);
                } catch (error) {
                    console.error('模拟第三方支付回调失败:', error);
                }
            }, 5000); // 5秒后模拟支付成功

            return {
                success: true,
                ...paymentData,
                message: '请扫描二维码完成支付'
            };
        } catch (error) {
            console.error('第三方支付创建失败:', error);
            throw error;
        }
    }

    /**
     * 处理第三方支付成功
     */
    static async processThirdPartyPaymentSuccess(paymentId) {
        try {
            // 获取支付记录
            const payments = await query(
                'SELECT * FROM payments WHERE id = ?',
                [paymentId]
            );
            
            if (payments.length === 0) {
                throw new Error('支付记录不存在');
            }

            const payment = payments[0];

            // 检查是否已处理
            if (payment.payment_status === 'success') {
                return { success: true, message: '支付已处理' };
            }

            // 开始事务
            await query('START TRANSACTION');

            try {
                // 更新支付记录状态
                await query(
                    `UPDATE payments 
                    SET payment_status = 'success',
                        payment_time = NOW(),
                        updated_at = NOW()
                    WHERE id = ?`,
                    [paymentId]
                );

                // 更新订单支付状态
                await query(
                    `UPDATE orders 
                    SET payment_status = 'paid',
                        payment_method = ?,
                        payment_time = NOW(),
                        updated_at = NOW()
                    WHERE id = ?`,
                    [payment.payment_method, payment.order_id]
                );

                await query('COMMIT');

                console.log(`✅ 第三方支付成功: ${payment.payment_number}, 金额: ${payment.amount}元`);
                
                return {
                    success: true,
                    payment_id: paymentId,
                    order_id: payment.order_id,
                    amount: payment.amount
                };
            } catch (error) {
                await query('ROLLBACK');
                throw error;
            }
        } catch (error) {
            console.error('处理第三方支付成功失败:', error);
            throw error;
        }
    }

    /**
     * 现金支付
     */
    static async payWithCash(order, userId) {
        try {
            // 创建支付记录（待确认状态）
            const paymentId = `payment_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            
            await query(
                `INSERT INTO payments 
                (id, order_id, payment_number, amount, payment_method, 
                 payment_status, payer_id, payer_name) 
                VALUES (?, ?, ?, ?, 'cash', 'pending', ?, ?)`,
                [
                    paymentId,
                    order.id,
                    `PAY${Date.now()}`,
                    order.total_amount,
                    userId,
                    '用户'
                ]
            );

            // 更新订单支付状态为待确认
            await query(
                `UPDATE orders 
                SET payment_status = 'pending',
                    payment_method = 'cash',
                    updated_at = NOW()
                WHERE id = ?`,
                [order.id]
            );

            return {
                success: true,
                payment_id: paymentId,
                order_id: order.id,
                amount: order.total_amount,
                message: '请线下支付现金，支付后联系陪诊师确认'
            };
        } catch (error) {
            console.error('现金支付创建失败:', error);
            throw error;
        }
    }

    /**
     * 确认现金支付
     */
    static async confirmCashPayment(paymentId, confirmUserId) {
        try {
            // 获取支付记录
            const payments = await query(
                'SELECT * FROM payments WHERE id = ? AND payment_method = "cash"',
                [paymentId]
            );
            
            if (payments.length === 0) {
                throw new Error('现金支付记录不存在');
            }

            const payment = payments[0];

            // 开始事务
            await query('START TRANSACTION');

            try {
                // 更新支付记录状态
                await query(
                    `UPDATE payments 
                    SET payment_status = 'success',
                        payment_time = NOW(),
                        updated_at = NOW(),
                        receiver_id = ?,
                        receiver_name = '陪诊师'
                    WHERE id = ?`,
                    [confirmUserId, paymentId]
                );

                //