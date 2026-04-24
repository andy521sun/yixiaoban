import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController(text: '13800138000');
  final _passwordController = TextEditingController(text: '123456');
  final _api = ApiService();
  bool _loading = false;
  bool _isRegister = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    if (phone.isEmpty || password.isEmpty) {
      setState(() => _error = '请填写手机号和密码');
      return;
    }

    setState(() { _loading = true; _error = null; });

    Map<String, dynamic> result;
    if (_isRegister) {
      result = await _api.register({
        'phone': phone,
        'password': password,
        'name': '用户${phone.substring(phone.length - 4)}',
      });
    } else {
      result = await _api.login(phone, password);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      final appState = context.read<AppState>();
      appState.setLoggedIn(true);
      // 兼容两种响应格式: 直接返回 {token, user} 或嵌套 {data: {token, user}}
      final data = result['data'] ?? result;
      appState.setToken(data['token'] ?? '');
      final userData = data['user'] ?? {};
      appState.setUserName(userData['name'] ?? userData['phone'] ?? '用户');
      appState.setUserPhone(phone);

      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _error = result['message'] ?? '登录失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? '注册' : '登录')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.medical_services, size: 64, color: Color(0xFF1A73E8)),
            const SizedBox(height: 16),
            const Text('医小伴', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('温暖就医 · 专业陪伴', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 48),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '手机号',
                prefixIcon: Icon(Icons.phone_android),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isRegister ? '注册' : '登录'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() { _isRegister = !_isRegister; _error = null; }),
              child: Text(_isRegister ? '已有账号？去登录' : '没有账号？去注册'),
            ),
          ],
        ),
      ),
    );
  }
}
