import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 患者端 API 服务
/// 连接真实后端，带 token 认证
class ApiService {
  static const String _baseUrl = '/api';

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// 通用 GET 请求
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

  /// 通用 POST 请求
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

  // ==================== 健康检查 ====================
  Future<bool> healthCheck() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/../health'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==================== 认证 ====================
  Future<Map<String, dynamic>> login(String phone, String password) {
    return _post('/auth/login', body: {'phone': phone, 'password': password});
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) {
    return _post('/auth/register', body: data);
  }

  Future<Map<String, dynamic>> getProfile() {
    return _get('/auth/profile');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) {
    return _post('/auth/profile', body: data);
  }

  // ==================== 医院 ====================
  Future<List<dynamic>> getHospitals() async {
    final res = await _get('/hospitals');
    if (res['success'] == true) return res['data'] ?? [];
    debugPrint('获取医院列表失败: ${res['message']}');
    return [];
  }

  Future<Map<String, dynamic>?> getHospitalDetail(String id) async {
    final res = await _get('/hospitals/$id');
    return res['success'] == true ? res['data'] as Map<String, dynamic>? : null;
  }

  // ==================== 陪诊师 ====================
  Future<List<dynamic>> getCompanions() async {
    final res = await _get('/companions');
    if (res['success'] == true) return res['data'] ?? [];
    debugPrint('获取陪诊师列表失败: ${res['message']}');
    return [];
  }

  Future<Map<String, dynamic>?> getCompanionDetail(String id) async {
    final res = await _get('/companions/$id');
    return res['success'] == true ? res['data'] as Map<String, dynamic>? : null;
  }

  // ==================== 订单 ====================
  /// 创建订单（需要登录 token）
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    // 需要认证
    if (_token == null) {
      return {'success': false, 'message': '请先登录'};
    }
    return _post('/orders', body: orderData);
  }

  /// 获取订单列表（需要 token）
  Future<List<dynamic>> getOrders({String? status}) async {
    if (_token == null) return [];
    final res = await _get('/orders', query: status != null ? {'status': status} : null);
    if (res['success'] == true) return res['data'] ?? [];
    debugPrint('获取订单失败: ${res['message']}');
    return [];
  }

  /// 获取订单详情
  Future<Map<String, dynamic>?> getOrderDetail(String orderId) async {
    if (_token == null) return null;
    final res = await _get('/orders/$orderId');
    if (res['success'] == true) {
      final data = res['data'];
      if (data is Map<String, dynamic>) return data['order'] as Map<String, dynamic>? ?? data;
    }
    return null;
  }

  /// 取消订单
  Future<Map<String, dynamic>> cancelOrder(String orderId, {String? reason}) async {
    if (_token == null) return {'success': false, 'message': '请先登录'};
    return _post('/orders/$orderId/cancel', body: reason != null ? {'reason': reason} : {});
  }

  // ==================== 支付 ====================
  Future<Map<String, dynamic>> createPayment(String orderId, String method, double amount) async {
    return _post('/payment/create', body: {
      'order_id': orderId,
      'payment_method': method,
      'amount': amount,
    });
  }

  Future<Map<String, dynamic>> simulatePayment(String paymentId, {String result = 'success'}) async {
    return _post('/payment/simulate/$paymentId', body: {'result': result});
  }

  Future<Map<String, dynamic>> getPaymentDetail(String paymentId) async {
    return _get('/payment/$paymentId');
  }

  // ==================== AI 问诊 ====================
  Future<Map<String, dynamic>> aiConsultation(String symptoms) async {
    return _post('/ai/consult', body: {'symptoms': symptoms});
  }

  Future<Map<String, dynamic>> aiReportAnalysis(String text, String type) async {
    return _post('/ai/report', body: {'report_text': text, 'report_type': type});
  }

  // ==================== 在线问诊 ====================
  Future<Map<String, dynamic>> createConsultation(Map<String, dynamic> data) async {
    if (_token == null) return {'success': false, 'message': '请先登录'};
    return _post('/consultations', body: data);
  }

  Future<List<dynamic>> getConsultations({String? status}) async {
    if (_token == null) return [];
    final res = await _get('/consultations', query: status != null ? {'status': status} : null);
    if (res['success'] == true) return res['data'] ?? [];
    return [];
  }

  Future<Map<String, dynamic>?> getConsultationDetail(String id) async {
    if (_token == null) return null;
    final res = await _get('/consultations/$id');
    return res['success'] == true ? res['data'] as Map<String, dynamic>? : null;
  }

  Future<List<dynamic>> getDoctors({String? department}) async {
    final res = await _get('/doctors/list', query: department != null ? {'department': department} : null);
    if (res['success'] == true) return res['data'] ?? [];
    return [];
  }

  Future<Map<String, dynamic>?> getDoctorDetail(String id) async {
    final res = await _get('/doctors/$id');
    return res['success'] == true ? res['data'] as Map<String, dynamic>? : null;
  }

  // ==================== 内容安全 ====================
  Future<Map<String, dynamic>> submitReport(Map<String, dynamic> data) async {
    if (_token == null) return {'success': false, 'message': '请先登录'};
    return _post('/content/report', body: data);
  }

  Future<List<dynamic>> getMyReports() async {
    if (_token == null) return [];
    final res = await _get('/content/reports/my');
    if (res['success'] == true) return res['data'] ?? [];
    return [];
  }

  // ==================== 通知 ====================
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
