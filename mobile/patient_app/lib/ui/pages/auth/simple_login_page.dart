import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:patient_app/core/config/theme_config.dart';

class SimpleLoginPage extends StatefulWidget {
  const SimpleLoginPage({super.key});

  @override
  State<SimpleLoginPage> createState() => _SimpleLoginPageState();
}

class _SimpleLoginPageState extends State<SimpleLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      Get.snackbar(
        '提示',
        '请输入手机号和密码',
        backgroundColor: ThemeConfig.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      Get.snackbar(
        '提示',
        '请输入正确的手机号',
        backgroundColor: ThemeConfig.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 模拟登录过程
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // 登录成功，跳转到首页
    Get.offAllNamed('/home');
  }

  void _handleRegister() {
    Get.toNamed('/register');
  }

  void _handleForgetPassword() {
    Get.toNamed('/forget-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: ThemeConfig.edgeInsetsScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo和标题
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: ThemeConfig.primaryColor,
                          borderRadius:
                              BorderRadius.circular(ThemeConfig.borderRadiusMedium),
                        ),
                        child: Icon(
                          Icons.medical_services,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      SizedBox(height: ThemeConfig.spacingM),
                      Text(
                        '医小伴',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.primaryColor,
                        ),
                      ),
                      SizedBox(height: ThemeConfig.spacingXS),
                      Text(
                        '专业就医陪诊服务',
                        style: TextStyle(
                          fontSize: ThemeConfig.fontSizeBody2,
                          color: ThemeConfig.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: ThemeConfig.spacingXXL),

                // 登录表单
                Text(
                  '手机号登录',
                  style: TextStyle(
                    fontSize: ThemeConfig.fontSizeH2,
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.textPrimaryColor,
                  ),
                ),
                SizedBox(height: ThemeConfig.spacingM),

                // 手机号输入框
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: '手机号',
                    hintText: '请输入手机号',
                    prefixIcon: Icon(
                      Icons.phone_android,
                      color: ThemeConfig.textSecondaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(ThemeConfig.borderRadiusMedium),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                ),

                SizedBox(height: ThemeConfig.spacingL),

                // 密码输入框
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '密码',
                    hintText: '请输入密码',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: ThemeConfig.textSecondaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: ThemeConfig.textSecondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(ThemeConfig.borderRadiusMedium),
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),

                SizedBox(height: ThemeConfig.spacingM),

                // 忘记密码
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgetPassword,
                    child: Text(
                      '忘记密码？',
                      style: TextStyle(
                        fontSize: ThemeConfig.fontSizeBody2,
                        color: ThemeConfig.primaryColor,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: ThemeConfig.spacingXL),

                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(ThemeConfig.borderRadiusMedium),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '登录',
                            style: TextStyle(
                              fontSize: ThemeConfig.fontSizeButton,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: ThemeConfig.spacingL),

                // 注册按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _handleRegister,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ThemeConfig.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(ThemeConfig.borderRadiusMedium),
                      ),
                    ),
                    child: Text(
                      '注册账号',
                      style: TextStyle(
                        fontSize: ThemeConfig.fontSizeButton,
                        fontWeight: FontWeight.w600,
                        color: ThemeConfig.primaryColor,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: ThemeConfig.spacingXL),

                // 其他登录方式
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: ThemeConfig.borderColor,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ThemeConfig.spacingM,
                      ),
                      child: Text(
                        '其他登录方式',
                        style: TextStyle(
                          fontSize: ThemeConfig.fontSizeBody2,
                          color: ThemeConfig.textSecondaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: ThemeConfig.borderColor,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: ThemeConfig.spacingL),

                // 社交登录
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        // 微信登录
                      },
                      icon: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF07C160),
                          borderRadius: BorderRadius.circular(
                            ThemeConfig.borderRadiusMedium,
                          ),
                        ),
                        child: Icon(
                          Icons.wechat,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: ThemeConfig.spacingL),
                    IconButton(
                      onPressed: () {
                        // 支付宝登录
                      },
                      icon: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1677FF),
                          borderRadius: BorderRadius.circular(
                            ThemeConfig.borderRadiusMedium,
                          ),
                        ),
                        child: Icon(
                          Icons.payment,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: ThemeConfig.spacingXXL),

                // 用户协议
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: '登录即代表同意',
                      style: TextStyle(
                        fontSize: ThemeConfig.fontSizeCaption,
                        color: ThemeConfig.textSecondaryColor,
                      ),
                      children: [
                        TextSpan(
                          text: '《用户协议》',
                          style: TextStyle(
                            color: ThemeConfig.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: '和'),
                        TextSpan(
                          text: '《隐私政策》',
                          style: TextStyle(
                            color: ThemeConfig.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}