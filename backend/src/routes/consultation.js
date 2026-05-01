/**
 * 医小伴 v2.0 - 在线问诊 API
 */

const express = require('express');
const router = express.Router();
const { query, transaction } = require('../db');
const auth = require('../auth');

// 所有接口需要登录
router.use(auth.authenticateToken);

/**
 * POST /api/consultations - 患者发起问诊
 */
router.post('/', async (req, res) => {
  try {
    if (req.user.role !== 'patient') {
      return res.status(403).json({ error: '仅患者可发起问诊' });
    }
    const { doctor_id, consult_type, chief_complaint, present_illness, past_history, severity } = req.body;
    if (!doctor_id || !consult_type) {
      return res.status(400).json({ error: '医生ID和问诊类型不能为空' });
    }

    // 检查医生是否存在且已认证
    const [doctor] = await query(
      'SELECT id, name FROM users WHERE id = ? AND role = ? AND is_verified = 1',
      [doctor_id, 'doctor']
    );
    if (!doctor) return res.status(404).json({ error: '医生不存在或未认证' });

    const result = await query(
      `INSERT INTO consultations (patient_id, doctor_id, consult_type, chief_complaint, present_illness, past_history, severity, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'waiting')`,
      [req.user.id, doctor_id, consult_type, chief_complaint, present_illness, past_history, severity || 'normal']
    );

    // 查询刚插入的记录获取 UUID (id 是 UUID() 生成的)
    const [newConsult] = await query(
      'SELECT id FROM consultations WHERE patient_id = ? AND doctor_id = ? ORDER BY created_at DESC LIMIT 1',
      [req.user.id, doctor_id]
    );

    res.status(201).json({
      message: '问诊已发起，等待医生接诊',
      consultation_id: newConsult ? newConsult.id : result.insertId
    });
  } catch (error) {
    console.error('发起问诊失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/consultations - 获取问诊列表（患者/医生各自视角）
 */
router.get('/', async (req, res) => {
  try {
    const { status, page = 1, page_size = 20 } = req.query;
    const offset = (page - 1) * page_size;

    let sql, params = [];
    const role = req.user.role;

    if (role === 'patient') {
      sql = `SELECT c.*, u.name as doctor_name, u.avatar_url as doctor_avatar,
                    u.title as doctor_title, u.department as doctor_dept
             FROM consultations c
             JOIN users u ON u.id = c.doctor_id
             WHERE c.patient_id = ?`;
      params.push(req.user.id);
    } else if (role === 'doctor') {
      sql = `SELECT c.*, u.name as patient_name, u.avatar_url as patient_avatar
             FROM consultations c
             JOIN users u ON u.id = c.patient_id
             WHERE c.doctor_id = ?`;
      params.push(req.user.id);
    } else {
      return res.status(403).json({ error: '无权限' });
    }

    if (status) {
      sql += ' AND c.status = ?';
      params.push(status);
    }
    sql += ' ORDER BY c.created_at DESC LIMIT ? OFFSET ?';
    params.push(Number(page_size), offset);

    const rows = await query(sql, params);
    res.json({ consultations: rows });
  } catch (error) {
    console.error('获取问诊列表失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/consultations/:id - 获取问诊详情
 */
router.get('/:id', async (req, res) => {
  try {
    const [consult] = await query(
      `SELECT c.*, 
        u1.name as doctor_name, u1.avatar_url as doctor_avatar,
        u2.name as patient_name, u2.avatar_url as patient_avatar
       FROM consultations c
       JOIN users u1 ON u1.id = c.doctor_id
       JOIN users u2 ON u2.id = c.patient_id
       WHERE c.id = ?`,
      [req.params.id]
    );
    if (!consult) return res.status(404).json({ error: '问诊记录不存在' });

    // 权限校验
    if (consult.patient_id !== req.user.id && consult.doctor_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: '无权限查看' });
    }

    // 获取消息
    const messages = await query(
      'SELECT * FROM consultation_messages WHERE consultation_id = ? ORDER BY created_at ASC',
      [req.params.id]
    );

    // 获取处方
    const prescription = await query(
      'SELECT * FROM prescriptions WHERE consultation_id = ? ORDER BY created_at DESC LIMIT 1',
      [req.params.id]
    );
    let prescriptionItems = [];
    if (prescription.length > 0) {
      prescriptionItems = await query(
        'SELECT * FROM prescription_items WHERE prescription_id = ?',
        [prescription[0].id]
      );
    }

    res.json({ consultation: consult, messages, prescription: prescription[0] || null, prescription_items: prescriptionItems });
  } catch (error) {
    console.error('获取问诊详情失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * POST /api/consultations/:id/accept - 医生接诊
 */
router.post('/:id/accept', async (req, res) => {
  try {
    if (req.user.role !== 'doctor' && req.user.role !== 'companion') return res.status(403).json({ error: '仅医生可操作' });

    const [consult] = await query(
      'SELECT * FROM consultations WHERE id = ? AND doctor_id = ? AND status = ?',
      [req.params.id, req.user.id, 'waiting']
    );
    if (!consult) return res.status(404).json({ error: '问诊不存在或状态不正确' });

    await query(
      "UPDATE consultations SET status = 'accepted', started_at = NOW() WHERE id = ?",
      [req.params.id]
    );

    res.json({ message: '已接诊' });
  } catch (error) {
    console.error('接诊失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * POST /api/consultations/:id/complete - 医生完成问诊
 */
router.post('/:id/complete', async (req, res) => {
  try {
    if (req.user.role !== 'doctor' && req.user.role !== 'companion') return res.status(403).json({ error: '仅医生可操作' });

    const { diagnosis, advice } = req.body;
    const [consult] = await query(
      "SELECT * FROM consultations WHERE id = ? AND doctor_id = ? AND status IN ('in_progress', 'accepted')",
      [req.params.id, req.user.id]
    );
    if (!consult) return res.status(404).json({ error: '问诊不存在或状态不正确' });

    await query(
      'UPDATE consultations SET status = ?, diagnosis = ?, advice = ?, completed_at = NOW() WHERE id = ?',
      ['completed', diagnosis || '', advice || '', req.params.id]
    );

    res.json({ message: '问诊已完成' });
  } catch (error) {
    console.error('完成问诊失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * POST /api/consultations/:id/cancel - 取消问诊
 */
router.post('/:id/cancel', async (req, res) => {
  try {
    const [consult] = await query(
      'SELECT * FROM consultations WHERE id = ? AND patient_id = ? AND status = ?',
      [req.params.id, req.user.id, 'waiting']
    );
    if (!consult) return res.status(404).json({ error: '问诊不存在或状态不正确' });

    await query("UPDATE consultations SET status = 'cancelled' WHERE id = ?", [req.params.id]);
    res.json({ message: '问诊已取消' });
  } catch (error) {
    console.error('取消问诊失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * POST /api/consultations/:id/rate - 患者评价
 */
router.post('/:id/rate', async (req, res) => {
  try {
    if (req.user.role !== 'patient') return res.status(403).json({ error: '仅患者可评价' });

    const { rating, review } = req.body;
    if (!rating || rating < 1 || rating > 5) return res.status(400).json({ error: '评分需在1-5之间' });

    const [consult] = await query(
      'SELECT * FROM consultations WHERE id = ? AND patient_id = ? AND status = ?',
      [req.params.id, req.user.id, 'completed']
    );
    if (!consult) return res.status(404).json({ error: '问诊不存在或状态不正确' });
    if (consult.patient_rated) return res.status(400).json({ error: '已评价过' });

    await query(
      'UPDATE consultations SET patient_rated = 1, patient_rating = ?, patient_review = ? WHERE id = ?',
      [rating, review || '', req.params.id]
    );

    res.json({ message: '评价成功' });
  } catch (error) {
    console.error('评价失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

module.exports = router;
