import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final authService = context.read<AuthService>();
      final success = await authService.login(
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (success) {
        // 根据用户角色跳转到不同页面
        final user = authService.user;
        if (user?.role == 'companion') {
          context.go('/companion/home');
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登录失败，请检查手机号或密码')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60.h),
              
              // 标题
              Text(
                '欢迎回来',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '登录医小伴，开启温暖陪诊服务',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              SizedBox(height: 48.h),
              
              // 登录表单
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _phoneController,
                      label: '手机号',
                      hintText: '请输入手机号',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入手机号';
                        }
                        if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                          return '请输入正确的手机号';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),
                    
                    AppTextField(
                      controller: _passwordController,
                      label: '密码',
                      hintText: '请输入密码',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword 
                            ? Icons.visibility_off 
                            : Icons.visibility,
                          color: AppColors.gray400,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
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
                    SizedBox(height: 16.h),
                    
                    // 忘记密码
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: 跳转到忘记密码页面
                        },
                        child: Text(
                          '忘记密码？',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    
                    // 登录按钮
                    AppButton(
                      text: '登录',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    SizedBox(height: 24.h),
                    
                    // 注册引导
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '还没有账号？',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: Text(
                            '立即注册',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40.h),
              
              // 其他登录方式
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AppColors.gray300),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      '其他登录方式',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AppColors.gray300),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              
              // 微信登录
              AppButton.outline(
                text: '微信登录',
                icon: Icons.wechat,
                onPressed: () {
                  // TODO: 微信登录
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}