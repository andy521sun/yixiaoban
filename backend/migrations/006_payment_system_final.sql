-- 医小伴APP - 支付系统数据库迁移
-- 创建时间：2026年4月19日
-- 最后更新：2026年4月19日

-- 1. 创建支付记录表
CREATE TABLE IF NOT EXISTS payments (
  id VARCHAR(64) PRIMARY KEY COMMENT '支付订单ID',
  order_id VARCHAR(64) NOT NULL COMMENT '关联订单ID',
  payment_method VARCHAR(20) NOT NULL COMMENT '支付方式: wechat/alipay/bank_card/balance',
  amount DECIMAL(10,2) NOT NULL COMMENT '支付金额（元）',
  description VARCHAR(255) COMMENT '支付描述',
  status VARCHAR(20) NOT NULL DEFAULT 'pending' COMMENT '支付状态: pending/processing/success/failed/refunded/refunding/cancelled',
  transaction_id VARCHAR(128) COMMENT '支付渠道交易ID',
  refund_amount DECIMAL(10,2) COMMENT '退款金额',
  refund_reason VARCHAR(255) COMMENT '退款原因',
  paid_at DATETIME COMMENT '支付完成时间',
  refunded_at DATETIME COMMENT '退款完成时间',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_order_id (order_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at),
  INDEX idx_payment_method (payment_method)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付记录表';

-- 2. 更新订单表，添加支付相关字段
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'unpaid' COMMENT '支付状态: unpaid/paid/refunded' AFTER status,
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20) COMMENT '支付方式' AFTER payment_status,
ADD COLUMN IF NOT EXISTS paid_at DATETIME COMMENT '支付时间' AFTER payment_method,
ADD COLUMN IF NOT EXISTS refunded_at DATETIME COMMENT '退款时间' AFTER paid_at;

-- 3. 创建支付统计视图
CREATE OR REPLACE VIEW payment_statistics AS
SELECT 
  DATE(p.created_at) as stat_date,
  p.payment_method,
  COUNT(*) as total_count,
  SUM(p.amount) as total_amount,
  COUNT(CASE WHEN p.status = 'success' THEN 1 END) as success_count,
  SUM(CASE WHEN p.status = 'success' THEN p.amount ELSE 0 END) as success_amount,
  COUNT(CASE WHEN p.status = 'failed' THEN 1 END) as failed_count,
  SUM(CASE WHEN p.status = 'failed' THEN p.amount ELSE 0 END) as failed_amount,
  COUNT(CASE WHEN p.status = 'refunded' THEN 1 END) as refunded_count,
  SUM(CASE WHEN p.status = 'refunded' THEN p.amount ELSE 0 END) as refunded_amount
FROM payments p
GROUP BY DATE(p.created_at), p.payment_method
ORDER BY stat_date DESC;

-- 4. 创建用户支付汇总视图
CREATE OR REPLACE VIEW user_payment_summary AS
SELECT 
  o.user_id,
  u.name as user_name,
  u.phone as user_phone,
  COUNT(DISTINCT p.id) as total_payments,
  SUM(p.amount) as total_amount,
  MAX(p.created_at) as last_payment_date,
  COUNT(DISTINCT CASE WHEN p.status = 'success' THEN p.id END) as success_payments,
  SUM(CASE WHEN p.status = 'success' THEN p.amount ELSE 0 END) as success_amount
FROM payments p
JOIN orders o ON p.order_id = o.id
JOIN users u ON o.user_id = u.id
GROUP BY o.user_id, u.name, u.phone
ORDER BY total_amount DESC;

-- 5. 插入测试支付数据
INSERT INTO payments (id, order_id, payment_method, amount, description, status, transaction_id, created_at) VALUES
('pay_test_001', 'order_001', 'wechat', 300.00, '测试订单支付', 'success', 'trans_wx_001', '2026-04-10 10:30:00'),
('pay_test_002', 'order_002', 'alipay', 450.00, '陪诊服务支付', 'success', 'trans_alipay_001', '2026-04-11 14:20:00'),
('pay_test_003', 'order_003', 'wechat', 200.00, '基础陪诊支付', 'failed', NULL, '2026-04-12 09:15:00'),
('pay_test_004', 'order_004', 'balance', 150.00, '余额支付测试', 'success', 'trans_balance_001', '2026-04-13 16:45:00'),
('pay_test_005', 'order_005', 'alipay', 500.00, '高级陪诊服务', 'success', 'trans_alipay_002', '2026-04-14 11:30:00'),
('pay_test_006', 'order_006', 'wechat', 350.00, '日常陪诊支付', 'pending', NULL, '2026-04-15 13:20:00'),
('pay_test_007', 'order_007', 'bank_card', 280.00, '银行卡支付测试', 'success', 'trans_bank_001', '2026-04-16 15:10:00'),
('pay_test_008', 'order_008', 'alipay', 420.00, '专家陪诊服务', 'refunded', 'trans_alipay_003', '2026-04-17 10:05:00'),
('pay_test_009', 'order_009', 'wechat', 180.00, '快速陪诊支付', 'success', 'trans_wx_002', '2026-04-18 09:40:00'),
('pay_test_010', 'order_010', 'balance', 220.00, '会员余额支付', 'processing', NULL, '2026-04-19 08:30:00');

-- 6. 更新测试订单的支付状态
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

UPDATE orders SET 
  payment_status = 'unpaid'
WHERE id = 'order_006';

UPDATE orders SET 
  payment_status = 'paid',
  payment_method = 'bank_card',
  paid_at = '2026-04-16 15:10:00'
WHERE id = 'order_007';

UPDATE orders SET 
  payment_status = 'refunded',
  payment_method = 'alipay',
  paid_at = '2026-04-17 10:05:00',
  refunded_at = '2026-04-17 14:30:00'
WHERE id = 'order_008';

UPDATE orders SET 
  payment_status = 'paid',
  payment_method = 'wechat',
  paid_at = '2026-04-18 09:40:00'
WHERE id = 'order_009';

UPDATE orders SET 
  payment_status = 'unpaid'
WHERE id = 'order_010';

-- 7. 创建支付状态更新触发器
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS update_order_payment_status
AFTER UPDATE ON payments
FOR EACH ROW
BEGIN
  IF NEW.status = 'success' AND OLD.status != 'success' THEN
    UPDATE orders 
    SET payment_status = 'paid',
        payment_method = NEW.payment_method,
        paid_at = NEW.paid_at,
        updated_at = NOW()
    WHERE id = NEW.order_id;
  END IF;
  
  IF NEW.status = 'refunded' AND OLD.status != 'refunded' THEN
    UPDATE orders 
    SET payment_status = 'refunded',
        refunded_at = NEW.refunded_at,
        updated_at = NOW()
    WHERE id = NEW.order_id;
  END IF;
END$$

DELIMITER ;

-- 8. 创建支付记录审计表
CREATE TABLE IF NOT EXISTS payment_audit_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  payment_id VARCHAR(64) NOT NULL,
  old_status VARCHAR(20),
  new_status VARCHAR(20) NOT NULL,
  changed_by VARCHAR(64) COMMENT '操作人',
  change_reason VARCHAR(255) COMMENT '变更原因',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_payment_id (payment_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付状态变更审计日志';

-- 9. 创建支付状态变更审计触发器
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS audit_payment_status_change
AFTER UPDATE ON payments
FOR EACH ROW
BEGIN
  IF NEW.status != OLD.status THEN
    INSERT INTO payment_audit_log (payment_id, old_status, new_status, changed_by, change_reason)
    VALUES (NEW.id, OLD.status, NEW.status, 'system', '状态自动更新');
  END IF;
END$$

DELIMITER ;

-- 10. 支付系统初始化完成
SELECT '支付系统数据库迁移完成！' as message;

-- 显示创建的表结构
SHOW CREATE TABLE payments;
SHOW CREATE VIEW payment_statistics;
SHOW CREATE VIEW user_payment_summary;