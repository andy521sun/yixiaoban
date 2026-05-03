/**
 * 医小伴 v2.0 - 电子处方 API
 * 医生开处方 → 患者查看处方
 */

const express = require('express');
const router = express.Router();
const { query, transaction } = require('../db');
const auth = require('../auth');

router.use(auth.authenticateToken);

/**
 * POST /api/consultations/:id/prescription - 医生开具处方
 */
router.post('/:consultationId/prescription', async (req, res) => {
  try {
    const { consultationId } = req.params;
    const { diagnosis, notes, items } = req.body; // items: [{drug_name, specification, dosage, frequency, duration, quantity, unit, remark}]

    // 验证问诊存在
    const [consult] = await query('SELECT * FROM consultations WHERE id = ?', [consultationId]);
    if (!consult) return res.status(404).json({ error: '问诊不存在' });

    // 只允许医生开处方
    if (consult.doctor_id !== req.user.id) {
      return res.status(403).json({ error: '仅接诊医生可开处方' });
    }

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: '处方至少包含一项药品' });
    }

    // 用 query 直接写入（不用 transaction 内的 execute，避免 UUID 生成问题）
    const prescriptionId = await (async () => {
      await query(
        `INSERT INTO prescriptions (consultation_id, patient_id, doctor_id, diagnosis, notes, status)
         VALUES (?, ?, ?, ?, ?, 'signed')`,
        [consultationId, consult.patient_id, req.user.id, diagnosis || consult.diagnosis || '', notes || '']
      );

      // 反查刚插入的处方 ID
      const pRows = await query(
        'SELECT id FROM prescriptions WHERE consultation_id = ? AND doctor_id = ? ORDER BY created_at DESC LIMIT 1',
        [consultationId, req.user.id]
      );
      const pid = Array.isArray(pRows) && pRows.length > 0 ? pRows[0].id : 
                  (pRows && pRows.id ? pRows.id : '');

      // 添加处方明细
      for (const item of items) {
        if (!item.drug_name) continue;
        await query(
          `INSERT INTO prescription_items (prescription_id, drug_name, specification, dosage, frequency, duration, quantity, unit, remark)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [pid, item.drug_name, item.specification || '', item.dosage || '', item.frequency || '',
           item.duration || '', item.quantity || 1, item.unit || '盒', item.remark || '']
        );
      }
      return pid;
    })();

    // 通知患者
    if (global.wss && typeof global.wss.sendToUser === 'function') {
      global.wss.sendToUser(consult.patient_id, {
        type: 'system_notification',
        data: { title: '新处方', content: '医生已为您开具电子处方，请查看', type: 'prescription', related_id: consultationId, timestamp: new Date().toISOString() }
      });
    }

    res.status(201).json({ message: '处方开具成功', prescription_id: prescriptionId });

    // 通知患者
    if (global.wss && typeof global.wss.sendToUser === 'function') {
      global.wss.sendToUser(consult.patient_id, {
        type: 'system_notification',
        data: {
          title: '新处方',
          content: '医生已为您开具电子处方，请查看',
          type: 'prescription',
          related_id: consultationId,
          timestamp: new Date().toISOString()
        }
      });
    }

    res.status(201).json({ message: '处方开具成功', prescription_id: prescriptionId });
  } catch (error) {
    console.error('开具处方失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/consultations/:id/prescription - 获取问诊的处方
 */
router.get('/:consultationId/prescription', async (req, res) => {
  try {
    const { consultationId } = req.params;

    // 权限校验
    const [consult] = await query('SELECT * FROM consultations WHERE id = ?', [consultationId]);
    if (!consult) return res.status(404).json({ error: '问诊不存在' });
    if (consult.patient_id !== req.user.id && consult.doctor_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: '无权限查看' });
    }

    const prescriptions = await query(
      'SELECT * FROM prescriptions WHERE consultation_id = ? ORDER BY created_at DESC',
      [consultationId]
    );

    if (prescriptions.length === 0) return res.json({ prescription: null, items: [] });

    const items = await query(
      'SELECT * FROM prescription_items WHERE prescription_id = ? ORDER BY id',
      [prescriptions[0].id]
    );

    res.json({ prescription: prescriptions[0], items });
  } catch (error) {
    console.error('获取处方失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * POST /api/prescriptions/:id/cancel - 作废处方
 */
router.post('/cancel/:id', async (req, res) => {
  try {
    const [prescription] = await query('SELECT * FROM prescriptions WHERE id = ?', [req.params.id]);
    if (!prescription) return res.status(404).json({ error: '处方不存在' });
    if (prescription.doctor_id !== req.user.id) return res.status(403).json({ error: '仅开方医生可操作' });

    await query("UPDATE prescriptions SET status = 'cancelled' WHERE id = ?", [req.params.id]);
    res.json({ message: '处方已作废' });
  } catch (error) {
    console.error('作废处方失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/prescriptions/:id - 获取处方详情
 */
router.get('/detail/:id', async (req, res) => {
  try {
    const [prescription] = await query(
      `SELECT p.*, u1.name as doctor_name, u1.title as doctor_title,
              u2.name as patient_name
       FROM prescriptions p
       JOIN users u1 ON u1.id = p.doctor_id
       JOIN users u2 ON u2.id = p.patient_id
       WHERE p.id = ?`,
      [req.params.id]
    );
    if (!prescription) return res.status(404).json({ error: '处方不存在' });

    // 权限校验
    if (prescription.patient_id !== req.user.id && prescription.doctor_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: '无权限查看' });
    }

    const items = await query(
      'SELECT * FROM prescription_items WHERE prescription_id = ? ORDER BY id',
      [req.params.id]
    );

    res.json({ prescription, items });
  } catch (error) {
    console.error('获取处方详情失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/prescriptions/my - 医生获取个人处方列表
 */
router.get('/my', async (req, res) => {
  try {
    const { page = 1, pageSize = 20 } = req.query;
    const offset = (page - 1) * pageSize;

    const prescriptions = await query(`
      SELECT p.*, u.name as patient_name
      FROM prescriptions p
      JOIN users u ON u.id = p.patient_id
      WHERE p.doctor_id = ?
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `, [req.user.id, parseInt(pageSize), offset]);

    const [{ total }] = await query(
      'SELECT COUNT(*) as total FROM prescriptions WHERE doctor_id = ?',
      [req.user.id]
    );

    res.json({
      success: true,
      data: prescriptions,
      total,
    });
  } catch (error) {
    console.error('获取处方列表失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

module.exports = router;
