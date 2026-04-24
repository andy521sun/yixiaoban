import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/theme_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../ui/widgets/buttons/primary_button.dart';
import '../../../ui/widgets/inputs/text_input_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _smsCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreedToTerms = false;
  
  int _countdown = 0;
  Timer? _timer;
  
  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _smsCodeController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  // 发送验证码
  Future<void> _sendSMSCode() async {
    final phone = _phoneController.text.trim();
    
    if (phone.isEmpty || !RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入有效的手机号'),
          backgroundColor: AppConfig.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      _countdown = 60;
    });
    
    // 开始倒计时
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.sendSMSCode(phone, 'register');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('验证码已发送'),
          backgroundColor: AppConfig.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('发送失败: $e'),
          backgroundColor: AppConfig.errorColor,
        ),
      );
      setState(() {
        _countdown = 0;
      });
      _timer?.cancel();
    }
  }
  
  // 处理注册
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请同意用户协议和隐私政策'),
          backgroundColor: AppConfig.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();
      final smsCode = _smsCodeController.text.trim();
      
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // 调用注册API
      final result = await apiService.register(
        phone: phone,
        password: password,
        name: name,
        smsCode: smsCode,
      );
      
      // 更新认证状态
      authService.setUser(result['user']);
      authService.setToken(result['token']);
      
      // 跳转到首页
      Get.offAllNamed('/');
      
      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('注册成功，欢迎使用医小伴！'),
          backgroundColor: AppConfig.successColor,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('注册失败: $e'),
          backgroundColor: AppConfig.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 跳转到登录页面
  void _goToLogin() {
    Get.back();
  }
  
  // 查看用户协议
  void _viewTerms() {
    // TODO: 打开用户协议页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('用户协议页面开发中'),
        backgroundColor: AppConfig.infoColor,
      ),
    );
  }
  
  // 查看隐私政策
  void _viewPrivacy() {
    // TODO: 打开隐私政策页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('隐私政策页面开发中'),
        backgroundColor: AppConfig.infoColor,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 返回按钮
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(Icons.arrow_back),
                color: ThemeConfig.getTextColor(context),
              ),
              
              const SizedBox(height: 40),
              
              // 标题
              Text(
                '创建账号',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '加入医小伴，享受专业陪诊服务',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeConfig.getSecondaryTextColor(context),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 注册表单
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 姓名输入
                    TextInputField(
                      controller: _nameController,
                      label: '姓名',
                      hintText: '请输入您的姓名',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入姓名';
                        }
                        if (value.length < 2) {
                          return '姓名至少2个字符';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 手机号输入
                    TextInputField(
                      controller: _phoneController,
                      label: '手机号',
                      hintText: '请输入手机号',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入手机号';
                        }
                        if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                          return '请输入有效的手机号';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 验证码输入
                    Row(
                      children: [
                        Expanded(
                          child: TextInputField(
                            controller: _smsCodeController,
                            label: '验证码',
                            hintText: '请输入验证码',
                            prefixIcon: Icons.sms,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入验证码';
                              }
                              if (value.length != 6) {
                                return '验证码为6位数字';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          margin: const EdgeInsets.only(top: 24),
                          child: ElevatedButton(
                            onPressed: _countdown > 0 ? null : _sendSMSCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _countdown > 0
                                  ? Colors.grey[300]
                                  : AppConfig.primaryColor,
                              foregroundColor: _countdown > 0
                                  ? Colors.grey[600]
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _countdown > 0 ? '${_countdown}s后重发' : '发送验证码',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 密码输入
                    TextInputField(
                      controller: _passwordController,
                      label: '密码',
                      hintText: '请输入密码（至少6位）',
                      prefixIcon: Icons.lock,
                      obscureText: !_showPassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                        icon: Icon(
                          _showPassword ? Icons.visibility : Icons.visibility_off,
                          color: ThemeConfig.getSecondaryTextColor(context),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        if (value.length < 6) {
                          return '密码至少6位';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 确认密码输入
                    TextInputField(
                      controller: _confirmPasswordController,
                      label: '确认密码',
                      hintText: '请再次输入密码',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_showConfirmPassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: ThemeConfig.getSecondaryTextColor(context),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请确认密码';
                        }
                        if (value != _passwordController.text) {
                          return '两次输入的密码不一致';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 用户协议同意
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                          activeColor: AppConfig.primaryColor,
                        ),
                        Expanded(
                          child: Wrap(
                            children: [
                              Text(
                                '我已阅读并同意',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _viewTerms,
                                child: Text(
                                  '《用户协议》',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppConfig.primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '和',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _viewPrivacy,
                                child: Text(
                                  '《隐私政策》',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppConfig.primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 注册按钮
                    PrimaryButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      text: _isLoading ? '注册中...' : '注册',
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 登录提示
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '已有账号？',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ThemeConfig.getSecondaryTextColor(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _goToLogin,
                          child: Text(
                            '立即登录',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppConfig.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // 快速注册提示
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConfig.infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppConfig.infoColor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppConfig.infoColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '注册提示',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppConfig.infoColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '注册后您可以：\n• 预约专业陪诊服务\n• 查看医院和医生信息\n• 管理您的就医记录\n• 享受会员专属优惠',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ThemeConfig.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}