// 数据库连接配置
const mysql = require('mysql2/promise');
require('dotenv').config();

// 创建数据库连接池
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'yixiaoban',
  password: process.env.DB_PASSWORD || 'yixiaoban123',
  database: process.env.DB_NAME || 'yixiaoban',
  charset: 'utf8mb4',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0
});

// 测试数据库连接
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ 数据库连接成功');
    connection.release();
    return true;
  } catch (error) {
    console.error('❌ 数据库连接失败:', error.message);
    return false;
  }
}

// 执行查询
async function query(sql, params = []) {
  try {
    // mysql2的execute对LIMIT/OFFSET参数化不支持，统一用query
    let results;
    if (params.length === 0) {
      [results] = await pool.query(sql);
    } else {
      [results] = await pool.query(sql, params);
    }
    return results;
  } catch (error) {
    console.error('数据库查询错误:', error.message);
    throw error;
  }
}

// 执行事务
async function transaction(callback) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const result = await callback(connection);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

// 用户相关查询
const userQueries = {
  // 根据手机号查找用户
  findByPhone: async (phone) => {
    const sql = 'SELECT * FROM users WHERE phone = ?';
    const users = await query(sql, [phone]);
    return users[0] || null;
  },

  // 根据ID查找用户
  findById: async (id) => {
    const sql = 'SELECT id, phone, name, avatar_url, gender, birth_date, role, status, balance, rating, created_at FROM users WHERE id = ?';
    const users = await query(sql, [id]);
    return users[0] || null;
  },

  // 创建用户
  create: async (userData) => {
    const {
      phone,
      password_hash,
      name,
      avatar_url = null,
      gender = 'other',
      birth_date = null,
      role = 'patient',
      status = 'active'
    } = userData;

    const sql = `
      INSERT INTO users 
      (id, phone, password_hash, name, avatar_url, gender, birth_date, role, status) 
      VALUES (UUID(), ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    const result = await query(sql, [
      phone, password_hash, name, avatar_url, gender, birth_date, role, status
    ]);
    
    return { id: result.insertId, ...userData };
  },

  // 更新用户信息
  update: async (id, updateData) => {
    const fields = [];
    const values = [];
    
    Object.keys(updateData).forEach(key => {
      if (updateData[key] !== undefined) {
        fields.push(`${key} = ?`);
        values.push(updateData[key]);
      }
    });
    
    if (fields.length === 0) return null;
    
    values.push(id);
    const sql = `UPDATE users SET ${fields.join(', ')} WHERE id = ?`;
    await query(sql, values);
    
    return userQueries.findById(id);
  },

  // 获取用户余额
  getBalance: async (userId) => {
    const sql = 'SELECT balance FROM users WHERE id = ?';
    const result = await query(sql, [userId]);
    return result[0]?.balance || 0;
  },

  // 更新用户余额
  updateBalance: async (userId, amount) => {
    const sql = 'UPDATE users SET balance = balance + ? WHERE id = ?';
    await query(sql, [amount, userId]);
    return userQueries.getBalance(userId);
  }
};

// 医院相关查询
const hospitalQueries = {
  // 获取所有医院
  findAll: async (filters = {}) => {
    let sql = 'SELECT * FROM hospitals WHERE is_active = TRUE';
    const params = [];
    
    if (filters.city) {
      sql += ' AND city = ?';
      params.push(filters.city);
    }
    
    if (filters.level) {
      sql += ' AND level = ?';
      params.push(filters.level);
    }
    
    sql += ' ORDER BY name';
    return await query(sql, params);
  },

  // 根据ID查找医院
  findById: async (id) => {
    const sql = 'SELECT * FROM hospitals WHERE id = ? AND is_active = TRUE';
    const hospitals = await query(sql, [id]);
    return hospitals[0] || null;
  },

  // 获取医院科室
  getDepartments: async (hospitalId) => {
    const sql = 'SELECT * FROM departments WHERE hospital_id = ? AND is_active = TRUE ORDER BY name';
    return await query(sql, [hospitalId]);
  }
};

// 陪诊师相关查询
const companionQueries = {
  // 获取所有可用陪诊师
  findAvailable: async (filters = {}) => {
    let sql = `
      SELECT c.*, u.name, u.avatar_url, u.rating 
      FROM companions c 
      JOIN users u ON c.user_id = u.id 
      WHERE c.is_available = TRUE AND c.is_certified = TRUE AND u.status = 'active'
    `;
    const params = [];
    
    if (filters.specialty) {
      sql += ' AND c.specialty LIKE ?';
      params.push(`%${filters.specialty}%`);
    }
    
    if (filters.minExperience) {
      sql += ' AND c.experience_years >= ?';
      params.push(filters.minExperience);
    }
    
    if (filters.maxHourlyRate) {
      sql += ' AND c.hourly_rate <= ?';
      params.push(filters.maxHourlyRate);
    }
    
    sql += ' ORDER BY c.average_rating DESC, c.service_count DESC';
    return await query(sql, params);
  },

  // 根据ID查找陪诊师
  findById: async (id) => {
    const sql = `
      SELECT c.*, u.name, u.avatar_url, u.rating, u.phone 
      FROM companions c 
      JOIN users u ON c.user_id = u.id 
      WHERE c.id = ? AND u.status = 'active'
    `;
    const companions = await query(sql, [id]);
    return companions[0] || null;
  },

  // 更新陪诊师状态
  updateAvailability: async (id, isAvailable) => {
    const sql = 'UPDATE companions SET is_available = ? WHERE id = ?';
    await query(sql, [isAvailable, id]);
    return companionQueries.findById(id);
  }
};

// 订单相关查询
const orderQueries = {
  // 创建订单
  create: async (orderData) => {
    const {
      patient_id,
      hospital_id,
      department_id = null,
      appointment_date,
      appointment_time,
      service_type = 'accompany',
      service_hours = 2,
      symptoms_description = '',
      special_requirements = '',
      total_amount
    } = orderData;

    // 生成订单号
    const date = new Date();
    const orderNumber = `YB${date.getFullYear()}${String(date.getMonth() + 1).padStart(2, '0')}${String(date.getDate()).padStart(2, '0')}${String(Math.floor(Math.random() * 10000)).padStart(4, '0')}`;

    const sql = `
      INSERT INTO orders 
      (id, order_number, patient_id, hospital_id, department_id, appointment_date, appointment_time, 
       service_type, service_hours, symptoms_description, special_requirements, total_amount) 
      VALUES (UUID(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    const result = await query(sql, [
      orderNumber, patient_id, hospital_id, department_id, appointment_date, appointment_time,
      service_type, service_hours, symptoms_description, special_requirements, total_amount
    ]);
    
    return orderQueries.findById(result.insertId);
  },

  // 根据ID查找订单
  findById: async (id) => {
    const sql = `
      SELECT o.*, 
        p.name as patient_name, p.phone as patient_phone,
        c.real_name as companion_name, c.hourly_rate,
        h.name as hospital_name, h.address as hospital_address,
        d.name as department_name
      FROM orders o
      LEFT JOIN users p ON o.patient_id = p.id
      LEFT JOIN companions c ON o.companion_id = c.id
      LEFT JOIN hospitals h ON o.hospital_id = h.id
      LEFT JOIN departments d ON o.department_id = d.id
      WHERE o.id = ?
    `;
    const orders = await query(sql, [id]);
    return orders[0] || null;
  },

  // 获取用户订单
  findByUserId: async (userId, filters = {}) => {
    let sql = `
      SELECT o.*, 
        h.name as hospital_name,
        c.real_name as companion_name
      FROM orders o
      LEFT JOIN hospitals h ON o.hospital_id = h.id
      LEFT JOIN companions c ON o.companion_id = c.id
      WHERE o.patient_id = ?
    `;
    const params = [userId];
    
    if (filters.status) {
      sql += ' AND o.status = ?';
      params.push(filters.status);
    }
    
    if (filters.startDate) {
      sql += ' AND o.appointment_date >= ?';
      params.push(filters.startDate);
    }
    
    if (filters.endDate) {
      sql += ' AND o.appointment_date <= ?';
      params.push(filters.endDate);
    }
    
    sql += ' ORDER BY o.created_at DESC';
    
    if (filters.limit) {
      sql += ' LIMIT ?';
      params.push(filters.limit);
    }
    
    return await query(sql, params);
  },

  // 更新订单状态
  updateStatus: async (id, status, data = {}) => {
    const updates = ['status = ?'];
    const params = [status];
    
    if (data.companion_id) {
      updates.push('companion_id = ?');
      params.push(data.companion_id);
    }
    
    if (data.cancel_reason) {
      updates.push('cancel_reason = ?');
      params.push(data.cancel_reason);
    }
    
    if (data.cancelled_by) {
      updates.push('cancelled_by = ?');
      params.push(data.cancelled_by);
    }
    
    if (status === 'completed') {
      updates.push('completed_at = NOW()');
    }
    
    params.push(id);
    const sql = `UPDATE orders SET ${updates.join(', ')}, updated_at = NOW() WHERE id = ?`;
    await query(sql, params);
    
    return orderQueries.findById(id);
  },

  // 更新支付状态
  updatePayment: async (id, paymentData) => {
    const { payment_status, payment_method, paid_amount, payment_time } = paymentData;
    
    const sql = `
      UPDATE orders 
      SET payment_status = ?, payment_method = ?, paid_amount = ?, payment_time = ?, updated_at = NOW() 
      WHERE id = ?
    `;
    
    await query(sql, [payment_status, payment_method, paid_amount, payment_time, id]);
    return orderQueries.findById(id);
  }
};

// 系统配置查询
const configQueries = {
  // 获取配置
  get: async (key) => {
    const sql = 'SELECT config_value FROM system_configs WHERE config_key = ?';
    const result = await query(sql, [key]);
    return result[0]?.config_value || null;
  },

  // 获取所有公开配置
  getAllPublic: async () => {
    const sql = 'SELECT config_key, config_value FROM system_configs WHERE is_public = TRUE';
    return await query(sql);
  }
};

module.exports = {
  pool,
  testConnection,
  query,
  transaction,
  userQueries,
  hospitalQueries,
  companionQueries,
  orderQueries,
  configQueries
};