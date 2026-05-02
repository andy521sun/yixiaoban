/**
 * 内容安全 API
 * 
 * 功能：
 * - 问诊内容举报/审核（content_reports 表）
 * - 敏感词过滤（内存 + config 表）
 * 
 * 路由挂载点：/api/content 和 /api/admin/content
 */

const express = require('express');
const router = express.Router();
const auth = require('../auth');

// ============================================================
// 敏感词过滤（内存缓存）
// ============================================================
const sensitiveWords = new Set([
  // 涉政类
  '法轮功', '天安门', '六四', '藏独', '疆独', '台独', '港独',
  // 涉黄类
  '色情', '裸聊', '一夜情', '约炮', '援交',
  // 涉赌类
  '赌博', '赌场', '六合彩', '时时彩',
  // 涉毒类
  '毒品', '冰毒', '海洛因', '吸毒',
  // 涉医违规类
  '代孕', '卖卵', '卖肾', '器官买卖', '非法堕胎',
  // 广告/诈骗类
  '微信号', 'QQ号', '刷单', '传销',
]);

/// 从文字中检测敏感词
function checkSensitiveWords(text) {
  if (!text || typeof text !== 'string') return { hasSensitive: false, matchedWords: [] };
  const matched = [];
  for (const word of sensitiveWords) {
    if (text.includes(word)) {
      matched.push(word);
    }
  }
  return {
    hasSensitive: matched.length > 0,
    matchedWords: matched
  };
}

/// 过滤敏感词（将敏感词替换为 ***）
function filterSensitiveWords(text, replacement = '***') {
  if (!text || typeof text !== 'string') return text;
  let result = text;
  for (const word of sensitiveWords) {
    if (result.includes(word)) {
      result = result.replaceAll(word, replacement);
    }
  }
  return result;
}

// ============================================================
// 举报 API（患者端）
// ============================================================

/// POST /api/content/report - 提交内容举报
router.post('/report', auth.authenticateToken, async (req, res) => {
  try {
    const { content_type, content_id, reason, description } = req.body;
    
    if (!content_type || !content_id || !reason) {
      return res.status(400).json({ success: false, message: '缺少必要参数：content_type, content_id, reason' });
    }
    
    const validTypes = ['consultation_message', 'review', 'comment', 'image', 'other'];
    if (!validTypes.includes(content_type)) {
      return res.status(400).json({ success: false, message: `无效的举报类型，支持: ${validTypes.join(', ')}` });
    }
    
    const { query } = require('../db');
    
    const existing = await query(
      'SELECT id FROM content_reports WHERE reporter_id = ? AND content_type = ? AND content_id = ? AND status = "pending"',
      [req.user.id, content_type, content_id]
    );
    
    if (existing.length > 0) {
      return res.status(409).json({ success: false, message: '您已举报过该内容，请等待审核', data: { report_id: existing[0].id } });
    }
    
    const result = await query(
      'INSERT INTO content_reports (reporter_id, content_type, content_id, reason, description, status, created_at) VALUES (?, ?, ?, ?, ?, "pending", NOW())',
      [req.user.id, content_type, content_id, reason, description || null]
    );
    
    console.log(`[举报] 用户 ${req.user.id} 举报 ${content_type}#${content_id}，原因: ${reason}`);
    
    res.status(201).json({
      success: true,
      message: '举报已提交，等待审核',
      data: { report_id: result.insertId }
    });
  } catch (error) {
    console.error('提交举报失败:', error);
    res.status(500).json({ success: false, message: '提交举报失败', error: error.message });
  }
});

/// GET /api/content/reports/my - 查询自己的举报记录
router.get('/reports/my', auth.authenticateToken, async (req, res) => {
  try {
    const { query } = require('../db');
    const reports = await query(
      'SELECT id, content_type, content_id, reason, description, status, created_at, updated_at FROM content_reports WHERE reporter_id = ? ORDER BY created_at DESC',
      [req.user.id]
    );
    res.json({ success: true, data: reports });
  } catch (error) {
    console.error('查询举报记录失败:', error);
    res.status(500).json({ success: false, message: '查询失败', error: error.message });
  }
});

// ============================================================
// 敏感词检查 API
// ============================================================

/// POST /api/content/check-text - 文本内容安全检查（所有登录用户）
router.post('/check-text', auth.authenticateToken, async (req, res) => {
  try {
    const { text, scope } = req.body;
    if (!text) {
      return res.status(400).json({ success: false, message: '请提供待检查的文本' });
    }
    const result = checkSensitiveWords(text);
    res.json({
      success: true,
      data: {
        safe: !result.hasSensitive,
        hasSensitive: result.hasSensitive,
        matchedWords: result.matchedWords,
        filteredText: filterSensitiveWords(text)
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: '检查失败', error: error.message });
  }
});

// ============================================================
// 管理后台：举报审核 API
// ============================================================

/// GET /api/admin/content/reports - 举报列表（管理员）
router.get('/reports', auth.authenticateToken, auth.authorizeRole(['admin']), async (req, res) => {
  try {
    const { query } = require('../db');
    const { status, content_type, page = 1, page_size = 20 } = req.query;
    
    let sql = `
      SELECT cr.*, u.name as reporter_name, u.phone as reporter_phone
      FROM content_reports cr
      LEFT JOIN users u ON cr.reporter_id = u.id
      WHERE 1=1
    `;
    const params = [];
    
    if (status) {
      sql += ' AND cr.status = ?';
      params.push(status);
    }
    if (content_type) {
      sql += ' AND cr.content_type = ?';
      params.push(content_type);
    }
    
    sql += ' ORDER BY cr.created_at DESC';
    
    const offset = (page - 1) * page_size;
    sql += ' LIMIT ? OFFSET ?';
    params.push(parseInt(page_size), parseInt(offset));
    
    const reports = await query(sql, params);
    
    let countSql = 'SELECT COUNT(*) as total FROM content_reports cr WHERE 1=1';
    const countParams = [];
    if (status) { countSql += ' AND cr.status = ?'; countParams.push(status); }
    if (content_type) { countSql += ' AND cr.content_type = ?'; countParams.push(content_type); }
    const countResult = await query(countSql, countParams);
    
    res.json({
      success: true,
      data: reports,
      pagination: {
        page: parseInt(page),
        page_size: parseInt(page_size),
        total: countResult[0].total,
        total_pages: Math.ceil(countResult[0].total / page_size)
      }
    });
  } catch (error) {
    console.error('查询举报列表失败:', error);
    res.status(500).json({ success: false, message: '查询失败', error: error.message });
  }
});

/// POST /api/admin/content/reports/:id/review - 审核举报
router.post('/reports/:id/review', auth.authenticateToken, auth.authorizeRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { action, admin_remark } = req.body; // action: approved | dismissed
    
    if (!action || !['approved', 'dismissed'].includes(action)) {
      return res.status(400).json({ success: false, message: '请指定审核结果：approved 或 dismissed' });
    }
    
    const { query } = require('../db');
    
    const reports = await query('SELECT * FROM content_reports WHERE id = ?', [id]);
    if (reports.length === 0) {
      return res.status(404).json({ success: false, message: '举报记录不存在' });
    }
    
    const report = reports[0];
    if (report.status !== 'pending') {
      return res.status(400).json({ success: false, message: '该举报已被处理' });
    }
    
    await query(
      'UPDATE content_reports SET status = ?, reviewed_by = ?, action_taken = ?, reviewed_at = NOW() WHERE id = ?',
      [action === 'approved' ? 'approved' : 'dismissed', req.user.id, admin_remark || null, id]
    );
    
    if (action === 'approved') {
      const actionTaken = [];
      
      if (report.content_type === 'consultation_message') {
        await query(
          'UPDATE consultation_messages SET content = "[该消息因违规已被屏蔽]", message_type = "system", is_deleted = 1, updated_at = NOW() WHERE id = ?',
          [report.content_id]
        );
        actionTaken.push('违规消息已屏蔽');
      }
      
      console.log(`[举报审核] 管理员 ${req.user.id} 核实举报 #${id}，已处理 ${report.content_type}#${report.content_id}`);
      res.json({ success: true, message: '审核完成，已对违规内容进行处理', data: { action_taken: actionTaken } });
    } else {
      res.json({ success: true, message: '已驳回该举报' });
    }
  } catch (error) {
    console.error('审核举报失败:', error);
    res.status(500).json({ success: false, message: '审核失败', error: error.message });
  }
});

/// GET /api/admin/content/reports/stats - 举报统计
router.get('/reports/stats', auth.authenticateToken, auth.authorizeRole(['admin']), async (req, res) => {
  try {
    const { query } = require('../db');
    
    const stats = await query(`  
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
        SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved,
        SUM(CASE WHEN status = 'dismissed' THEN 1 ELSE 0 END) as dismissed,
        COUNT(DISTINCT reporter_id) as unique_reporters
      FROM content_reports
    `);
    
    const byType = await query(`
      SELECT content_type, COUNT(*) as count
      FROM content_reports
      GROUP BY content_type
      ORDER BY count DESC
    `);
    
    const byReason = await query(`
      SELECT reason, COUNT(*) as count
      FROM content_reports
      GROUP BY reason
      ORDER BY count DESC
    `);
    
    res.json({
      success: true,
      data: {
        stats: stats[0],
        by_type: byType,
        by_reason: byReason
      }
    });
  } catch (error) {
    console.error('查询举报统计失败:', error);
    console.error(err);
    res.status(500).json({ success: false, message: '查询失败', error: error.message });
  }
});

// 暴露敏感词检查函数供其他模块使用
router.checkSensitiveWords = checkSensitiveWords;
router.filterSensitiveWords = filterSensitiveWords;

module.exports = router;
