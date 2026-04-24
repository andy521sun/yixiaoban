-- 医小伴陪诊APP - 实时通信系统数据库升级
USE yixiaoban;

-- 1. 通话记录表
CREATE TABLE IF NOT EXISTS call_records (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    caller_id VARCHAR(36) NOT NULL COMMENT '呼叫者ID',
    receiver_id VARCHAR(36) NOT NULL COMMENT '接收者ID',
    order_id VARCHAR(36) COMMENT '关联订单ID',
    call_type VARCHAR(20) DEFAULT 'audio' COMMENT '通话类型: audio音频, video视频',
    status VARCHAR(20) DEFAULT 'requested' COMMENT '状态: requested已请求, accepted已接受, rejected已拒绝, ongoing进行中, completed已完成, missed未接听',
    duration_seconds INT DEFAULT 0 COMMENT '通话时长(秒)',
    started_at TIMESTAMP NULL COMMENT '开始时间',
    ended_at TIMESTAMP NULL COMMENT '结束时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_caller (caller_id),
    INDEX idx_receiver (receiver_id),
    INDEX idx_order (order_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) COMMENT='通话记录表';

-- 2. 扩展聊天消息表（如果字段不存在）
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS message_type VARCHAR(20) DEFAULT 'text' COMMENT '消息类型: text文本, image图片, audio语音, video视频, file文件',
ADD COLUMN IF NOT EXISTS file_url VARCHAR(500) COMMENT '文件URL',
ADD COLUMN IF NOT EXISTS file_size INT COMMENT '文件大小(字节)',
ADD COLUMN IF NOT EXISTS duration_seconds INT COMMENT '音频/视频时长(秒)',
ADD COLUMN IF NOT EXISTS thumbnail_url VARCHAR(500) COMMENT '缩略图URL',
ADD COLUMN IF NOT EXISTS read_at TIMESTAMP NULL COMMENT '已读时间',
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP NULL COMMENT '送达时间',
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'sent' COMMENT '状态: sent已发送, delivered已送达, read已读, failed发送失败';

-- 3. 创建索引
CREATE INDEX IF NOT EXISTS idx_chat_sender ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_receiver ON chat_messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_chat_order ON chat_messages(order_id);
CREATE INDEX IF NOT EXISTS idx_chat_status ON chat_messages(status);
CREATE INDEX IF NOT EXISTS idx_chat_created ON chat_messages(created_at);

-- 4. 系统通知表
CREATE TABLE IF NOT EXISTS system_notifications (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    title VARCHAR(200) NOT NULL COMMENT '通知标题',
    content TEXT NOT NULL COMMENT '通知内容',
    notification_type VARCHAR(20) DEFAULT 'info' COMMENT '通知类型: info信息, success成功, warning警告, error错误, order订单, payment支付',
    related_id VARCHAR(36) COMMENT '关联ID(订单ID/支付ID等)',
    related_type VARCHAR(50) COMMENT '关联类型',
    is_read BOOLEAN DEFAULT FALSE COMMENT '是否已读',
    read_at TIMESTAMP NULL COMMENT '已读时间',
    action_url VARCHAR(500) COMMENT '操作链接',
    expires_at TIMESTAMP NULL COMMENT '过期时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_notification_user (user_id),
    INDEX idx_notification_type (notification_type),
    INDEX idx_notification_read (is_read),
    INDEX idx_notification_created (created_at)
) COMMENT='系统通知表';

-- 5. 在线状态记录表
CREATE TABLE IF NOT EXISTS online_status (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    status VARCHAR(20) DEFAULT 'online' COMMENT '状态: online在线, offline离线, away离开, busy忙碌',
    last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '最后活跃时间',
    device_type VARCHAR(50) COMMENT '设备类型: web网页, android安卓, ios苹果',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_device (user_id, device_type(50)),
    INDEX idx_status (status),
    INDEX idx_last_active (last_active_at)
) COMMENT='在线状态记录表';

-- 6. 消息撤回记录表
CREATE TABLE IF NOT EXISTS message_recalls (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    message_id VARCHAR(36) NOT NULL UNIQUE COMMENT '消息ID',
    user_id VARCHAR(36) NOT NULL COMMENT '撤回用户ID',
    recall_reason VARCHAR(255) COMMENT '撤回原因',
    recalled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_recall_user (user_id),
    INDEX idx_recall_time (recalled_at)
) COMMENT='消息撤回记录表';

-- 7. 插入测试聊天消息
INSERT INTO chat_messages (id, sender_id, receiver_id, order_id, content, message_type, status) VALUES
(UUID(), 
 (SELECT id FROM users WHERE phone = '13800138001'),
 (SELECT id FROM users WHERE phone = '13900139001'),
 (SELECT id FROM orders LIMIT 1),
 '您好，我是患者张三，明天需要陪诊服务', 'text', 'read'),
(UUID(),
 (SELECT id FROM users WHERE phone = '13900139001'),
 (SELECT id FROM users WHERE phone = '13800138001'),
 (SELECT id FROM orders LIMIT 1),
 '您好，我是陪诊师李护士，明天我会准时到达', 'text', 'read'),
(UUID(),
 (SELECT id FROM users WHERE phone = '13800138001'),
 (SELECT id FROM users WHERE phone = '13900139001'),
 (SELECT id FROM orders LIMIT 1),
 '请问需要提前准备什么材料吗？', 'text', 'delivered')
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

SELECT '✅ 实时通信系统数据库升级完成' as result;
