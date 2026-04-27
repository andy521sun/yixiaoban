import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// 评价服务
class ReviewService {
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

  /// 获取我的评价列表（收到的评价）
  Future<List<Map<String, dynamic>>> getMyReviews({int page = 1, int limit = 20}) async {
    try {
      final res = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/reviews/mine?page=$page&limit=$limit'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final list = data['data'] as List? ?? [];
          return list.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      debugPrint('获取评价失败: $e');
      return [];
    }
  }

  /// 获取评价统计
  Future<Map<String, dynamic>?> getReviewStats() async {
    try {
      final res = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/reviews/stats'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true ? data['data'] as Map<String, dynamic>? : null;
      }
      return null;
    } catch (e) {
      debugPrint('获取评价统计失败: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
