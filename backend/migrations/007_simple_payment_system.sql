-- 医小伴APP - 简化支付系统迁移
-- 创建时间：2026年4月19日

-- 1. 创建支付记录表
CREATE TABLE IF NOT EXISTS payments (
  id VARCHAR(64) PRIMARY KEY,
  order_id VARCHAR(64) NOT NULL,
  payment_method VARCHAR(20) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  description VARCHAR(255),
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  transaction_id VARCHAR(128),
  refund_amount DECIMAL(10,2),
  refund_reason VARCHAR(255),
  paid_at DATETIME,
  refunded_at DATETIME,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_order_id (order_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
);

-- 2. 检查并添加订单表的支付字段
ALTER TABLE orders 
ADD COLUMN payment_status VARCHAR(20) DEFAULT 'unpaid',
ADD COLUMN payment_method VARCHAR(20),
ADD COLUMN paid_at DATETIME,
ADD COLUMN refunded_at DATETIME;

-- 3. 插入测试支付数据
INSERT INTO payments (id, order_id, payment_method, amount, description, status, transaction_id, created_at) VALUES
('pay_001', 'order_001', 'wechat', 300.00, '测试订单支付', 'success', 'trans_001', '2026-04-10 10:30:00'),
('pay_002', 'order_002', 'alipay', 450.00, '陪诊服务支付', 'success', 'trans_002', '2026-04-11 14:20:00'),
('pay_003', 'order_003', 'wechat', 200.00, '基础陪诊支付', 'failed', NULL, '2026-04-12 09:15:00'),
('pay_004', 'order_004', 'balance', 150.00, '余额支付测试', 'success', 'trans_004', '2026-04-13 16:45:00'),
('pay_005', 'order_005', 'alipay', 500.00, '高级陪诊服务', 'success', 'trans_005', '2026-04-14 11:30:00');

-- 4. 更新测试订单的支付状态
UPDATE orders SET 
  payment_status = 'paid',
  payment_method = 'wechat',
  paid_at = '2026-04-10 10:30:00'
WHERE id = 'order_001';

UPDATE orders SET 
  payment_status = 'paid',
  payment_method = 'alipay',
  paid_at = '2026-04-11 14:20:00'
WHERE id = 'order_002';

UPDATE orders SET 
  payment_status = 'unpaid'
WHERE id = 'order_003';

UPDATE orders SET 
  payment_status = 'paid',
  payment_method = 'balance',
  paid_at = '2026-04-13 16:45:00'
WHERE id = 'order_004';

UPDATE orders SET 
  payment_status = 'paid',
  payment_method = 'alipay',
  paid_at = '2026-04-14 11:30:00'
WHERE id = 'order_005';

-- 5. 显示创建结果
SELECT '支付系统表创建完成！' as message;
SELECT COUNT(*) as payment_count FROM payments;
SELECT COUNT(*) as order_count FROM orders WHERE payment_status = 'paid';