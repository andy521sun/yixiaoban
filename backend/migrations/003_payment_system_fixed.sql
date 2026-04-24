-- 医小伴陪诊APP - 支付系统数据库升级（兼容版本）
-- 创建时间: 2026-03-31

USE yixiaoban;

-- 1. 支付方式表
CREATE TABLE IF NOT EXISTS payment_methods (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(50) NOT NULL COMMENT '支付方式名称',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT '支付方式代码: wechat, alipay, balance, cash',
    description TEXT COMMENT '描述',
    icon_url VARCHAR(255) COMMENT '图标URL',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否启用',
    sort_order INT DEFAULT 0 COMMENT '排序',
    config JSON COMMENT '支付配置(JSON格式)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT='支付方式表';

CREATE INDEX idx_code ON payment_methods(code);
CREATE INDEX idx_active ON payment_methods(is_active);

-- 2. 检查并添加支付记录表字段
ALTER TABLE payments 
ADD COLUMN payment_method_code VARCHAR(20) COMMENT '支付方式代码',
ADD COLUMN trade_no VARCHAR(64) UNIQUE COMMENT '第三方交易号',
ADD COLUMN prepay_id VARCHAR(64) COMMENT '预支付ID(微信)',
ADD COLUMN payment_url TEXT COMMENT '支付链接',
ADD COLUMN qr_code_url TEXT COMMENT '二维码URL',
ADD COLUMN callback_data JSON COMMENT '回调数据',
ADD COLUMN refund_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT '退款金额',
ADD COLUMN refund_reason VARCHAR(255) COMMENT '退款原因',
ADD COLUMN refunded_at TIMESTAMP NULL COMMENT '退款时间',
ADD COLUMN notify_url VARCHAR(255) COMMENT '回调通知URL';

CREATE INDEX idx_trade_no ON payments(trade_no);
CREATE INDEX idx_payment_method ON payments(payment_method_code);
CREATE INDEX idx_refund_status ON payments(refund_amount);

-- 3. 用户钱包表
CREATE TABLE IF NOT EXISTS user_wallets (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    balance DECIMAL(10,2) DEFAULT 0.00 COMMENT '余额',
    frozen_amount DECIMAL(10,2) DEFAULT 0.00 COMMENT '冻结金额',
    total_recharge DECIMAL(10,2) DEFAULT 0.00 COMMENT '累计充值',
    total_withdraw DECIMAL(10,2) DEFAULT 0.00 COMMENT '累计提现',
    total_consumption DECIMAL(10,2) DEFAULT 0.00 COMMENT '累计消费',
    last_transaction_at TIMESTAMP NULL COMMENT '最后交易时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) COMMENT='用户钱包表';

CREATE INDEX idx_balance ON user_wallets(balance);
CREATE INDEX idx_user ON user_wallets(user_id);

-- 4. 钱包交易流水表
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    wallet_id VARCHAR(36) NOT NULL COMMENT '钱包ID',
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    transaction_type VARCHAR(20) NOT NULL COMMENT '交易类型: recharge充值, consume消费, refund退款, withdraw提现, freeze冻结, unfreeze解冻',
    amount DECIMAL(10,2) NOT NULL COMMENT '交易金额',
    balance_before DECIMAL(10,2) NOT NULL COMMENT '交易前余额',
    balance_after DECIMAL(10,2) NOT NULL COMMENT '交易后余额',
    related_id VARCHAR(36) COMMENT '关联ID(订单ID/支付ID等)',
    related_type VARCHAR(50) COMMENT '关联类型: order, payment等',
    description VARCHAR(255) COMMENT '交易描述',
    status VARCHAR(20) DEFAULT 'completed' COMMENT '状态: pending处理中, completed已完成, failed失败, cancelled已取消',
    remark TEXT COMMENT '备注',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (wallet_id) REFERENCES user_wallets(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) COMMENT='钱包交易流水表';

CREATE INDEX idx_user_transaction ON wallet_transactions(user_id, transaction_type);
CREATE INDEX idx_created_at ON wallet_transactions(created_at);
CREATE INDEX idx_related ON wallet_transactions(related_type, related_id);

-- 5. 充值记录表
CREATE TABLE IF NOT EXISTS recharge_records (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    amount DECIMAL(10,2) NOT NULL COMMENT '充值金额',
    payment_method_code VARCHAR(20) NOT NULL COMMENT '支付方式',
    trade_no VARCHAR(64) UNIQUE COMMENT '交易号',
    status VARCHAR(20) DEFAULT 'pending' COMMENT '状态: pending待支付, paid已支付, failed支付失败, cancelled已取消',
    payment_data JSON COMMENT '支付数据',
    completed_at TIMESTAMP NULL COMMENT '完成时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) COMMENT='充值记录表';

CREATE INDEX idx_user_status ON recharge_records(user_id, status);
CREATE INDEX idx_trade_no ON recharge_records(trade_no);
CREATE INDEX idx_created_at ON recharge_records(created_at);

-- 6. 退款申请表
CREATE TABLE IF NOT EXISTS refund_applications (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    order_id VARCHAR(36) NOT NULL COMMENT '订单ID',
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    amount DECIMAL(10,2) NOT NULL COMMENT '申请退款金额',
    reason TEXT NOT NULL COMMENT '退款原因',
    status VARCHAR(20) DEFAULT 'pending' COMMENT '状态: pending待处理, approved已批准, rejected已拒绝, completed已完成',
    admin_remark TEXT COMMENT '管理员备注',
    processed_by VARCHAR(36) COMMENT '处理人ID',
    processed_at TIMESTAMP NULL COMMENT '处理时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) COMMENT='退款申请表';

CREATE INDEX idx_order ON refund_applications(order_id);
CREATE INDEX idx_status ON refund_applications(status);
CREATE INDEX idx_created_at ON refund_applications(created_at);

-- 插入初始支付方式数据
INSERT INTO payment_methods (id, name, code, description, icon_url, is_active, sort_order, config) VALUES
(UUID(), '微信支付', 'wechat', '使用微信扫码支付', '/static/icons/wechat.png', TRUE, 1, '{"app_id": "wx_test_appid", "mch_id": "wx_test_mchid", "notify_url": "/api/payment/wechat/notify"}'),
(UUID(), '支付宝', 'alipay', '使用支付宝扫码支付', '/static/icons/alipay.png', TRUE, 2, '{"app_id": "alipay_test_appid", "gateway": "https://openapi.alipay.com/gateway.do", "notify_url": "/api/payment/alipay/notify"}'),
(UUID(), '余额支付', 'balance', '使用账户余额支付', '/static/icons/balance.png', TRUE, 3, '{"min_amount": 0.01, "max_amount": 10000}'),
(UUID(), '现金支付', 'cash', '线下现金支付', '/static/icons/cash.png', TRUE, 4, '{"need_confirm": true}'),
(UUID(), '银行卡支付', 'bankcard', '银行卡支付', '/static/icons/bankcard.png', FALSE, 5, '{}');

-- 为用户创建钱包
INSERT IGNORE INTO user_wallets (id, user_id, balance, total_recharge, total_consumption)
SELECT 
    UUID(),
    id,
    1000.00, -- 初始测试余额
    1000.00,
    0.00
FROM users 
WHERE phone IN ('13800138001', '13900139001', '13800000000');

-- 更新现有支付记录
UPDATE payments SET payment_method_code = 'balance' WHERE payment_method = 'balance';
UPDATE payments SET payment_method_code = 'cash' WHERE payment_method = 'cash';

-- 添加系统配置
INSERT INTO system_configs (config_key, config_value, description, is_public) VALUES
('payment_enabled', 'true', '是否启用支付功能', true),
('min_recharge_amount', '10.00', '最小充值金额', true),
('max_recharge_amount', '5000.00', '最大充值金额', true),
('auto_refund_days', '7', '自动退款天数', false),
('payment_timeout_minutes', '30', '支付超时时间(分钟)', false),
('refund_processing_days', '3', '退款处理天数', true)
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

SELECT '✅ 支付系统数据库升级完成' AS message;