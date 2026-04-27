import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// 陪诊师认证服务 - 处理登录/注册/自动恢复会话
class AuthService {
  final http.Client _client = http.Client();
  String? _token;
  Map<String, dynamic>? _currentUser;

  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final res = await _client.post(
        Uri.parse('${AppConfig.authUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final d = data['data'] ?? data;
        _token = d['token'];
        _currentUser = d['user'] as Map<String, dynamic>?;
      }
      return data;
    } catch (e) {
      debugPrint('认证服务登录失败: $e');
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  void setSession(String token, Map<String, dynamic> user) {
    _token = token;
    _currentUser = user;
  }

  void clearSession() {
    _token = null;
    _currentUser = null;
  }

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  void dispose() {
    _client.close();
  }
}
