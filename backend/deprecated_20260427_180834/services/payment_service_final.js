/**
 * 医小伴APP - 支付服务模块（简化完整版）
 */

const { query } = require('../db');

class PaymentService {
    // 生成充值单号
    static generateRechargeNumber() {
        const date = new Date();
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
        return `RC${year}${month}${day}${random}`;
    }

    // 获取用户钱包
    static async getUserWallet(userId) {
        try {
            const wallets = await query('SELECT * FROM user_wallets WHERE user_id = ?', [userId]);
            if (wallets.length === 0) {
                // 使用MySQL的UUID函数生成钱包ID
                await query('INSERT INTO user_wallets (user_id, balance) VALUES (?, 0.00)', [userId]);
                // 重新查询获取生成的ID
                const newWallets = await query('SELECT * FROM user_wallets WHERE user_id = ?', [userId]);
                if (newWallets.length === 0) {
                    throw new Error('创建钱包失败');
                }
                return newWallets[0];
            }
            return wallets[0];
        } catch (error) {
            console.error('获取用户钱包失败:', error);
            throw new Error('获取用户钱包失败');
        }
    }

    // 获取支付方式
    static async getPaymentMethods(userId = null) {
        try {
            const methods = await query('SELECT * FROM payment_methods WHERE is_active = TRUE ORDER BY sort_order ASC');
            if (userId) {
                const wallet = await this.getUserWallet(userId);
                return methods.map(method => {
                    if (method.code === 'balance') {
                        return { ...method, available: wallet.balance > 0, balance: wallet.balance };
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

    // 创建充值订单
    static async createRecharge(userId, amount, paymentMethodCode) {
        try {
            if (amount < 10 || amount > 5000) throw new Error('充值金额必须在10元到5000元之间');
            
            const wallet = await this.getUserWallet(userId);
            const methods = await query('SELECT * FROM payment_methods WHERE code = ? AND is_active = TRUE', [paymentMethodCode]);
            if (methods.length === 0) throw new Error('支付方式不可用');

            const rechargeNumber = this.generateRechargeNumber();
            const rechargeId = `recharge_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

            await execute(
                'INSERT INTO recharge_records (id, recharge_number, user_id, wallet_id, amount, payment_method_code, description) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [rechargeId, rechargeNumber, userId, wallet.id, amount, paymentMethodCode, `充值${amount}元`]
            );

            // 模拟支付成功
            setTimeout(async () => {
                try {
                    await this.processRechargeSuccess(rechargeId);
                } catch (error) {
                    console.error('模拟支付回调失败:', error);
                }
            }, 3000);

            return {
                recharge_id: rechargeId,
                recharge_number: rechargeNumber,
                amount,
                payment_method: methods[0].name,
                qr_code_url: `/api/payment/qrcode/${rechargeId}`,
                expires_at: new Date(Date.now() + 30 * 60 * 1000)
            };
        } catch (error) {
            console.error('创建充值订单失败:', error);
            throw error;
        }
    }

    // 处理充值成功
    static async processRechargeSuccess(rechargeId) {
        try {
            const recharges = await query('SELECT * FROM recharge_records WHERE id = ?', [rechargeId]);
            if (recharges.length === 0) throw new Error('充值记录不存在');
            const recharge = recharges[0];
            if (recharge.payment_status === 'paid') return { success: true, message: '充值已处理' };

            await execute('START TRANSACTION');
            try {
                await execute(
                    'UPDATE recharge_records SET payment_status = "paid", paid_amount = ?, paid_time = NOW() WHERE id = ?',
                    [recharge.amount, rechargeId]
                );

                const wallets = await query('SELECT * FROM user_wallets WHERE id = ? FOR UPDATE', [recharge.wallet_id]);
                if (wallets.length === 0) throw new Error('钱包不存在');
                const wallet = wallets[0];
                const newBalance = parseFloat(wallet.balance) + parseFloat(recharge.amount);

                await execute(
                    'UPDATE user_wallets SET balance = ?, total_recharge = total_recharge + ? WHERE id = ?',
                    [newBalance, recharge.amount, recharge.wallet_id]
                );

                const transactionId = `trans_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
                await execute(
                    'INSERT INTO wallet_transactions (id, wallet_id, user_id, transaction_type, amount, balance_before, balance_after, related_id, related_type, description, status) VALUES (?, ?, ?, "recharge", ?, ?, ?, ?, ?, ?, "success")',
                    [transactionId, recharge.wallet_id, recharge.user_id, recharge.amount, wallet.balance, newBalance, rechargeId, 'recharge', `充值${recharge.amount}元`]
                );

                await execute('COMMIT');
                console.log(`✅ 充值成功: ${recharge.recharge_number}, 金额: ${recharge.amount}元`);
                return { success: true, recharge_id: rechargeId, amount: recharge.amount, new_balance: newBalance };
            } catch (error) {
                await execute('ROLLBACK');
                throw error;
            }
        } catch (error) {
            console.error('处理充值成功失败:', error);
            throw error;
        }
    }

    // 支付订单
    static async payOrder(orderId, userId, paymentMethodCode) {
        try {
            const orders = await query('SELECT * FROM orders WHERE id = ?', [orderId]);
            if (orders.length === 0) throw new Error('订单不存在');
            const order = orders[0];
            if (order.patient_id !== userId) throw new Error('无权支付此订单');
            if (order.payment_status === 'paid') throw new Error('订单已支付');
            if (order.status === 'cancelled') throw new Error('订单已取消，无法支付');

            const methods = await query('SELECT * FROM payment_methods WHERE code = ? AND is_active = TRUE', [paymentMethodCode]);
            if (methods.length === 0) throw new Error('支付方式不可用');
            const paymentMethod = methods[0];

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

    // 余额支付
    static async payWithBalance(order, userId) {
        try {
            const wallet = await this.getUserWallet(userId);
            if (parseFloat(wallet.balance) < parseFloat(order.total_amount)) {
                throw new Error('余额不足，请先充值');
            }

            await execute('START TRANSACTION');
            try {
                await execute(
                    'UPDATE orders SET payment_status = "paid", payment_method = "balance", payment_time = NOW() WHERE id = ?',
                    [order.id]
                );

                const newBalance = parseFloat(wallet.balance) - parseFloat(order.total_amount);
                await execute(
                    'UPDATE user_wallets SET balance = ?, total_consumption = total_consumption + ? WHERE id = ?',
                    [newBalance, order.total_amount, wallet.id]
                );

                const transactionId = `trans_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
                await execute(
                    'INSERT INTO wallet_transactions (id, wallet_id, user_id, transaction_type, amount, balance_before, balance_after, related_id, related_type, description, status) VALUES (?, ?, ?, "payment", ?, ?, ?, ?, ?, ?, "success")',
                    [transactionId, wallet.id, userId, -order.total_amount, wallet.balance, newBalance, order.id, 'order', `支付订单${order.order_number}`]
                );

                const paymentId = `payment_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
                await execute(
                    'INSERT INTO payments (id, order_id, payment_number, amount, payment_method, payment_status, payer_id, payer_name, receiver_id, receiver_name, payment_time) VALUES (?, ?, ?, ?, "balance", "success", ?, ?, "system", "系统", NOW())',
                    [paymentId, order.id, `PAY${Date.now()}`, order.total_amount, userId, '用户']
                );

                await execute('COMMIT');
                return {
                    success: true,
                    payment_id: paymentId,
                    order_id: order.id,
                    amount: order.total_amount,
                    new_balance: newBalance,
                    message: '支付成功'
                };
            } catch (error) {
                await execute('ROLLBACK');
                throw error;
            }
        } catch (error) {
            console.error('余额支付失败:', error);
            throw error;
        }
    }

    // 第三方支付
    static async payWithThirdParty(order, userId, paymentMethod) {
        try {
            const paymentId = `payment_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            await execute(
                'INSERT INTO payments (id, order_id, payment_number, amount, payment_method, payment_status, payer_id, payer_name) VALUES (?, ?, ?, ?, ?, "pending", ?, ?)',
                [paymentId, order.id, `PAY${Date.now()}`, order.total_amount, paymentMethod.code, userId, '用户']
            );

            // 模拟支付成功
            setTimeout(async () => {
                try {
                    await this.processThirdPartyPaymentSuccess(paymentId);
                } catch (error) {
                    console.error('模拟第三方支付回调失败:', error);
                }
            }, 5000);

            return {
                success: true,
                payment_id: paymentId,
                order_id: order.id,
                amount: order.total_amount,
                payment_method: paymentMethod.name,
                qr_code_url: `/api/payment/qrcode/${paymentId}`,
                expires_at: new Date(Date.now() + 30 * 60 * 1000),
                message: '请扫描二维码完成支付'
            };
        } catch (error) {
            console.error('第三方支付创建失败:', error);
            throw error;
        }
    }

    // 处理第三方支付成功
    static async processThirdPartyPaymentSuccess(paymentId) {
        try {
            const payments = await query('SELECT * FROM payments WHERE id = ?', [paymentId]);
            if (payments.length === 0) throw new Error('支付记录不存在');
            const payment = payments[0];
            if (payment.payment_status === 'success') return { success: true, message: '支付已处理' };

            await execute('START TRANSACTION');
            try {
                await execute('UPDATE payments SET payment_status = "success", payment_time = NOW() WHERE id = ?', [paymentId]);
                await execute('UPDATE orders SET payment_status = "paid", payment_method = ?, payment_time = NOW() WHERE id = ?', [payment.payment_method, payment.order_id]);
                await execute('COMMIT');
                console.log(`✅ 第三方支付成功: ${payment.payment_number}, 金额: ${payment.amount}元`);
                return { success: true, payment_id: paymentId, order_id: payment.order_id, amount: payment.amount };
            } catch (error) {
                await execute('ROLLBACK');
                throw error;
            }
        } catch (error) {
            console.error('处理第三方支付成功失败:', error);
            throw error;
        }
    }

    // 现金支付
    static async payWithCash(order, userId) {
        try {
            const paymentId = `payment_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            await execute(
                'INSERT INTO payments (id, order_id, payment_number, amount, payment_method, payment_status, payer_id, payer_name) VALUES (?, ?, ?, ?, "cash", "pending", ?, ?)',
                [paymentId, order.id, `PAY${Date.now()}`, order.total_amount, userId, '用户']
            );
            await execute('UPDATE orders SET payment_status = "pending", payment_method = "cash" WHERE id = ?', [order.id]);
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

    // 申请退款
    static async applyRefund(orderId, userId, reason) {
        try {
            const orders = await query('SELECT * FROM orders WHERE id = ?', [orderId]);
            if (orders.length === 0) throw new Error('订单不存在');
            const order = orders[0];
            if (order.patient_id !== userId) throw new Error('无权申请退款');
            if (!['pending', 'confirmed', 'cancelled'].includes(order.status)) throw new Error('当前订单状态不可退款');
            if (order.payment_status !== 'paid') throw new Error('订单未支付，无法退款');

            const existingRefunds = await query('SELECT * FROM refund_applications WHERE order_id = ? AND status IN ("pending", "approved", "processing")', [orderId]);
            if (existingRefunds.length > 0) throw new Error('该订单已有退款申请在处理中');

            const refundId = `refund_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            await execute(
                'INSERT INTO refund_applications (id, order_id, user_id, amount, reason, status) VALUES (?, ?, ?, ?, ?, "pending")',
                [refundId, orderId, userId, order.total_amount, reason]
            );

            return {
                success: true,
                refund_id: refundId,
                order_id: orderId,
                amount: order.total_amount,
                message: '退款申请已提交，请等待审核'
            };
        } catch (error) {
            console.error('申请退款失败:', error);
            throw error;
        }
    }

    // 获取用户交易记录
    static async getUserTransactions(userId, limit = 20, page = 1) {
        try {
            const offset = (page - 1) * limit;
            const walletTransactions = await query(
                'SELECT id, "wallet" as source, transaction_type as type, amount, balance_before, balance_after, description, status, created_at FROM wallet_transactions WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
                [userId, limit, offset]
            );
            const rechargeRecords = await query(
                'SELECT id, "recharge" as source, "recharge" as type, amount, NULL as balance_before, NULL as balance_after, description, payment_status as status, created_at FROM recharge_records WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
                [userId, limit, offset]
            );
            const paymentRecords = await query(
                'SELECT id, "payment" as source, "payment" as type, amount, NULL as balance_before, NULL as balance_after, CONCAT("支付订单", order_id) as description, payment_status as status, payment_time as created_at FROM payments WHERE payer_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
                [userId, limit, offset]
            );
            const allTransactions = [...walletTransactions, ...rechargeRecords, ...paymentRecords]
                .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
                .slice(0, limit);
            return allTransactions;
        } catch (error) {
            console.error('获取用户交易记录失败:', error);
            throw error;
        }
    }

    // 检查支付状态
    static async checkPaymentStatus(paymentId, userId) {
        try {
            const payments = await query('SELECT * FROM payments WHERE id = ?', [paymentId]);
            if (payments.length === 0) throw new Error('支付记录不存在');
            const payment = payments[0];
            if (payment.payer_id !== userId) throw new Error('无权查看此支付记录');
            return {
                payment_id: payment.id,
                order_id: payment.order_id,
                amount: payment.amount,
                payment_method: payment.payment_method,
                payment_status: payment.payment_status,
                payment_time: payment.payment_time,
                created_at: payment.created_at
            };
        } catch (error) {
            console.error('检查支付状态失败:', error);
            throw error;
        }
    }
}

module.exports = PaymentService;