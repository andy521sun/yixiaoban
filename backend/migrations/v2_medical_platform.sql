-- =============================================
-- 医小伴 v2.0 在线医疗平台 数据库迁移脚本
-- =============================================

-- 1. 扩展 users 表角色
ALTER TABLE users 
  MODIFY COLUMN role ENUM('patient','companion','admin','doctor') NOT NULL DEFAULT 'patient',
  ADD COLUMN title VARCHAR(100) DEFAULT NULL COMMENT '职称' AFTER role,
  ADD COLUMN hospital_affiliation VARCHAR(200) DEFAULT NULL COMMENT '所属医院' AFTER title,
  ADD COLUMN department VARCHAR(100) DEFAULT NULL COMMENT '科室' AFTER hospital_affiliation,
  ADD COLUMN license_number VARCHAR(100) DEFAULT NULL COMMENT '执业医师编号' AFTER department,
  ADD COLUMN is_verified TINYINT(1) DEFAULT 0 COMMENT '身份认证' AFTER license_number;

-- 2. 医生认证信息表
CREATE TABLE IF NOT EXISTS doctor_certifications (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id VARCHAR(36) NOT NULL,
  real_name VARCHAR(100) NOT NULL,
  id_card VARCHAR(20) DEFAULT NULL,
  practice_license VARCHAR(500) DEFAULT NULL,
  qualification_cert VARCHAR(500) DEFAULT NULL,
  hospital_cert VARCHAR(500) DEFAULT NULL,
  hospital_name VARCHAR(200) DEFAULT NULL,
  department VARCHAR(100) DEFAULT NULL,
  title VARCHAR(100) DEFAULT NULL,
  specialty TEXT,
  introduction TEXT,
  status ENUM('pending','approved','rejected') DEFAULT 'pending',
  reject_reason TEXT,
  reviewed_by VARCHAR(36) DEFAULT NULL,
  reviewed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 问诊记录表
CREATE TABLE IF NOT EXISTS consultations (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  order_id VARCHAR(36) DEFAULT NULL,
  patient_id VARCHAR(36) NOT NULL,
  doctor_id VARCHAR(36) DEFAULT NULL,
  consult_type ENUM('text','image','video') NOT NULL DEFAULT 'text',
  chief_complaint TEXT,
  present_illness TEXT,
  past_history TEXT,
  status ENUM('waiting','accepted','in_progress','completed','cancelled') DEFAULT 'waiting',
  severity ENUM('normal','urgent','emergency') DEFAULT 'normal',
  diagnosis TEXT,
  advice TEXT,
  patient_rated TINYINT(1) DEFAULT 0,
  patient_rating INT DEFAULT NULL,
  patient_review TEXT,
  started_at TIMESTAMP NULL,
  completed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_patient (patient_id),
  INDEX idx_doctor (doctor_id),
  INDEX idx_status (status),
  INDEX idx_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 问诊消息表
CREATE TABLE IF NOT EXISTS consultation_messages (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  consultation_id VARCHAR(36) NOT NULL,
  sender_id VARCHAR(36) NOT NULL,
  sender_role ENUM('patient','doctor','system') NOT NULL,
  msg_type ENUM('text','image','voice','file','system') DEFAULT 'text',
  content TEXT,
  media_url VARCHAR(500) DEFAULT NULL,
  media_thumbnail VARCHAR(500) DEFAULT NULL,
  file_name VARCHAR(255) DEFAULT NULL,
  file_size INT DEFAULT NULL,
  is_read TINYINT(1) DEFAULT 0,
  read_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_consultation (consultation_id),
  INDEX idx_sender (sender_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. 处方表
CREATE TABLE IF NOT EXISTS prescriptions (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  consultation_id VARCHAR(36) NOT NULL,
  order_id VARCHAR(36) DEFAULT NULL,
  doctor_id VARCHAR(36) NOT NULL,
  patient_id VARCHAR(36) NOT NULL,
  diagnosis TEXT,
  notes TEXT,
  status ENUM('draft','signed','dispensed','cancelled') DEFAULT 'draft',
  doctor_signature VARCHAR(500) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_consultation (consultation_id),
  INDEX idx_doctor (doctor_id),
  INDEX idx_patient (patient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. 处方明细表
CREATE TABLE IF NOT EXISTS prescription_items (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  prescription_id VARCHAR(36) NOT NULL,
  drug_name VARCHAR(200) NOT NULL,
  specification VARCHAR(200) DEFAULT NULL,
  dosage VARCHAR(100) DEFAULT NULL,
  frequency VARCHAR(100) DEFAULT NULL,
  duration VARCHAR(100) DEFAULT NULL,
  quantity INT DEFAULT 1,
  unit VARCHAR(20) DEFAULT '盒',
  remark TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_prescription (prescription_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. 会诊房间表
CREATE TABLE IF NOT EXISTS consultation_rooms (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  consultation_id VARCHAR(36) NOT NULL,
  room_type ENUM('single','multi') DEFAULT 'single',
  status ENUM('active','completed') DEFAULT 'active',
  created_by VARCHAR(36) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_consultation (consultation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. 会诊参与人表
CREATE TABLE IF NOT EXISTS consultation_participants (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  room_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  role ENUM('host','participant','observer') DEFAULT 'participant',
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  left_at TIMESTAMP NULL,
  UNIQUE KEY uk_room_user (room_id, user_id),
  INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. 提现申请表
CREATE TABLE IF NOT EXISTS withdraw_requests (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id VARCHAR(36) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  fee DECIMAL(10,2) DEFAULT 0.00,
  actual_amount DECIMAL(10,2) NOT NULL,
  bank_name VARCHAR(100) DEFAULT NULL,
  bank_card VARCHAR(50) DEFAULT NULL,
  account_name VARCHAR(100) DEFAULT NULL,
  status ENUM('pending','approved','rejected','completed') DEFAULT 'pending',
  reject_reason TEXT,
  reviewed_by VARCHAR(36) DEFAULT NULL,
  reviewed_at TIMESTAMP NULL,
  completed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user (user_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. 内容审核表
CREATE TABLE IF NOT EXISTS content_reports (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  reporter_id VARCHAR(36) NOT NULL,
  content_type ENUM('consultation_message','review','comment','image','other') NOT NULL,
  content_id VARCHAR(36) NOT NULL,
  reason TEXT,
  status ENUM('pending','approved','dismissed') DEFAULT 'pending',
  action_taken TEXT,
  reviewed_by VARCHAR(36) DEFAULT NULL,
  reviewed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_status (status),
  INDEX idx_content (content_type, content_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. 扩展系统通知表
ALTER TABLE system_notifications
  ADD COLUMN notification_type ENUM('system','order','consultation','withdraw','review') DEFAULT 'system' AFTER id,
  ADD COLUMN related_id VARCHAR(36) DEFAULT NULL AFTER notification_type;

-- 12. 医生服务价格配置
CREATE TABLE IF NOT EXISTS doctor_service_pricing (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  doctor_id VARCHAR(36) NOT NULL,
  service_type ENUM('text_consult','image_consult','video_consult','phone_consult') NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_doctor_service (doctor_id, service_type),
  INDEX idx_doctor (doctor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入默认价格
INSERT INTO doctor_service_pricing (doctor_id, service_type, price)
SELECT c.id, 'text_consult', 50.00 FROM companions c
UNION ALL
SELECT c.id, 'image_consult', 80.00 FROM companions c
UNION ALL
SELECT c.id, 'video_consult', 150.00 FROM companions c;

-- 更新配置
REPLACE INTO system_configs (config_key, config_value, description)
VALUES ('app_version', '2.0.0', '应用版本'),
       ('app_name', '医小伴在线医疗', '应用名称'),
       ('platform_type', 'online_medical', '平台类型');
