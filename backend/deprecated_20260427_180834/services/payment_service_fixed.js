/**
 * 医小伴APP - 支付服务模块（修复版）
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
                // 创建钱包
                await query('INSERT INTO user_wallets (user_id, balance) VALUES (?, 0.00)', [userId]);
                // 重新查询
                const newWallets = await query('SELECT * FROM user_wallets WHERE user_id = ?', [userId]);
                if (newWallets.length === 0) throw new Error('创建钱包失败');
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

    // 创建充值订单（简化版，只返回数据，不实际处理）
    static async createRecharge(userId, amount, paymentMethodCode) {
        try {
            if (amount < 10 || amount > 5000) throw new Error('充值金额必须在10元到5000元之间');
            
            const wallet = await this.getUserWallet(userId);
            const methods = await query('SELECT * FROM payment_methods WHERE code = ? AND is_active = TRUE', [paymentMethodCode]);
            if (methods.length === 0) throw new Error('支付方式不可用');

            const rechargeNumber = this.generateRechargeNumber();
            const rechargeId = `recharge_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

            // 创建充值记录（模拟）
            console.log(`模拟创建充值记录: ${rechargeNumber}, 用户: ${userId}, 金额: ${amount}元`);

            return {
                recharge_id: rechargeId,
                recharge_number: rechargeNumber,
                amount,
                payment_method: methods[0].name,
                qr_code_url: `/api/payment/qrcode/${rechargeId}`,
                expires_at: new Date(Date.now() + 30 * 60 * 1000),
                message: '充值订单创建成功（模拟）'
            };
        } catch (error) {
            console.error('创建充值订单失败:', error);
            throw error;
        }
    }

    // 支付订单（简化版）
    static async payOrder(orderId, userId, paymentMethodCode) {
        try {
            const orders = await query('SELECT * FROM orders WHERE id = ?', [orderId]);
            if (orders.length === 0) throw new Error('订单不存在');
            const order = orders[0];
            if (order.patient_id !== userId) throw new Error('无权支付此订单');
            if (order.payment_status === 'paid') throw new Error('订单已支付');

            const methods = await query('SELECT * FROM payment_methods WHERE code = ? AND is_active = TRUE', [paymentMethodCode]);
            if (methods.length === 0) throw new Error('支付方式不可用');

            const paymentMethod = methods[0];
            const paymentId = `payment_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

            // 模拟支付处理
            console.log(`模拟支付: 订单 ${orderId}, 用户 ${userId}, 方式 ${paymentMethodCode}, 金额 ${order.total_amount}`);

            return {
                success: true,
                payment_id: paymentId,
                order_id: orderId,
                amount: order.total_amount,
                payment_method: paymentMethod.name,
                message: '支付处理中（模拟）'
            };
        } catch (error) {
            console.error('支付订单失败:', error);
            throw error;
        }
    }

    // 申请退款（简化版）
    static async applyRefund(orderId, userId, reason) {
        try {
            const orders = await query('SELECT * FROM orders WHERE id = ?', [orderId]);
            if (orders.length === 0) throw new Error('订单不存在');
            const order = orders[0];
            if (order.patient_id !== userId) throw new Error('无权申请退款');
            if (order.payment_status !== 'paid') throw new Error('订单未支付，无法退款');

            const refundId = `refund_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

            console.log(`模拟退款申请: 订单 ${orderId}, 用户 ${userId}, 原因: ${reason}`);

            return {
                success: true,
                refund_id: refundId,
                order_id: orderId,
                amount: order.total_amount,
                message: '退款申请已提交（模拟）'
            };
        } catch (error) {
            console.error('申请退款失败:', error);
            throw error;
        }
    }

    // 获取用户交易记录（简化版）
    static async getUserTransactions(userId, limit = 20, page = 1) {
        try {
            // 简化版本，只返回空数组
            return [];
        } catch (error) {
            console.error('获取用户交易记录失败:', error);
            throw error;
        }
    }

    // 检查支付状态
    static async checkPaymentStatus(paymentId, userId) {
        try {
            // 模拟支付状态检查
            return {
                payment_id: paymentId,
                payment_status: 'success', // 模拟成功
                message: '支付状态检查（模拟）'
            };
        } catch (error) {
            console.error('检查支付状态失败:', error);
            throw error;
        }
    }
}

module.exports = PaymentService;