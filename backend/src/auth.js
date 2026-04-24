// 用户认证和授权工具
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const validator = require('validator');
const { userQueries } = require('./db');
require('dotenv').config();

// JWT密钥
const JWT_SECRET = process.env.JWT_SECRET || 'yixiaoban_jwt_secret_2024';
const JWT_EXPIRES_IN = '7d'; // Token有效期7天

// 密码加密
async function hashPassword(password) {
  const salt = await bcrypt.genSalt(10);
  return await bcrypt.hash(password, salt);
}

// 验证密码
async function verifyPassword(password, hashedPassword) {
  return await bcrypt.compare(password, hashedPassword);
}

// 生成JWT令牌
function generateToken(user) {
  const payload = {
    id: user.id,
    phone: user.phone,
    name: user.name,
    role: user.role
  };
  
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

// 验证JWT令牌
function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
}

// 用户注册（带验证码）
async function register(userData) {
  const { phone, password, name, smsCode, role = 'patient' } = userData;
  
  // 验证输入
  if (!phone || !password || !name || !smsCode) {
    throw new Error('手机号、密码、姓名和验证码不能为空');
  }
  
  if (!validator.isMobilePhone(phone, 'zh-CN')) {
    throw new Error('请输入有效的手机号');
  }
  
  if (password.length < 6) {
    throw new Error('密码长度不能少于6位');
  }
  
  if (smsCode.length !== 6 || !/^\d{6}$/.test(smsCode)) {
    throw new Error('验证码必须是6位数字');
  }
  
  // 检查用户是否已存在
  const existingUser = await userQueries.findByPhone(phone);
  if (existingUser) {
    throw new Error('该手机号已被注册');
  }
  
  // 验证短信验证码（生产环境需要实现）
  // 这里简化处理，实际应该调用短信验证服务
  console.log(`[注册] 验证码验证: ${phone} - ${smsCode}`);
  
  // 加密密码
  const password_hash = await hashPassword(password);
  
  // 创建用户
  const user = await userQueries.create({
    phone,
    password_hash,
    name,
    role
  });
  
  // 生成令牌
  const token = generateToken(user);
  
  return {
    success: true,
    message: '注册成功',
    data: {
      token,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        role: user.role,
        createdAt: user.created_at
      }
    }
  };
}

// 用户登录
async function login(phone, password) {
  // 验证输入
  if (!phone || !password) {
    throw new Error('手机号和密码不能为空');
  }
  
  // 查找用户
  const user = await userQueries.findByPhone(phone);
  if (!user) {
    throw new Error('用户不存在或密码错误');
  }
  
  // 检查用户状态
  if (user.status !== 'active') {
    throw new Error('用户账户已被禁用');
  }
  
  // 验证密码
  const isValidPassword = await verifyPassword(password, user.password_hash);
  if (!isValidPassword) {
    throw new Error('用户不存在或密码错误');
  }
  
  // 生成令牌
  const token = generateToken(user);
  
  // 返回用户信息（排除密码）
  const { password_hash, ...userWithoutPassword } = user;
  
  return {
    success: true,
    message: '登录成功',
    data: {
      token,
      user: userWithoutPassword
    }
  };
}

// 获取当前用户信息
async function getCurrentUser(userId) {
  const user = await userQueries.findById(userId);
  if (!user) {
    throw new Error('用户不存在');
  }
  
  return {
    success: true,
    data: user
  };
}

// 更新用户信息
async function updateUser(userId, updateData) {
  // 不允许更新的字段
  const disallowedFields = ['id', 'phone', 'password_hash', 'role', 'created_at'];
  Object.keys(updateData).forEach(field => {
    if (disallowedFields.includes(field)) {
      delete updateData[field];
    }
  });
  
  // 如果有密码，需要加密
  if (updateData.password) {
    if (updateData.password.length < 6) {
      throw new Error('密码长度不能少于6位');
    }
    updateData.password_hash = await hashPassword(updateData.password);
    delete updateData.password;
  }
  
  const updatedUser = await userQueries.update(userId, updateData);
  
  return {
    success: true,
    message: '用户信息更新成功',
    data: updatedUser
  };
}

// 中间件：验证JWT令牌
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
  
  if (!token) {
    return res.status(401).json({
      success: false,
      message: '访问令牌缺失'
    });
  }
  
  const user = verifyToken(token);
  if (!user) {
    return res.status(403).json({
      success: false,
      message: '无效或过期的访问令牌'
    });
  }
  
  req.user = user;
  next();
}

// 中间件：检查用户角色
function authorizeRole(allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: '用户未认证'
      });
    }
    
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: '权限不足'
      });
    }
    
    next();
  };
}

// 中间件：检查资源所有权（用户只能操作自己的资源）
function authorizeOwnership(resourceType) {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: '用户未认证'
      });
    }
    
    // 管理员可以操作所有资源
    if (req.user.role === 'admin') {
      return next();
    }
    
    const resourceId = req.params.id;
    let isOwner = false;
    
    try {
      switch (resourceType) {
        case 'user':
          // 用户只能操作自己的信息
          isOwner = req.user.id === resourceId;
          break;
          
        case 'order':
          // 检查订单是否属于当前用户
          const { orderQueries } = require('./db');
          const order = await orderQueries.findById(resourceId);
          if (order) {
            isOwner = order.patient_id === req.user.id;
            
            // 陪诊师可以查看分配给自己的订单
            if (!isOwner && req.user.role === 'companion') {
              const { companionQueries } = require('./db');
              const companion = await companionQueries.findByUserId(req.user.id);
              if (companion && order.companion_id === companion.id) {
                isOwner = true;
              }
            }
          }
          break;
          
        default:
          isOwner = false;
      }
      
      if (!isOwner) {
        return res.status(403).json({
          success: false,
          message: '无权操作此资源'
        });
      }
      
      next();
    } catch (error) {
      console.error('权限检查错误:', error);
      return res.status(500).json({
        success: false,
        message: '服务器内部错误'
      });
    }
  };
}

module.exports = {
  hashPassword,
  verifyPassword,
  generateToken,
  verifyToken,
  register,
  login,
  getCurrentUser,
  updateUser,
  authenticateToken,
  authorizeRole,
  authorizeOwnership
};