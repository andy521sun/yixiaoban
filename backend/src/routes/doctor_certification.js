/**
 * 医小伴 v2.0 - 医生认证/入驻 API
 */

const express = require('express');
const router = express.Router();
const { query, transaction } = require('../db');
const auth = require('../auth');

// 中间件：要求登录
router.use(auth.authenticateToken);

/**
 * POST /api/doctor/certification - 提交医生认证
 */
router.post('/certification', async (req, res) => {
  try {
    const user = req.user;
    if (user.role !== 'doctor' && user.role !== 'companion' && user.role !== 'patient') {
      return res.status(403).json({ error: '当前角色不支持申请医生认证' });
    }

    const {
      real_name, id_card, practice_license, qualification_cert,
      hospital_cert, hospital_name, department, title, specialty, introduction
    } = req.body;

    if (!real_name || !id_card) {
      return res.status(400).json({ error: '真实姓名和身份证号不能为空' });
    }

    // 检查是否已有认证申请
    const existing = await query('SELECT id, status FROM doctor_certifications WHERE user_id = ?', [user.id]);
    if (existing.length > 0) {
      const status = existing[0].status;
      if (status === 'pending') return res.status(400).json({ error: '已有待审核的认证申请' });
      if (status === 'approved') return res.status(400).json({ error: '您已通过医生认证' });
      // rejected - 允许重新提交
    }

    await transaction(async (conn) => {
      if (existing.length > 0 && existing[0].status === 'rejected') {
        await conn.execute(
          `UPDATE doctor_certifications SET real_name=?, id_card=?, practice_license=?, 
           qualification_cert=?, hospital_cert=?, hospital_name=?, department=?, 
           title=?, specialty=?, introduction=?, status='pending', reject_reason=NULL,
           reviewed_by=NULL, reviewed_at=NULL, updated_at=NOW()
           WHERE user_id=?`,
          [real_name, id_card, practice_license, qualification_cert, hospital_cert,
           hospital_name, department, title, specialty, introduction, user.id]
        );
      } else {
        await conn.execute(
          `INSERT INTO doctor_certifications 
           (user_id, real_name, id_card, practice_license, qualification_cert, 
            hospital_cert, hospital_name, department, title, specialty, introduction)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [user.id, real_name, id_card, practice_license, qualification_cert,
           hospital_cert, hospital_name, department, title, specialty, introduction]
        );
      }
    });

    res.json({ message: '认证申请提交成功，请等待审核' });
  } catch (error) {
    console.error('提交医生认证失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/doctor/certification - 查询自己的认证状态
 */
router.get('/certification', async (req, res) => {
  try {
    const rows = await query(
      'SELECT * FROM doctor_certifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 1',
      [req.user.id]
    );
    if (rows.length === 0) return res.json({ certified: false });
    res.json({ certified: true, data: rows[0] });
  } catch (error) {
    console.error('查询认证状态失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * PUT /api/doctor/service-pricing - 设置服务价格
 */
router.put('/service-pricing', async (req, res) => {
  try {
    const { services } = req.body; // [{service_type, price}]
    if (!Array.isArray(services) || services.length === 0) {
      return res.status(400).json({ error: '请提供服务价格配置' });
    }

    // 检查用户角色
    const users = await query('SELECT role, is_verified FROM users WHERE id = ?', [req.user.id]);
    if (users.length === 0) return res.status(404).json({ error: '用户不存在' });
    if (users[0].role !== 'doctor' || !users[0].is_verified) {
      return res.status(403).json({ error: '仅认证医生可设置服务价格' });
    }

    await transaction(async (conn) => {
      for (const svc of services) {
        const validTypes = ['text_consult', 'image_consult', 'video_consult', 'phone_consult'];
        if (!validTypes.includes(svc.service_type)) continue;
        await conn.execute(
          `INSERT INTO doctor_service_pricing (doctor_id, service_type, price)
           VALUES (?, ?, ?)
           ON DUPLICATE KEY UPDATE price = VALUES(price), updated_at = NOW()`,
          [req.user.id, svc.service_type, svc.price || 0]
        );
      }
    });

    res.json({ message: '服务价格配置已保存' });
  } catch (error) {
    console.error('设置服务价格失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/doctor/service-pricing - 查询服务价格
 */
router.get('/service-pricing', async (req, res) => {
  try {
    const rows = await query(
      'SELECT * FROM doctor_service_pricing WHERE doctor_id = ? AND is_active = 1',
      [req.user.id]
    );
    res.json({ services: rows });
  } catch (error) {
    console.error('查询服务价格失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/doctors - 患者端：获取医生列表
 */
router.get('/list', async (req, res) => {
  try {
    const { department, page = 1, page_size = 20 } = req.query;
    const offset = (page - 1) * page_size;

    let sql = `
      SELECT u.id, u.name, u.avatar_url, u.title, u.department, u.hospital_affiliation,
             u.rating, u.is_verified,
             (SELECT JSON_ARRAYAGG(JSON_OBJECT('service_type', dsp.service_type, 'price', dsp.price))
              FROM doctor_service_pricing dsp WHERE dsp.doctor_id = u.id AND dsp.is_active = 1) as services
      FROM users u
      WHERE u.role = 'doctor' AND u.is_verified = 1
    `;
    const params = [];
    if (department) {
      sql += ' AND u.department LIKE ?';
      params.push(`%${department}%`);
    }
    sql += ' ORDER BY u.rating DESC LIMIT ? OFFSET ?';
    params.push(Number(page_size), offset);

    const rows = await query(sql, params);
    const [{ total }] = await query(
      'SELECT COUNT(*) as total FROM users WHERE role = ? AND is_verified = ?',
      ['doctor', 1]
    );

    res.json({ doctors: rows, total, page: Number(page), page_size: Number(page_size) });
  } catch (error) {
    console.error('获取医生列表失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/doctors/:id - 患者端：获取医生详情
 */
router.get('/:id', async (req, res) => {
  try {
    const rows = await query(`
      SELECT u.id, u.name, u.avatar_url, u.title, u.department, u.hospital_affiliation,
             u.rating, u.is_verified, u.license_number,
             dc.introduction, dc.specialty
      FROM users u
      LEFT JOIN doctor_certifications dc ON dc.user_id = u.id AND dc.status = 'approved'
      WHERE u.id = ? AND u.role = 'doctor'
    `, [req.params.id]);

    if (rows.length === 0) return res.status(404).json({ error: '医生不存在' });

    const prices = await query(
      'SELECT service_type, price FROM doctor_service_pricing WHERE doctor_id = ? AND is_active = 1',
      [req.params.id]
    );

    res.json({ doctor: rows[0], services: prices });
  } catch (error) {
    console.error('获取医生详情失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

module.exports = router;
