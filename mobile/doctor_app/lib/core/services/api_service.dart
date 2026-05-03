import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 医生端 API 服务
class DoctorApiService {
  static const String _baseUrl = '/api';

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> _get(String path, {Map<String, String>? query}) async {
    try {
      final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body) as Map<String, dynamic>? ?? {'success': false};
    } catch (e) {
      debugPrint('GET $path 失败: $e');
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  Future<Map<String, dynamic>> _post(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body) as Map<String, dynamic>? ?? {'success': false};
    } catch (e) {
      debugPrint('POST $path 失败: $e');
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  // ===== 认证 =====
  Future<Map<String, dynamic>> login(String phone, String password) {
    return _post('/auth/login', body: {'phone': phone, 'password': password});
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) {
    return _post('/auth/register', body: data);
  }

  Future<Map<String, dynamic>> getProfile() {
    return _get('/auth/profile');
  }

  // ===== 医生认证/入驻 =====
  Future<Map<String, dynamic>> submitCertification(Map<String, dynamic> data) {
    return _post('/doctor/certification', body: data);
  }

  Future<Map<String, dynamic>> getCertificationStatus() {
    return _get('/doctor/certification');
  }

  Future<Map<String, dynamic>> setServicePricing(Map<String, dynamic> data) {
    return _post('/doctor/service-pricing', body: data);
  }

  Future<Map<String, dynamic>> getServicePricing() {
    return _get('/doctor/service-pricing');
  }

  // ===== 问诊管理 =====
  Future<List<dynamic>> getConsultations({String? status}) async {
    final res = await _get('/consultations', query: status != null ? {'status': status} : null);
    return res['success'] == true ? (res['data'] ?? []) : [];
  }

  Future<Map<String, dynamic>?> getConsultationDetail(String id) async {
    final res = await _get('/consultations/$id');
    return res['success'] == true ? res['data'] as Map<String, dynamic>? : null;
  }

  Future<Map<String, dynamic>> acceptConsultation(String id) {
    return _post('/consultations/$id/accept');
  }

  Future<Map<String, dynamic>> completeConsultation(String id, Map<String, dynamic> data) {
    return _post('/consultations/$id/complete', body: data);
  }

  // ===== 处方 =====
  Future<Map<String, dynamic>> createPrescription(String consultationId, Map<String, dynamic> data) {
    return _post('/consultations/$consultationId/prescription', body: data);
  }

  Future<Map<String, dynamic>> getMyPrescriptions({int page = 1, int pageSize = 20}) async {
    return _get('/prescriptions/my', query: {'page': '$page', 'page_size': '$pageSize'});
  }

  Future<Map<String, dynamic>?> getPrescriptionDetail(String id) async {
    final res = await _get('/prescriptions/detail/$id');
    if (res['prescription'] != null) return res as Map<String, dynamic>?;
    return null;
  }

  // ===== 消息 =====
  Future<Map<String, dynamic>> sendMessage(String consultationId, Map<String, dynamic> data) {
    return _post('/consultations/$consultationId/messages', body: data);
  }

  Future<List<dynamic>> getMessages(String consultationId) async {
    final res = await _get('/consultations/$consultationId/messages');
    return res['success'] == true ? (res['messages'] ?? []) : [];
  }

  // ===== 财务 =====
  Future<Map<String, dynamic>> getFinanceStats() {
    return _get('/doctor/finance/stats');
  }

  Future<Map<String, dynamic>> getEarnings({int page = 1, int pageSize = 20}) {
    return _get('/doctor/finance/earnings', query: {'page': '$page', 'page_size': '$pageSize'});
  }

  Future<Map<String, dynamic>> submitWithdraw(Map<String, dynamic> data) {
    return _post('/doctor/finance/withdraw', body: data);
  }

  Future<Map<String, dynamic>> getWithdrawals() {
    return _get('/doctor/finance/withdraws');
  }

  // ===== 通知 =====
  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20, bool unreadOnly = false}) async {
    if (_token == null) return {'success': false, 'data': {'notifications': [], 'pagination': {'total': 0}}};
    return _get('/realtime/notifications', query: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (unreadOnly) 'unread_only': 'true',
    });
  }

  Future<Map<String, dynamic>> markNotificationRead({String? notificationId}) async {
    if (_token == null) return {'success': false};
    return _post('/realtime/notifications/mark-read', body: notificationId != null ? {'notification_id': notificationId} : {});
  }
}
