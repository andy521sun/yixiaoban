-- 简单支付系统升级
USE yixiaoban;

-- 1. 支付方式表（如果不存在）
CREATE TABLE IF NOT EXISTS payment_methods (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(50) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    description TEXT,
    icon_url VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    config JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. 添加支付记录字段
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS payment_method_code VARCHAR(20),
ADD COLUMN IF NOT EXISTS trade_no VARCHAR(64),
ADD COLUMN IF NOT EXISTS prepay_id VARCHAR(64),
ADD COLUMN IF NOT EXISTS payment_url TEXT,
ADD COLUMN IF NOT EXISTS qr_code_url TEXT,
ADD COLUMN IF NOT EXISTS callback_data JSON,
ADD COLUMN IF NOT EXISTS refund_amount DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS refund_reason VARCHAR(255),
ADD COLUMN IF NOT EXISTS refunded_at TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS notify_url VARCHAR(255);

-- 3. 用户钱包表
CREATE TABLE IF NOT EXISTS user_wallets (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL UNIQUE,
    balance DECIMAL(10,2) DEFAULT 0.00,
    frozen_amount DECIMAL(10,2) DEFAULT 0.00,
    total_recharge DECIMAL(10,2) DEFAULT 0.00,
    total_withdraw DECIMAL(10,2) DEFAULT 0.00,
    total_consumption DECIMAL(10,2) DEFAULT 0.00,
    last_transaction_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 4. 插入支付方式
INSERT IGNORE INTO payment_methods (name, code, description, is_active, sort_order) VALUES
('微信支付', 'wechat', '使用微信扫码支付', TRUE, 1),
('支付宝', 'alipay', '使用支付宝扫码支付', TRUE, 2),
('余额支付', 'balance', '使用账户余额支付', TRUE, 3),
('现金支付', 'cash', '线下现金支付', TRUE, 4);

-- 5. 为用户创建钱包
INSERT IGNORE INTO user_wallets (user_id, balance, total_recharge)
SELECT id, 1000.00, 1000.00 FROM users 
WHERE phone IN ('13800138001', '13900139001', '13800000000');

SELECT '支付系统升级完成' as result;
