/**
 * 医小伴 v2.0 - 医生财务 API
 * 结算统计 + 提现管理
 */

const express = require('express');
const router = express.Router();
const { query, transaction } = require('../db');
const auth = require('../auth');

router.use(auth.authenticateToken);

/**
 * GET /api/doctor/finance/stats - 医生收入统计
 */
router.get('/finance/stats', async (req, res) => {
  try {
    if (req.user.role !== 'doctor' && req.user.role !== 'companion') {
      return res.status(403).json({ error: '仅医生可查看' });
    }

    const doctorId = req.user.id;

    // 本日收入（已完成问诊）
    const [todayIncome] = await query(
      `SELECT COUNT(*) as count, COALESCE(SUM(price), 0) as total
       FROM consultations c
       JOIN doctor_service_pricing dsp ON dsp.doctor_id = c.doctor_id AND dsp.service_type = CONCAT(c.consult_type, '_consult')
       WHERE c.doctor_id = ? AND c.status = 'completed' AND DATE(c.completed_at) = CURDATE()`,
      [doctorId]
    );

    // 本月收入
    const [monthIncome] = await query(
      `SELECT COUNT(*) as count, COALESCE(SUM(price), 0) as total
       FROM consultations c
       JOIN doctor_service_pricing dsp ON dsp.doctor_id = c.doctor_id AND dsp.service_type = CONCAT(c.consult_type, '_consult')
       WHERE c.doctor_id = ? AND c.status = 'completed' AND YEAR(c.completed_at) = YEAR(CURDATE()) AND MONTH(c.completed_at) = MONTH(CURDATE())`,
      [doctorId]
    );

    // 总接诊数
    const [totalStats] = await query(
      `SELECT COUNT(*) as total_consultations,
              SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_count,
              SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_count
       FROM consultations WHERE doctor_id = ?`,
      [doctorId]
    );

    // 待提现金额（可提现 = 已完成问诊的预估收入）
    const [pendingWithdraw] = await query(
      `SELECT COALESCE(SUM(dsp.price), 0) as total
       FROM consultations c
       JOIN doctor_service_pricing dsp ON dsp.doctor_id = c.doctor_id AND dsp.service_type = CONCAT(c.consult_type, '_consult')
       LEFT JOIN withdraw_requests wr ON wr.user_id = c.doctor_id AND wr.status IN ('pending', 'approved')
       WHERE c.doctor_id = ? AND c.status = 'completed'
       HAVING total > 0`,
      [doctorId]
    );

    // 已提现金额
    const [withdrawn] = await query(
      `SELECT COALESCE(SUM(actual_amount), 0) as total FROM withdraw_requests
       WHERE user_id = ? AND status = 'completed'`,
      [doctorId]
    );

    res.json({
      today: {
        count: todayIncome && todayIncome.count ? Number(todayIncome.count) : 0,
        income: todayIncome && todayIncome.total ? Number(todayIncome.total) : 0
      },
      month: {
        count: monthIncome && monthIncome.count ? Number(monthIncome.count) : 0,
        income: monthIncome && monthIncome.total ? Number(monthIncome.total) : 0
      },
      total: {
        consultations: totalStats ? Number(totalStats.total_consultations || 0) : 0,
        completed: totalStats ? Number(totalStats.completed_count || 0) : 0,
        cancelled: totalStats ? Number(totalStats.cancelled_count || 0) : 0
      },
      wallet: {
        pending_withdraw: pendingWithdraw && pendingWithdraw.total ? Number(pendingWithdraw.total) : 0,
        withdrawn: withdrawn && withdrawn.total ? Number(withdrawn.total) : 0
      }
    });
  } catch (error) {
    console.error('获取医生收入统计失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/doctor/finance/earnings - 收益明细列表
 */
router.get('/finance/earnings', async (req, res) => {
  try {
    if (req.user.role !== 'doctor' && req.user.role !== 'companion') return res.status(403).json({ error: '仅医生可查看' });

    const { page = 1, page_size = 20, start_date, end_date } = req.query;
    const offset = (page - 1) * page_size;

    let sql = `
      SELECT c.id as consultation_id, c.consult_type, c.status, c.completed_at,
             u.name as patient_name, dsp.price
      FROM consultations c
      JOIN users u ON u.id = c.patient_id
      LEFT JOIN doctor_service_pricing dsp ON dsp.doctor_id = c.doctor_id AND dsp.service_type = CONCAT(c.consult_type, '_consult')
      WHERE c.doctor_id = ?
    `;
    const params = [req.user.id];

    if (start_date) {
      sql += ' AND c.completed_at >= ?';
      params.push(start_date);
    }
    if (end_date) {
      sql += ' AND c.completed_at <= ?';
      params.push(end_date + ' 23:59:59');
    }

    sql += ' ORDER BY c.created_at DESC LIMIT ? OFFSET ?';
    params.push(Number(page_size), offset);

    const rows = await query(sql, params);
    res.json({ earnings: rows });
  } catch (error) {
    console.error('获取收益明细失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * POST /api/doctor/finance/withdraw - 申请提现
 */
router.post('/finance/withdraw', async (req, res) => {
  try {
    if (req.user.role !== 'doctor' && req.user.role !== 'companion') return res.status(403).json({ error: '仅医生可操作' });

    const { amount, bank_name, bank_card, account_name } = req.body;
    if (!amount || amount <= 0) return res.status(400).json({ error: '提现金额无效' });
    if (!bank_name || !bank_card) return res.status(400).json({ error: '请填写银行卡信息' });

    // 检查是否有正在处理的提现
    const existing = await query(
      "SELECT id, amount FROM withdraw_requests WHERE user_id = ? AND status IN ('pending', 'approved')",
      [req.user.id]
    );
    if (existing.length > 0) {
      return res.status(400).json({ error: `已有 ${existing.length} 笔提现在处理中，请等待处理完成` });
    }

    // 检查可提现余额
    const [earnings] = await query(
      `SELECT COALESCE(SUM(dsp.price), 0) as total
       FROM consultations c
       JOIN doctor_service_pricing dsp ON dsp.doctor_id = c.doctor_id AND dsp.service_type = CONCAT(c.consult_type, '_consult')
       WHERE c.doctor_id = ? AND c.status = 'completed'`,
      [req.user.id]
    );

    const [withdrawn] = await query(
      "SELECT COALESCE(SUM(actual_amount), 0) as total FROM withdraw_requests WHERE user_id = ? AND status = 'completed'",
      [req.user.id]
    );

    const available = (Number(earnings?.total || 0) - Number(withdrawn?.total || 0));
    if (amount > available) {
      return res.status(400).json({ error: `可提现余额不足，当前可提现 ¥${available.toFixed(2)}` });
    }

    const fee = Math.round(amount * 0.01 * 100) / 100; // 1% 手续费
    const actualAmount = amount - fee;

    await query(
      `INSERT INTO withdraw_requests (user_id, amount, fee, actual_amount, bank_name, bank_card, account_name, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')`,
      [req.user.id, amount, fee, actualAmount, bank_name, bank_card, account_name || req.user.name]
    );

    res.json({ message: '提现申请已提交，请等待审核', amount, fee, actual_amount: actualAmount });
  } catch (error) {
    console.error('申请提现失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

/**
 * GET /api/doctor/finance/withdraws - 提现记录
 */
router.get('/finance/withdraws', async (req, res) => {
  try {
    if (req.user.role !== 'doctor' && req.user.role !== 'companion') return res.status(403).json({ error: '仅医生可查看' });

    const rows = await query(
      'SELECT * FROM withdraw_requests WHERE user_id = ? ORDER BY created_at DESC',
      [req.user.id]
    );
    res.json({ withdraws: rows });
  } catch (error) {
    console.error('获取提现记录失败:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

module.exports = router;
