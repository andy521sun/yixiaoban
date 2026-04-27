import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// 结算服务
class SettlementService {
  final http.Client _client = http.Client();
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// 获取结算列表
  Future<Map<String, dynamic>> getSettlements({int page = 1, int limit = 20}) async {
    try {
      final res = await _client.get(
        Uri.parse('${AppConfig.companionUrl}/settlements?page=$page&limit=$limit'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'success': false};
    } catch (e) {
      debugPrint('获取结算记录失败: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  void dispose() {
    _client.close();
  }
}
