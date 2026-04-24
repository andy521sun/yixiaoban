const express = require('express');
const router = express.Router();

// 模拟短信验证码存储（生产环境应该用Redis）
const smsCodes = new Map();

// 生成6位数字验证码
function generateSMSCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// 发送短信验证码
router.post('/send', async (req, res) => {
  try {
    const { phone, type = 'register' } = req.body;
    
    // 验证手机号
    if (!phone || !/^1[3-9]\d{9}$/.test(phone)) {
      return res.status(400).json({
        success: false,
        message: '请输入有效的手机号'
      });
    }
    
    // 验证类型
    const validTypes = ['register', 'login', 'reset_password', 'change_phone'];
    if (!validTypes.includes(type)) {
      return res.status(400).json({
        success: false,
        message: '无效的验证码类型'
      });
    }
    
    // 生成验证码
    const code = generateSMSCode();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5分钟有效
    
    // 存储验证码
    smsCodes.set(`${phone}:${type}`, {
      code,
      expiresAt,
      attempts: 0,
      createdAt: Date.now()
    });
    
    // 模拟发送短信（生产环境应该调用短信服务商API）
    console.log(`[SMS] 发送验证码到 ${phone}: ${code} (类型: ${type})`);
    
    // 清理过期验证码
    cleanupExpiredCodes();
    
    res.json({
      success: true,
      message: '验证码已发送',
      data: {
        phone,
        type,
        // 开发环境返回验证码，生产环境不应该返回
        code: process.env.NODE_ENV === 'development' ? code : undefined
      }
    });
    
  } catch (error) {
    console.error('发送短信验证码失败:', error);
    res.status(500).json({
      success: false,
      message: '发送验证码失败',
      error: error.message
    });
  }
});

// 验证短信验证码
router.post('/verify', async (req, res) => {
  try {
    const { phone, code, type = 'register' } = req.body;
    
    // 验证输入
    if (!phone || !code) {
      return res.status(400).json({
        success: false,
        message: '手机号和验证码不能为空'
      });
    }
    
    // 查找验证码
    const key = `${phone}:${type}`;
    const smsData = smsCodes.get(key);
    
    if (!smsData) {
      return res.status(400).json({
        success: false,
        message: '验证码不存在或已过期'
      });
    }
    
    // 检查是否过期
    if (Date.now() > smsData.expiresAt) {
      smsCodes.delete(key);
      return res.status(400).json({
        success: false,
        message: '验证码已过期'
      });
    }
    
    // 检查尝试次数
    if (smsData.attempts >= 5) {
      smsCodes.delete(key);
      return res.status(400).json({
        success: false,
        message: '验证码尝试次数过多，请重新获取'
      });
    }
    
    // 验证验证码
    if (smsData.code !== code) {
      smsData.attempts++;
      smsCodes.set(key, smsData);
      
      return res.status(400).json({
        success: false,
        message: '验证码错误',
        data: {
          remainingAttempts: 5 - smsData.attempts
        }
      });
    }
    
    // 验证成功，删除验证码
    smsCodes.delete(key);
    
    res.json({
      success: true,
      message: '验证码验证成功',
      data: {
        phone,
        type,
        verified: true
      }
    });
    
  } catch (error) {
    console.error('验证短信验证码失败:', error);
    res.status(500).json({
      success: false,
      message: '验证码验证失败',
      error: error.message
    });
  }
});

// 清理过期验证码
function cleanupExpiredCodes() {
  const now = Date.now();
  for (const [key, data] of smsCodes.entries()) {
    if (now > data.expiresAt) {
      smsCodes.delete(key);
    }
  }
}

// 定期清理过期验证码（每小时一次）
setInterval(cleanupExpiredCodes, 60 * 60 * 1000);

module.exports = router;