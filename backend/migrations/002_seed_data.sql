-- 医小伴陪诊APP - 初始数据
-- 创建时间: 2026-03-31

-- 插入系统配置
INSERT INTO system_configs (config_key, config_value, description, is_public) VALUES
('app_name', '医小伴陪诊', '应用名称', TRUE),
('app_version', '1.0.0', '应用版本', TRUE),
('company_name', '医小伴科技有限公司', '公司名称', TRUE),
('customer_service_phone', '400-123-4567', '客服电话', TRUE),
('min_service_hours', '2', '最小服务小时数', TRUE),
('max_service_hours', '8', '最大服务小时数', TRUE),
('default_hourly_rate', '150', '默认小时费率（元）', TRUE),
('order_cancel_time_limit', '24', '订单取消时间限制（小时）', TRUE),
('refund_processing_days', '7', '退款处理天数', TRUE),
('system_maintenance', 'false', '系统维护状态', TRUE);

-- 插入医院数据
INSERT INTO hospitals (id, name, level, address, province, city, district, phone, description, is_active) VALUES
('hosp_001', '上海市第一人民医院', '三甲', '上海市虹口区武进路85号', '上海', '上海', '虹口区', '021-63240090', '上海市第一人民医院是上海市属大型综合性三级甲等医院，创建于1864年，是上海最早建立的西医医院之一。', TRUE),
('hosp_002', '华山医院', '三甲', '上海市静安区乌鲁木齐中路12号', '上海', '上海', '静安区', '021-62489999', '复旦大学附属华山医院是卫生部直属医院，是中国最著名的医院之一，以神经外科、皮肤科、感染科闻名。', TRUE),
('hosp_003', '瑞金医院', '三甲', '上海市黄浦区瑞金二路197号', '上海', '上海', '黄浦区', '021-64370045', '上海交通大学医学院附属瑞金医院是一所集医疗、教学、科研为一体的三级甲等综合性医院，以内分泌科、血液科著称。', TRUE),
('hosp_004', '中山医院', '三甲', '上海市徐汇区枫林路180号', '上海', '上海', '徐汇区', '021-64041990', '复旦大学附属中山医院是上海市第一批三级甲等医院，以心血管病、肝肿瘤、呼吸病诊治为特色。', TRUE),
('hosp_005', '仁济医院', '三甲', '上海市浦东新区浦建路160号', '上海', '上海', '浦东新区', '021-58752345', '上海交通大学医学院附属仁济医院是上海开埠后第一所西医医院，以消化内科、风湿免疫科、泌尿外科闻名。', TRUE);

-- 插入科室数据
INSERT INTO departments (id, hospital_id, name, description, floor, room_number, phone) VALUES
-- 上海市第一人民医院科室
('dept_001', 'hosp_001', '内科', '综合性内科，擅长各种常见病、多发病的诊治', '2楼', '201-210', '021-63240091'),
('dept_002', 'hosp_001', '外科', '普外科、骨科、神经外科等', '3楼', '301-315', '021-63240092'),
('dept_003', 'hosp_001', '妇产科', '妇科、产科、计划生育科', '4楼', '401-410', '021-63240093'),
('dept_004', 'hosp_001', '儿科', '儿童内科、儿童外科、新生儿科', '5楼', '501-508', '021-63240094'),
('dept_005', 'hosp_001', '眼科', '眼科疾病诊治、白内障手术等', '6楼', '601-605', '021-63240095'),

-- 华山医院科室
('dept_006', 'hosp_002', '神经内科', '神经系统疾病诊治，擅长脑血管病、癫痫等', '3楼', '301-310', '021-62489991'),
('dept_007', 'hosp_002', '皮肤科', '皮肤病、性病诊治，皮肤美容', '4楼', '401-408', '021-62489992'),
('dept_008', 'hosp_002', '感染科', '传染病、发热性疾病诊治', '5楼', '501-505', '021-62489993'),
('dept_009', 'hosp_002', '骨科', '创伤骨科、关节外科、脊柱外科', '6楼', '601-610', '021-62489994'),
('dept_010', 'hosp_002', '康复科', '物理治疗、作业治疗、言语治疗', '7楼', '701-705', '021-62489995'),

-- 瑞金医院科室
('dept_011', 'hosp_003', '内分泌科', '糖尿病、甲状腺疾病、骨质疏松等', '3楼', '301-308', '021-64370046'),
('dept_012', 'hosp_003', '血液科', '白血病、淋巴瘤、贫血等血液病', '4楼', '401-406', '021-64370047'),
('dept_013', 'hosp_003', '消化科', '胃肠疾病、肝病、胰腺疾病', '5楼', '501-508', '021-64370048'),
('dept_014', 'hosp_003', '呼吸科', '哮喘、慢阻肺、肺炎等呼吸系统疾病', '6楼', '601-605', '021-64370049'),
('dept_015', 'hosp_003', '心血管科', '冠心病、高血压、心律失常等', '7楼', '701-708', '021-64370050');

-- 插入管理员用户（密码：admin123，实际使用时应使用bcrypt加密）
INSERT INTO users (id, phone, password_hash, name, role, status) VALUES
('admin_001', '13800000000', '$2b$10$YourHashedPasswordHere', '系统管理员', 'admin', 'active');

-- 插入测试患者用户（密码：patient123）
INSERT INTO users (id, phone, password_hash, name, gender, birth_date, role, status, balance) VALUES
('patient_001', '13800138001', '$2b$10$YourHashedPasswordHere', '张先生', 'male', '1980-05-15', 'patient', 'active', 500.00),
('patient_002', '13800138002', '$2b$10$YourHashedPasswordHere', '李女士', 'female', '1975-08-22', 'patient', 'active', 300.00),
('patient_003', '13800138003', '$2b$10$YourHashedPasswordHere', '王阿姨', 'female', '1965-03-10', 'patient', 'active', 200.00);

-- 插入陪诊师用户和数据（密码：companion123）
INSERT INTO users (id, phone, password_hash, name, role, status) VALUES
('companion_user_001', '13900139001', '$2b$10$YourHashedPasswordHere', '张护士', 'companion', 'active'),
('companion_user_002', '13900139002', '$2b$10$YourHashedPasswordHere', '李医生', 'companion', 'active'),
('companion_user_003', '13900139003', '$2b$10$YourHashedPasswordHere', '王阿姨', 'companion', 'active');

INSERT INTO companions (id, user_id, real_name, id_card, experience_years, specialty, certification_number, introduction, service_count, average_rating, hourly_rate, is_available, is_certified) VALUES
('comp_001', 'companion_user_001', '张美丽', '310101198505151234', 5, '["内科陪诊", "老年陪护", "报告解读"]', 'CERT2024001', '拥有5年陪诊经验，擅长内科疾病陪诊和老年患者陪护，耐心细致，服务周到。', 128, 4.8, 200.00, TRUE, TRUE),
('comp_002', 'companion_user_002', '李建国', '310101197808221235', 8, '["全科陪诊", "报告解读", "医患沟通"]', 'CERT2024002', '原三甲医院医生，8年临床经验，精通医学术语，能有效协助医患沟通。', 256, 4.9, 300.00, TRUE, TRUE),
('comp_003', 'companion_user_003', '王秀英', '310101196503101236', 3, '["妇产科陪诊", "儿科陪护", "心理疏导"]', 'CERT2024003', '3年陪诊经验，特别擅长妇产科和儿科陪诊，善于与患者沟通，提供心理支持。', 89, 4.7, 180.00, FALSE, TRUE);

-- 插入测试订单数据
INSERT INTO orders (id, order_number, patient_id, companion_id, hospital_id, department_id, appointment_date, appointment_time, service_type, service_hours, symptoms_description, status, total_amount, paid_amount, payment_status, payment_method, created_at) VALUES
('order_001', 'YB202603310001', 'patient_001', 'comp_001', 'hosp_002', 'dept_006', '2026-04-01', '09:00:00', 'accompany', 3, '头痛、头晕持续一周，需要神经内科检查', 'confirmed', 600.00, 600.00, 'paid', 'wechat', '2026-03-30 10:00:00'),
('order_002', 'YB202603310002', 'patient_002', 'comp_002', 'hosp_003', 'dept_011', '2026-04-02', '14:30:00', 'accompany', 2, '血糖控制不佳，需要内分泌科复诊', 'pending', 600.00, 0.00, 'unpaid', 'alipay', '2026-03-30 11:30:00'),
('order_003', 'YB202603310003', 'patient_003', 'comp_003', 'hosp_001', 'dept_003', '2026-04-03', '10:00:00', 'accompany', 4, '妇科常规检查', 'completed', 720.00, 720.00, 'paid', 'balance', '2026-03-29 15:45:00'),
('order_004', 'YB202603310004', 'patient_001', NULL, 'hosp_004', 'dept_014', '2026-04-04', '13:00:00', 'consult', 1, '咳嗽、胸闷咨询', 'pending', 150.00, 0.00, 'unpaid', 'wechat', '2026-03-30 16:20:00');

-- 插入聊天消息示例
INSERT INTO chat_messages (id, order_id, sender_id, receiver_id, message_type, content, is_read, created_at) VALUES
('msg_001', 'order_001', 'patient_001', 'companion_user_001', 'text', '张护士您好，我明天9点准时到医院门口等您。', TRUE, '2026-03-30 14:30:00'),
('msg_002', 'order_001', 'companion_user_001', 'patient_001', 'text', '好的张先生，我会提前15分钟到达。请带好身份证和医保卡。', TRUE, '2026-03-30 14:32:00'),
('msg_003', 'order_001', 'patient_001', 'companion_user_001', 'text', '谢谢提醒！我还会带最近的检查报告。', TRUE, '2026-03-30 14:35:00'),
('msg_004', 'order_002', 'patient_002', 'companion_user_002', 'text', '李医生，我最近血糖控制不太好，有点担心。', FALSE, '2026-03-30 15:20:00');

-- 插入支付记录示例
INSERT INTO payments (id, order_id, payment_number, amount, payment_method, payment_status, transaction_id, payer_id, payer_name, receiver_id, receiver_name, payment_time) VALUES
('pay_001', 'order_001', 'PAY202603310001', 600.00, 'wechat', 'success', 'WX202603301000123456', 'patient_001', '张先生', 'companion_user_001', '张护士', '2026-03-30 10:05:00'),
('pay_002', 'order_003', 'PAY202603290001', 720.00, 'balance', 'success', 'BAL202603291500654321', 'patient_003', '王阿姨', 'companion_user_003', '王阿姨', '2026-03-29 15:50:00');

-- 插入操作日志示例
INSERT INTO operation_logs (user_id, user_type, operation_type, target_type, target_id, ip_address, request_method, request_url, response_status, duration_ms) VALUES
('patient_001', 'patient', 'user_login', 'user', 'patient_001', '192.168.1.100', 'POST', '/api/auth/login', 200, 120),
('patient_001', 'patient', 'create_order', 'order', 'order_001', '192.168.1.100', 'POST', '/api/orders', 201, 350),
('companion_user_001', 'companion', 'accept_order', 'order', 'order_001', '192.168.1.101', 'PUT', '/api/orders/order_001/accept', 200, 180),
('admin_001', 'admin', 'view_dashboard', 'system', NULL, '192.168.1.1', 'GET', '/api/admin/dashboard', 200, 85);