ALTER DATABASE yixiaoban CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- 初始化SQL - 医小伴
-- MySQL dump 10.13  Distrib 8.0.45, for Linux (x86_64)
--
-- Host: localhost    Database: yixiaoban
-- ------------------------------------------------------
-- Server version	8.0.45-0ubuntu0.24.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `call_records`
--

DROP TABLE IF EXISTS `call_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `call_records` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `caller_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '呼叫者ID',
  `receiver_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '接收者ID',
  `order_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '关联订单ID',
  `call_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'audio' COMMENT '通话类型: audio音频, video视频',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'requested' COMMENT '状态: requested已请求, accepted已接受, rejected已拒绝, ongoing进行中, completed已完成, missed未接听',
  `duration_seconds` int DEFAULT '0' COMMENT '通话时长(秒)',
  `started_at` timestamp NULL DEFAULT NULL COMMENT '开始时间',
  `ended_at` timestamp NULL DEFAULT NULL COMMENT '结束时间',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_caller` (`caller_id`),
  KEY `idx_receiver` (`receiver_id`),
  KEY `idx_order` (`order_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通话记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `chat_messages`
--

DROP TABLE IF EXISTS `chat_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chat_messages` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `order_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sender_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receiver_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message_type` enum('text','image','voice','file','location') COLLATE utf8mb4_unicode_ci DEFAULT 'text',
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `media_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_sender_id` (`sender_id`),
  KEY `idx_receiver_id` (`receiver_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `chat_messages_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chat_messages_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chat_messages_ibfk_3` FOREIGN KEY (`receiver_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `companions`
--

DROP TABLE IF EXISTS `companions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `companions` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `user_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `real_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_card` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `experience_years` int DEFAULT '0',
  `specialty` text COLLATE utf8mb4_unicode_ci COMMENT '擅长领域，JSON格式',
  `certification_number` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `certification_image` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `introduction` text COLLATE utf8mb4_unicode_ci,
  `service_count` int DEFAULT '0',
  `average_rating` decimal(3,2) DEFAULT '5.00',
  `hourly_rate` decimal(8,2) NOT NULL,
  `is_available` tinyint(1) DEFAULT '1',
  `is_certified` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_is_available` (`is_available`),
  KEY `idx_is_certified` (`is_certified`),
  CONSTRAINT `companions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `departments`
--

DROP TABLE IF EXISTS `departments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `departments` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `hospital_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `floor` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `room_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_hospital_id` (`hospital_id`),
  KEY `idx_name` (`name`),
  CONSTRAINT `departments_ibfk_1` FOREIGN KEY (`hospital_id`) REFERENCES `hospitals` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hospitals`
--

DROP TABLE IF EXISTS `hospitals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hospitals` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `level` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '医院等级：三甲、三乙等',
  `address` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `province` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`),
  KEY `idx_city` (`city`),
  KEY `idx_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `message_recalls`
--

DROP TABLE IF EXISTS `message_recalls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `message_recalls` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `recall_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recalled_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `message_id` (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `online_status`
--

DROP TABLE IF EXISTS `online_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `online_status` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'online',
  `last_active_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `device_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `operation_logs`
--

DROP TABLE IF EXISTS `operation_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `operation_logs` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `user_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_type` enum('patient','companion','admin','system') COLLATE utf8mb4_unicode_ci NOT NULL,
  `operation_type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `target_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `request_method` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `request_url` text COLLATE utf8mb4_unicode_ci,
  `request_params` text COLLATE utf8mb4_unicode_ci,
  `response_status` int DEFAULT NULL,
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `duration_ms` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_operation_type` (`operation_type`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `order_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '订单号，格式：YB202603310001',
  `patient_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `companion_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hospital_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `department_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `appointment_date` date NOT NULL,
  `appointment_time` time NOT NULL,
  `service_type` enum('accompany','consult','report','other') COLLATE utf8mb4_unicode_ci DEFAULT 'accompany',
  `service_hours` int DEFAULT '2',
  `symptoms_description` text COLLATE utf8mb4_unicode_ci,
  `special_requirements` text COLLATE utf8mb4_unicode_ci,
  `status` enum('pending','confirmed','in_progress','completed','cancelled','refunded') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `total_amount` decimal(10,2) NOT NULL,
  `paid_amount` decimal(10,2) DEFAULT '0.00',
  `payment_status` enum('unpaid','paid','refunded') COLLATE utf8mb4_unicode_ci DEFAULT 'unpaid',
  `payment_method` enum('wechat','alipay','balance','cash') COLLATE utf8mb4_unicode_ci DEFAULT 'wechat',
  `payment_time` timestamp NULL DEFAULT NULL,
  `patient_rating` int DEFAULT NULL,
  `patient_comment` text COLLATE utf8mb4_unicode_ci,
  `companion_rating` int DEFAULT NULL,
  `companion_comment` text COLLATE utf8mb4_unicode_ci,
  `cancel_reason` text COLLATE utf8mb4_unicode_ci,
  `cancelled_by` enum('patient','companion','system','admin') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `completed_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `order_number` (`order_number`),
  KEY `hospital_id` (`hospital_id`),
  KEY `department_id` (`department_id`),
  KEY `idx_order_number` (`order_number`),
  KEY `idx_patient_id` (`patient_id`),
  KEY `idx_companion_id` (`companion_id`),
  KEY `idx_status` (`status`),
  KEY `idx_appointment_date` (`appointment_date`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`companion_id`) REFERENCES `companions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`hospital_id`) REFERENCES `hospitals` (`id`) ON DELETE CASCADE,
  CONSTRAINT `orders_ibfk_4` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `orders_chk_1` CHECK (((`patient_rating` >= 1) and (`patient_rating` <= 5))),
  CONSTRAINT `orders_chk_2` CHECK (((`companion_rating` >= 1) and (`companion_rating` <= 5)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payment_methods`
--

DROP TABLE IF EXISTS `payment_methods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_methods` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '支付方式名称',
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '支付方式代码: wechat, alipay, balance, cash',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '描述',
  `icon_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '图标URL',
  `is_active` tinyint(1) DEFAULT '1' COMMENT '是否启用',
  `sort_order` int DEFAULT '0' COMMENT '排序',
  `config` json DEFAULT NULL COMMENT '支付配置(JSON格式)',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `idx_code` (`code`),
  KEY `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付方式表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `order_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payment_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` enum('wechat','alipay','balance','cash') COLLATE utf8mb4_unicode_ci NOT NULL,
  `payment_status` enum('pending','success','failed','refunded') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `transaction_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '第三方支付交易号',
  `payer_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payer_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payer_account` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `receiver_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receiver_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `receiver_account` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payment_time` timestamp NULL DEFAULT NULL,
  `refund_time` timestamp NULL DEFAULT NULL,
  `refund_amount` decimal(10,2) DEFAULT '0.00',
  `refund_reason` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `payment_method_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `payment_number` (`payment_number`),
  KEY `payer_id` (`payer_id`),
  KEY `receiver_id` (`receiver_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_payment_number` (`payment_number`),
  KEY `idx_payment_status` (`payment_status`),
  KEY `idx_payment_time` (`payment_time`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`payer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `payments_ibfk_3` FOREIGN KEY (`receiver_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `recharge_records`
--

DROP TABLE IF EXISTS `recharge_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recharge_records` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `recharge_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '充值单号',
  `user_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `wallet_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '支付方式代码',
  `payment_status` enum('pending','paid','failed','cancelled') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `transaction_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '第三方交易号',
  `paid_amount` decimal(10,2) DEFAULT NULL COMMENT '实际支付金额',
  `paid_time` timestamp NULL DEFAULT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `callback_data` json DEFAULT NULL COMMENT '回调数据',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `recharge_number` (`recharge_number`),
  KEY `idx_recharge_number` (`recharge_number`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_payment_status` (`payment_status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `refund_applications`
--

DROP TABLE IF EXISTS `refund_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refund_applications` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `order_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `reason` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','approved','rejected','processing','completed','cancelled') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `reject_reason` text COLLATE utf8mb4_unicode_ci COMMENT '拒绝原因',
  `processor_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '处理人ID',
  `processed_at` timestamp NULL DEFAULT NULL,
  `refund_method` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '退款方式',
  `refund_transaction_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '退款交易号',
  `refund_time` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `refund_records`
--

DROP TABLE IF EXISTS `refund_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refund_records` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payment_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `order_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `refund_amount` decimal(10,2) NOT NULL,
  `refund_reason` text COLLATE utf8mb4_unicode_ci,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'pending' COMMENT 'pending待处理, processing处理中, completed已完成, failed失败',
  `processed_by` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '处理人ID',
  `processed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_payment` (`payment_id`),
  KEY `idx_order` (`order_id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `system_configs`
--

DROP TABLE IF EXISTS `system_configs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_configs` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `config_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `config_value` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_public` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_key` (`config_key`),
  KEY `idx_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `system_notifications`
--

DROP TABLE IF EXISTS `system_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_notifications` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `notification_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'info',
  `related_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `related_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `read_at` timestamp NULL DEFAULT NULL,
  `action_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_wallets`
--

DROP TABLE IF EXISTS `user_wallets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_wallets` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `user_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `balance` decimal(10,2) DEFAULT '0.00',
  `frozen_amount` decimal(10,2) DEFAULT '0.00',
  `total_recharge` decimal(10,2) DEFAULT '0.00',
  `total_withdraw` decimal(10,2) DEFAULT '0.00',
  `total_consumption` decimal(10,2) DEFAULT '0.00',
  `last_transaction_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `avatar_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender` enum('male','female','other') COLLATE utf8mb4_unicode_ci DEFAULT 'other',
  `birth_date` date DEFAULT NULL,
  `id_card` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `emergency_contact` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `emergency_phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` enum('patient','companion','admin') COLLATE utf8mb4_unicode_ci DEFAULT 'patient',
  `status` enum('active','inactive','banned') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `balance` decimal(10,2) DEFAULT '0.00',
  `rating` decimal(3,2) DEFAULT '5.00',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone` (`phone`),
  KEY `idx_phone` (`phone`),
  KEY `idx_role` (`role`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wallet_transactions`
--

DROP TABLE IF EXISTS `wallet_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wallet_transactions` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `wallet_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `transaction_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'recharge充值, consume消费, refund退款, adjustment调整',
  `amount` decimal(10,2) NOT NULL,
  `balance_before` decimal(10,2) NOT NULL,
  `balance_after` decimal(10,2) NOT NULL,
  `related_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '关联ID',
  `related_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '关联类型',
  `description` text COLLATE utf8mb4_unicode_ci,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'completed' COMMENT 'pending待处理, completed已完成, failed失败',
  `admin_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '管理员ID（如果是管理员操作）',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_wallet` (`wallet_id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_type` (`transaction_type`),
  KEY `idx_related` (`related_id`,`related_type`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- 初始化数据库结构完成
-- MySQL dump 10.13  Distrib 8.0.45, for Linux (x86_64)
--
-- Host: localhost    Database: yixiaoban
-- ------------------------------------------------------
-- Server version	8.0.45-0ubuntu0.24.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping data for table `companions`
--

LOCK TABLES `companions` WRITE;
/*!40000 ALTER TABLE `companions` DISABLE KEYS */;
INSERT INTO `companions` (`id`, `user_id`, `real_name`, `id_card`, `experience_years`, `specialty`, `certification_number`, `certification_image`, `introduction`, `service_count`, `average_rating`, `hourly_rate`, `is_available`, `is_certified`, `created_at`, `updated_at`) VALUES ('comp_001','companion_user_001','张美丽','310101198505151234',5,'[\"内科陪诊\",\"老年陪护\",\"报告解读\"]','CERT2024001',NULL,'拥有5年陪诊经验，擅长内科疾病陪诊和老年患者陪护，耐心细致，服务周到。',128,4.80,200.00,1,1,'2026-03-30 23:58:39','2026-04-24 16:27:40'),('comp_002','companion_user_002','李建国','310101197808221235',8,'[\"全科陪诊\", \"报告解读\", \"医患沟通\"]','CERT2024002',NULL,'原三甲医院医生，8年临床经验，精通医学术语，能有效协助医患沟通。',256,4.90,300.00,1,1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('comp_003','companion_user_003','王秀英','310101196503101236',3,'[\"妇产科陪诊\", \"儿科陪护\", \"心理疏导\"]','CERT2024003',NULL,'3年陪诊经验，特别擅长妇产科和儿科陪诊，善于与患者沟通，提供心理支持。',89,4.70,180.00,0,1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('comp_1777050461508','companion_user_1777050461499','andy',NULL,1,'[\"hjkkkkk\"]',NULL,NULL,'hjkkk',0,5.00,200.00,1,1,'2026-04-24 17:07:41','2026-04-24 17:07:41');
/*!40000 ALTER TABLE `companions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `hospitals`
--

LOCK TABLES `hospitals` WRITE;
/*!40000 ALTER TABLE `hospitals` DISABLE KEYS */;
INSERT INTO `hospitals` (`id`, `name`, `level`, `address`, `province`, `city`, `district`, `phone`, `description`, `latitude`, `longitude`, `is_active`, `created_at`, `updated_at`) VALUES ('hosp_001','上海市第一人民医院','三甲','上海市虹口区武进路85号','上海','上海','虹口区','021-63240090','上海市第一人民医院是上海市属大型综合性三级甲等医院，创建于1864年，是上海最早建立的西医医院之一。',NULL,NULL,1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('hosp_002','华山医院','三甲','上海市静安区乌鲁木齐中路12号','上海','上海','静安区','021-62489999','复旦大学附属华山医院是卫生部直属医院，是中国最著名的医院之一，以神经外科、皮肤科、感染科闻名。',NULL,NULL,1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('hosp_003','瑞金医院','三甲','上海市黄浦区瑞金二路197号','上海','上海','黄浦区','021-64370045','上海交通大学医学院附属瑞金医院是一所集医疗、教学、科研为一体的三级甲等综合性医院，以内分泌科、血液科著称。',NULL,NULL,1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('hosp_004','中山医院','三甲','上海市徐汇区枫林路180号','上海','上海','徐汇区','021-64041990','复旦大学附属中山医院是上海市第一批三级甲等医院，以心血管病、肝肿瘤、呼吸病诊治为特色。',NULL,NULL,1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('hosp_005','仁济医院','三甲','上海市浦东新区浦建路160号','上海','上海','浦东新区','021-58752345','上海交通大学医学院附属仁济医院是上海开埠后第一所西医医院，以消化内科、风湿免疫科、泌尿外科闻名。',NULL,NULL,1,'2026-03-30 23:58:39','2026-03-30 23:58:39');
/*!40000 ALTER TABLE `hospitals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `departments`
--

LOCK TABLES `departments` WRITE;
/*!40000 ALTER TABLE `departments` DISABLE KEYS */;
INSERT INTO `departments` (`id`, `hospital_id`, `name`, `description`, `floor`, `room_number`, `phone`, `is_active`, `created_at`, `updated_at`) VALUES ('dept_001','hosp_001','内科','综合性内科，擅长各种常见病、多发病的诊治','2楼','201-210','021-63240091',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_002','hosp_001','外科','普外科、骨科、神经外科等','3楼','301-315','021-63240092',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_003','hosp_001','妇产科','妇科、产科、计划生育科','4楼','401-410','021-63240093',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_004','hosp_001','儿科','儿童内科、儿童外科、新生儿科','5楼','501-508','021-63240094',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_005','hosp_001','眼科','眼科疾病诊治、白内障手术等','6楼','601-605','021-63240095',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_006','hosp_002','神经内科','神经系统疾病诊治，擅长脑血管病、癫痫等','3楼','301-310','021-62489991',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_007','hosp_002','皮肤科','皮肤病、性病诊治，皮肤美容','4楼','401-408','021-62489992',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_008','hosp_002','感染科','传染病、发热性疾病诊治','5楼','501-505','021-62489993',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_009','hosp_002','骨科','创伤骨科、关节外科、脊柱外科','6楼','601-610','021-62489994',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_010','hosp_002','康复科','物理治疗、作业治疗、言语治疗','7楼','701-705','021-62489995',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_011','hosp_003','内分泌科','糖尿病、甲状腺疾病、骨质疏松等','3楼','301-308','021-64370046',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_012','hosp_003','血液科','白血病、淋巴瘤、贫血等血液病','4楼','401-406','021-64370047',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_013','hosp_003','消化科','胃肠疾病、肝病、胰腺疾病','5楼','501-508','021-64370048',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_014','hosp_003','呼吸科','哮喘、慢阻肺、肺炎等呼吸系统疾病','6楼','601-605','021-64370049',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('dept_015','hosp_003','心血管科','冠心病、高血压、心律失常等','7楼','701-708','021-64370050',1,'2026-03-30 23:58:39','2026-03-30 23:58:39');
/*!40000 ALTER TABLE `departments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` (`id`, `phone`, `password_hash`, `name`, `avatar_url`, `gender`, `birth_date`, `id_card`, `emergency_contact`, `emergency_phone`, `role`, `status`, `balance`, `rating`, `created_at`, `updated_at`) VALUES ('2b0bb997-2f43-11f1-ac9a-525400c4d8bf','13800138000','$2a$10$iyAly0aU4gFqzh.ODvf8wuebh2Rxur.Ys24b4Jvp6QhWFeSQTXN4S','测试用户',NULL,'other',NULL,NULL,NULL,NULL,'patient','active',0.00,5.00,'2026-04-03 09:54:55','2026-04-24 16:29:56'),('30bc8d5b-2c95-11f1-ac9a-525400c4d8bf','13888888888','$2a$10$nfMlwGxRTBMV4BDZrwt7cOqdux6NYho32cGlLUukBJQeTil4xwr7y','新测试用户',NULL,'other',NULL,NULL,NULL,NULL,'patient','active',0.00,5.00,'2026-03-31 00:04:30','2026-03-31 00:04:30'),('3cc4a0f4-2ec5-11f1-ac9a-525400c4d8bf','13800138111','$2a$10$D3YLEarqC1XsdaZmbPRG8.ACejoudwltW.VnLv6FKFMDcvlE8C7Oe','支付测试用户',NULL,'other',NULL,NULL,NULL,NULL,'patient','active',0.00,5.00,'2026-04-02 18:53:28','2026-04-02 18:53:28'),('5671117b-2e98-11f1-ac9a-525400c4d8bf','13800138010','$2a$10$Jn6XdJDU9jtbf89Q0dn77.u8IUYte0uc0C4PHMnC0J5rUUhndbz7S','测试用户',NULL,'other',NULL,NULL,NULL,NULL,'patient','active',0.00,5.00,'2026-04-02 13:32:04','2026-04-02 13:32:04'),('admin_001','13800000000','$2a$10$CLx20VOFIpIV2ZXZOxLwtO3QWmWJ4yzALAD1xokNmy7pw5Ume1uay','系统管理员',NULL,'other',NULL,NULL,NULL,NULL,'admin','active',0.00,5.00,'2026-03-30 23:58:39','2026-04-24 12:31:53'),('companion_user_001','13900139001','$2a$10$CLx20VOFIpIV2ZXZOxLwtO3QWmWJ4yzALAD1xokNmy7pw5Ume1uay','张美丽',NULL,'other',NULL,NULL,NULL,NULL,'companion','active',0.00,5.00,'2026-03-30 23:58:39','2026-04-24 16:27:40'),('companion_user_002','13900139002','$2a$10$CLx20VOFIpIV2ZXZOxLwtO3QWmWJ4yzALAD1xokNmy7pw5Ume1uay','李医生',NULL,'other',NULL,NULL,NULL,NULL,'companion','active',0.00,5.00,'2026-03-30 23:58:39','2026-04-24 12:31:53'),('companion_user_003','13900139003','$2a$10$CLx20VOFIpIV2ZXZOxLwtO3QWmWJ4yzALAD1xokNmy7pw5Ume1uay','王阿姨',NULL,'other',NULL,NULL,NULL,NULL,'companion','active',0.00,5.00,'2026-03-30 23:58:39','2026-04-24 12:31:53'),('companion_user_1777048060926','13900999001','$2a$10$6P2.bMrUzR/c8z7z/eObiODeV63/uOXM.7SALcE8CZZ2PZ3kSomJy','测试新人',NULL,'other',NULL,NULL,NULL,NULL,'companion','active',0.00,5.00,'2026-04-24 16:27:40','2026-04-24 16:27:40'),('companion_user_1777048187201','13900999003','$2a$10$aa8hZbZdlGUYd5XCJsdCjOR0qFdAJTnGcZfOVsozU5Bzzipp0ljJO','待删除测试',NULL,'other',NULL,NULL,NULL,NULL,'companion','active',0.00,5.00,'2026-04-24 16:29:47','2026-04-24 16:29:47'),('companion_user_1777050461499','15021176755','$2a$10$DSBX/d4UPCQ65F1cmcXe1uea9eM6Wp6oYsO6olCZtdNmhKw1M9Xqq','andy',NULL,'other',NULL,NULL,NULL,NULL,'companion','active',0.00,5.00,'2026-04-24 17:07:41','2026-04-24 17:07:41'),('patient_001','13800138001','$2a$10$CLx20VOFIpIV2ZXZOxLwtO3QWmWJ4yzALAD1xokNmy7pw5Ume1uay','张先生',NULL,'male','1980-05-15',NULL,NULL,NULL,'patient','active',500.00,5.00,'2026-03-30 23:58:39','2026-04-24 12:31:53'),('patient_002','13800138002','$2a$10$CLx20VOFIpIV2ZXZOxLwtO3QWmWJ4yzALAD1xokNmy7pw5Ume1uay','李女士',NULL,'female','1975-08-22',NULL,NULL,NULL,'patient','active',300.00,5.00,'2026-03-30 23:58:39','2026-04-24 12:31:53'),('patient_003','13800138003','$2a$10$CLx20VOFIpIV2ZXZOxLwtO3QWmWJ4yzALAD1xokNmy7pw5Ume1uay','王阿姨',NULL,'female','1965-03-10',NULL,NULL,NULL,'patient','active',200.00,5.00,'2026-03-30 23:58:39','2026-04-24 12:31:53');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` (`id`, `order_number`, `patient_id`, `companion_id`, `hospital_id`, `department_id`, `appointment_date`, `appointment_time`, `service_type`, `service_hours`, `symptoms_description`, `special_requirements`, `status`, `total_amount`, `paid_amount`, `payment_status`, `payment_method`, `payment_time`, `patient_rating`, `patient_comment`, `companion_rating`, `companion_comment`, `cancel_reason`, `cancelled_by`, `created_at`, `updated_at`, `completed_at`) VALUES ('order_001','YB202603310001','patient_001','comp_001','hosp_002','dept_006','2026-04-01','09:00:00','accompany',3,'头痛、头晕持续一周，需要神经内科检查',NULL,'completed',600.00,600.00,'paid','wechat',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-30 02:00:00','2026-04-24 14:18:25',NULL),('order_002','YB202603310002','patient_002','comp_002','hosp_003','dept_011','2026-04-02','14:30:00','accompany',2,'血糖控制不佳，需要内分泌科复诊',NULL,'pending',600.00,0.00,'unpaid','alipay',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-30 03:30:00','2026-03-30 23:58:39',NULL),('order_003','YB202603310003','patient_003','comp_003','hosp_001','dept_003','2026-04-03','10:00:00','accompany',4,'妇科常规检查',NULL,'completed',720.00,720.00,'paid','balance',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-29 07:45:00','2026-03-30 23:58:39',NULL),('order_004','YB202603310004','patient_001',NULL,'hosp_004','dept_014','2026-04-04','13:00:00','consult',1,'咳嗽、胸闷咨询',NULL,'pending',150.00,0.00,'unpaid','wechat',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-30 08:20:00','2026-04-24 16:29:53','2026-04-24 16:29:53');
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `user_wallets`
--

LOCK TABLES `user_wallets` WRITE;
/*!40000 ALTER TABLE `user_wallets` DISABLE KEYS */;
INSERT INTO `user_wallets` (`id`, `user_id`, `balance`, `frozen_amount`, `total_recharge`, `total_withdraw`, `total_consumption`, `last_transaction_at`, `created_at`, `updated_at`) VALUES ('2949d0f9-2cda-11f1-ac9a-525400c4d8bf','admin_001',1000.00,0.00,1000.00,0.00,0.00,NULL,'2026-03-31 08:18:13','2026-03-31 08:18:13'),('2949d409-2cda-11f1-ac9a-525400c4d8bf','patient_001',1000.00,0.00,1000.00,0.00,0.00,NULL,'2026-03-31 08:18:13','2026-03-31 08:18:13'),('2949d4c1-2cda-11f1-ac9a-525400c4d8bf','companion_user_001',1000.00,0.00,1000.00,0.00,0.00,NULL,'2026-03-31 08:18:13','2026-03-31 08:18:13'),('4b0c4042-2f45-11f1-ac9a-525400c4d8bf','2b0bb997-2f43-11f1-ac9a-525400c4d8bf',0.00,0.00,0.00,0.00,0.00,NULL,'2026-04-03 10:10:08','2026-04-03 10:10:08'),('70aacd7a-2ec5-11f1-ac9a-525400c4d8bf','3cc4a0f4-2ec5-11f1-ac9a-525400c4d8bf',0.00,0.00,0.00,0.00,0.00,NULL,'2026-04-02 18:54:55','2026-04-02 18:54:55');
/*!40000 ALTER TABLE `user_wallets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `payment_methods`
--

LOCK TABLES `payment_methods` WRITE;
/*!40000 ALTER TABLE `payment_methods` DISABLE KEYS */;
INSERT INTO `payment_methods` (`id`, `name`, `code`, `description`, `icon_url`, `is_active`, `sort_order`, `config`, `created_at`, `updated_at`) VALUES ('29489805-2cda-11f1-ac9a-525400c4d8bf','微信支付','wechat','使用微信扫码支付',NULL,1,1,NULL,'2026-03-31 08:18:13','2026-03-31 08:18:13'),('2948aee5-2cda-11f1-ac9a-525400c4d8bf','支付宝','alipay','使用支付宝扫码支付',NULL,1,2,NULL,'2026-03-31 08:18:13','2026-03-31 08:18:13'),('2948c320-2cda-11f1-ac9a-525400c4d8bf','余额支付','balance','使用账户余额支付',NULL,1,3,NULL,'2026-03-31 08:18:13','2026-03-31 08:18:13'),('2948c45a-2cda-11f1-ac9a-525400c4d8bf','现金支付','cash','线下现金支付',NULL,1,4,NULL,'2026-03-31 08:18:13','2026-03-31 08:18:13');
/*!40000 ALTER TABLE `payment_methods` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `system_configs`
--

LOCK TABLES `system_configs` WRITE;
/*!40000 ALTER TABLE `system_configs` DISABLE KEYS */;
INSERT INTO `system_configs` (`id`, `config_key`, `config_value`, `description`, `is_public`, `created_at`, `updated_at`) VALUES ('5f8cfc9f-2c94-11f1-ac9a-525400c4d8bf','app_name','医小伴陪诊','应用名称',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('5f8d01fd-2c94-11f1-ac9a-525400c4d8bf','app_version','1.0.0','应用版本',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('5f8d043e-2c94-11f1-ac9a-525400c4d8bf','company_name','医小伴科技有限公司','公司名称',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('5f8d05a4-2c94-11f1-ac9a-525400c4d8bf','customer_service_phone','400-123-4567','客服电话',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('5f8d06df-2c94-11f1-ac9a-525400c4d8bf','min_service_hours','2','最小服务小时数',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('5f8d0834-2c94-11f1-ac9a-525400c4d8bf','max_service_hours','8','最大服务小时数',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('5f8d0972-2c94-11f1-ac9a-525400c4d8bf','default_hourly_rate','150','默认小时费率（元）',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('5f8d0a9b-2c94-11f1-ac9a-525400c4d8bf','order_cancel_time_limit','24','订单取消时间限制（小时）',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('5f8d0bc9-2c94-11f1-ac9a-525400c4d8bf','refund_processing_days','7','退款处理天数',1,'2026-03-30 23:58:39','2026-03-30 23:58:39'),('5f8d0d04-2c94-11f1-ac9a-525400c4d8bf','system_maintenance','false','系统维护状态',1,'2026-03-30 23:58:39','2026-03-30 23:58:39');
/*!40000 ALTER TABLE `system_configs` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

