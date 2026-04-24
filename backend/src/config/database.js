// 数据库连接配置（CommonJS版本）
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'yixiaoban',
  password: process.env.DB_PASSWORD || 'yixiaoban123',
  database: process.env.DB_NAME || 'yixiaoban',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0
});

async function query(sql, params = []) {
  const [results] = await pool.execute(sql, params);
  return results;
}

module.exports = { pool, query };
