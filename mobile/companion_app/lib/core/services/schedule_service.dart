import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// 日程服务
class ScheduleService {
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

  /// 获取指定日期的日程
  Future<List<Map<String, dynamic>>> getScheduleByDate(DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await _client.get(
        Uri.parse('${AppConfig.companionUrl}/schedule?date=$dateStr'),
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
      debugPrint('获取日程失败: $e');
      return [];
    }
  }

  /// 获取月份日程概览（仅含状态的日期）
  Future<List<Map<String, dynamic>>> getMonthOverview(int year, int month) async {
    try {
      final res = await _client.get(
        Uri.parse(
            '${AppConfig.companionUrl}/schedule/month?year=$year&month=$month'),
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
      debugPrint('获取月概览失败: $e');
      return [];
    }
  }

  void dispose() {
    _client.close();
  }
}
