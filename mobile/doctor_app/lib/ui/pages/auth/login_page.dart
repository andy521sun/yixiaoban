import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/core/providers/doctor_state.dart';

/// 医生端登录页
class DoctorLoginPage extends StatefulWidget {
  const DoctorLoginPage({super.key});

  @override
  State<DoctorLoginPage> createState() => _DoctorLoginPageState();
}

class _DoctorLoginPageState extends State<DoctorLoginPage> {
  final _phoneController = TextEditingController(text: '13800000000');
  final _passwordController = TextEditingController(text: 'test123456');
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showSnack('请输入手机号和密码');
      return;
    }

    setState(() => _loading = true);

    final state = context.read<DoctorAppState>();
    final res = await state.api.login(phone, password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final token = data['token'] as String? ?? '';

      state.setToken(token);
      state.setLoggedIn(true);
      state.setDoctorName(user['name'] as String? ?? '');

      // 检查认证状态
      _checkCertification(state);
    } else {
      _showSnack(res['message'] as String? ?? '登录失败');
    }
  }

  Future<void> _checkCertification(DoctorAppState state) async {
    final certRes = await state.api.getCertificationStatus();
    if (mounted) {
      if (certRes['success'] == true) {
        final cert = certRes['data'] as Map<String, dynamic>?;
        if (cert != null) {
          state.setCertStatus(cert['status'] as String? ?? 'pending');
          state.setDoctorInfo(
            title: cert['title'] as String?,
            department: cert['department'] as String?,
            hospital: cert['hospital'] as String?,
          );
        }
      }
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.medical_services_rounded, size: 36, color: Color(0xFF1A73E8)),
              ),
              const SizedBox(height: 24),
              const Text('医生登录', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('医小伴医生端 — 在线接诊，随时服务', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              const SizedBox(height: 40),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('登录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
