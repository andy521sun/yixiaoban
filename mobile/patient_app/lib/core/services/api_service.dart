import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://andysun521.online/api';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ==================== 健康检查 ====================
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/../health'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('健康检查失败: $e');
      return false;
    }
  }

  // ==================== 医院 ====================
  Future<List<dynamic>> getHospitals() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hospitals'), headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      debugPrint('获取医院列表失败: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('API错误: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getHospitalDetail(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hospitals/$id'), headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('获取医院详情失败: $e');
      return null;
    }
  }

  // ==================== 陪诊师 ====================
  Future<List<dynamic>> getCompanions() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/companions'), headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      debugPrint('获取陪诊师列表失败: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('API错误: $e');
      return [];
    }
  }

  // ==================== 用户认证 ====================
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'phone': phone, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('登录失败: $e');
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode(userData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('注册失败: $e');
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  // ==================== 订单 ====================
  Future<List<dynamic>> getOrders(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders'),
        headers: {..._headers, 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('获取订单失败: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData, {String? mock}) async {
    // 如果使用mock模式
    if (mock != null) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'success': true,
        'order_id': 'ORD${DateTime.now().millisecondsSinceEpoch}',
        'payment_info': {
          'order_id': 'ORD${DateTime.now().millisecondsSinceEpoch}',
          'amount': orderData['total_amount'] ?? 199.0,
          'currency': 'CNY',
        },
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/orders'),
        headers: _headers,
        body: jsonEncode(orderData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('创建订单失败: $e');
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  Future<Map<String, dynamic>> payOrder(String orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment/pay'),
        headers: _headers,
        body: jsonEncode({'order_id': orderId, 'payment_method': 'wechat'}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('支付失败: $e');
      return {'success': false, 'message': '网络错误: $e'};
    }
  }
}
