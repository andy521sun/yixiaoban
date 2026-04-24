-- 医小伴APP - 支付系统表结构（最终版）
-- 创建时间: 2026-04-02

-- 支付方式表（如果不存在则创建）
CREATE TABLE IF NOT EXISTS payment_methods (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(100) NOT NULL COMMENT '支付方式名称',
    code VARCHAR(50) UNIQUE NOT NULL COMMENT '支付方式代码: wechat, alipay, balance, cash',
    description VARCHAR(500) COMMENT '描述',
    icon_url VARCHAR(500) COMMENT '图标URL',
    sort_order INT DEFAULT 0 COMMENT '排序',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否启用',
    config JSON COMMENT '配置信息',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_is_active (is_active)
);

-- 钱包交易记录表
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    wallet_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    transaction_type ENUM('recharge', 'payment', 'refund', 'withdraw', 'adjustment', 'reward') NOT NULL,
    amount DECIMAL(10, 2) NOT NULL COMMENT '交易金额，正数表示收入，负数表示支出',
    balance_before DECIMAL(10, 2) NOT NULL COMMENT '交易前余额',
    balance_after DECIMAL(10, 2) NOT NULL COMMENT '交易后余额',
    related_id VARCHAR(36) COMMENT '关联ID（订单ID、充值记录ID等）',
    related_type VARCHAR(50) COMMENT '关联类型',
    description VARCHAR(500) NOT NULL,
    status ENUM('pending', 'success', 'failed', 'cancelled') DEFAULT 'pending',
    remark VARCHAR(500) COMMENT '备注',
    operator_id VARCHAR(36) COMMENT '操作员ID',
    operator_type ENUM('user', 'system', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_wallet_id (wallet_id),
    INDEX idx_user_id (user_id),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- 充值记录表
CREATE TABLE IF NOT EXISTS recharge_records (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    recharge_number VARCHAR(50) UNIQUE NOT NULL COMMENT '充值单号',
    user_id VARCHAR(36) NOT NULL,
    wallet_id VARCHAR(36) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method_code VARCHAR(50) NOT NULL COMMENT '支付方式代码',
    payment_status ENUM('pending', 'paid', 'failed', 'cancelled') DEFAULT 'pending',
    transaction_id VARCHAR(100) COMMENT '第三方交易号',
    paid_amount DECIMAL(10, 2) COMMENT '实际支付金额',
    paid_time TIMESTAMP NULL,
    description VARCHAR(500),
    callback_data JSON COMMENT '回调数据',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_recharge_number (recharge_number),
    INDEX idx_user_id (user_id),
    INDEX idx_payment_status (payment_status),
    INDEX idx_created_at (created_at)
);

-- 退款申请表
CREATE TABLE IF NOT EXISTS refund_applications (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    order_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    reason TEXT NOT NULL,
    status ENUM('pending', 'approved', 'rejected', 'processing', 'completed', 'cancelled') DEFAULT 'pending',
    reject_reason TEXT COMMENT '拒绝原因',
    processor_id VARCHAR(36) COMMENT '处理人ID',
    processed_at TIMESTAMP NULL,
    refund_method VARCHAR(50) COMMENT '退款方式',
    refund_transaction_id VARCHAR(100) COMMENT '退款交易号',
    refund_time TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_id (order_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- 插入默认支付方式（如果不存在）
INSERT IGNORE INTO payment_methods (id, name, code, description, icon_url, sort_order, is_active, config) VALUES
('pay_method_001', '微信支付', 'wechat', '使用微信扫码支付', '/icons/wechat-pay.png', 1, TRUE, '{"min_amount": 0.01, "max_amount": 50000.00, "fee_rate": 0.006, "support_refund": true}'),
('pay_method_002', '支付宝', 'alipay', '使用支付宝扫码支付', '/icons/alipay.png', 2, TRUE, '{"min_amount": 0.01, "max_amount": 50000.00, "fee_rate": 0.006, "support_refund": true}'),
('pay_method_003', '余额支付', 'balance', '使用账户余额支付', '/icons/balance-pay.png', 3, TRUE, '{"min_amount": 0.01, "max_amount": 50000.00, "fee_rate": 0, "support_refund": true}'),
('pay_method_004', '现金支付', 'cash', '线下现金支付', '/icons/cash-pay.png', 4, TRUE, '{"min_amount": 0.01, "max_amount": 10000.00, "fee_rate": 0, "support_refund": false}');

-- 为现有用户创建钱包（如果不存在）
INSERT IGNORE INTO user_wallets (id, user_id, balance, total_recharge, created_at)
SELECT 
    CONCAT('wallet_', REPLACE(u.id, '_', '')),
    u.id,
    CASE 
        WHEN u.id = 'patient_001' THEN 500.00
        WHEN u.id = 'patient_002' THEN 300.00
        WHEN u.id = 'patient_003' THEN 200.00
        ELSE 0.00
    END,
    CASE 
        WHEN u.id = 'patient_001' THEN 500.00
        WHEN u.id = 'patient_002' THEN 300.00
        WHEN u.id = 'patient_003' THEN 200.00
        ELSE 0.00
    END,
    NOW()
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM user_wallets w WHERE w.user_id = u.id
);

-- 插入示例充值记录
INSERT IGNORE INTO recharge_records (id, recharge_number, user_id, wallet_id, amount, payment_method_code, payment_status, paid_amount, paid_time, description) VALUES
('recharge_001', 'RC202603310001', 'patient_001', (SELECT id FROM user_wallets WHERE user_id = 'patient_001'), 500.00, 'wechat', 'paid', 500.00, '2026-03-30 10:00:00', '首次充值'),
('recharge_002', 'RC202603310002', 'patient_002', (SELECT id FROM user_wallets WHERE user_id = 'patient_002'), 300.00, 'alipay', 'paid', 300.00, '2026-03-30 11:30:00', '首次充值'),
('recharge_003', 'RC202603310003', 'patient_003', (SELECT id FROM user_wallets WHERE user_id = 'patient_003'), 200.00, 'balance', 'paid', 200.00, '2026-03-30 12:45:00', '首次充值');

-- 插入示例钱包交易记录
INSERT IGNORE INTO wallet_transactions (id, wallet_id, user_id, transaction_type, amount, balance_before, balance_after, related_id, related_type, description, status) VALUES
('trans_001', (SELECT id FROM user_wallets WHERE user_id = 'patient_001'), 'patient_001', 'recharge', 500.00, 0.00, 500.00, 'recharge_001', 'recharge', '微信充值500元', 'success'),
('trans_002', (SELECT id FROM user_wallets WHERE user_id = 'patient_002'), 'patient_002', 'recharge', 300.00, 0.00, 300.00, 'recharge_002', 'recharge', '支付宝充值300元', 'success'),
('trans_003', (SELECT id FROM user_wallets WHERE user_id = 'patient_003'), 'patient_003', 'recharge', 200.00, 0.00, 200.00, 'recharge_003', 'recharge', '余额充值200元', 'success'),
('trans_004', (SELECT id FROM user_wallets WHERE user_id = 'patient_001'), 'patient_001', 'payment', -600.00, 500.00, -100.00, 'order_001', 'order', '支付订单YB202603310001', 'success'),
('trans_005', (SELECT id FROM user_wallets WHERE user_id = 'patient_003'), 'patient_003', 'payment', -720.00, 200.00, -520.00, 'order_003', 'order', '支付订单YB202603310003', 'success');

-- 插入示例退款申请
INSERT IGNORE INTO refund_applications (id, order_id, user_id, amount, reason, status, created_at) VALUES
('refund_001', 'order_002', 'patient_002', 600.00, '时间冲突，无法就诊', 'pending', '2026-03-30 16:30:00');