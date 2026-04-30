import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = '/api';
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ========== 认证 ==========
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  // ========== Dashboard ==========
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/dashboard/stats'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true ? data['data'] as Map<String, dynamic>? : null;
      }
      return null;
    } catch (e) {
      debugPrint('获取Dashboard统计失败: $e');
      return null;
    }
  }

  // ========== 用户管理 ==========
  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 20, String? role, String? search}) async {
    try {
      var url = '$baseUrl/admin/users?page=$page&limit=$limit';
      if (role != null) url += '&role=$role';
      if (search != null) url += '&search=$search';
      final res = await http.get(Uri.parse(url), headers: _headers);
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: _headers,
        body: jsonEncode(data),
      );
      final r = jsonDecode(res.body);
      return r['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ========== 订单管理 ==========
  Future<Map<String, dynamic>> getOrders({int page = 1, int limit = 20, String? status}) async {
    try {
      var url = '$baseUrl/admin/orders?page=$page&limit=$limit';
      if (status != null) url += '&status=$status';
      final res = await http.get(Uri.parse(url), headers: _headers);
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/admin/orders/$orderId/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(res.body)['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ========== 医院管理 ==========
  Future<Map<String, dynamic>> getHospitals({int page = 1, int limit = 20}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/hospitals?page=$page&limit=$limit'), headers: _headers);
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> createHospital(Map<String, dynamic> data) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/admin/hospitals'), headers: _headers, body: jsonEncode(data));
      return jsonDecode(res.body)['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateHospital(String id, Map<String, dynamic> data) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/admin/hospitals/$id'), headers: _headers, body: jsonEncode(data));
      return jsonDecode(res.body)['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ========== 陪诊师管理 ==========
  Future<Map<String, dynamic>> getCompanions({int page = 1, int limit = 20}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/companions?page=$page&limit=$limit'), headers: _headers);
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  void dispose() {}
}
