import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

/// 增强版陪诊师API服务
/// 支持完整接单流程 + 详细错误处理 + 日志
class CompanionApiService {
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

  /// 通用请求封装
  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    try {
      final uri = Uri.parse('$path').replace(queryParameters: query);
      late http.Response res;

      switch (method) {
        case 'GET':
          res = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
          break;
        case 'POST':
          res = await _client.post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 10));
          break;
        default:
          return {'success': false, 'message': '不支持的请求方法'};
      }

      final data = jsonDecode(res.body);
      return data is Map<String, dynamic> ? data : {'success': false, 'message': '响应格式错误'};
    } catch (e) {
      debugPrint('[$method $path] 请求失败: $e');
      return {'success': false, 'message': '网络错误: ${e.toString()}'};
    }
  }

  // ==================== 认证 ====================

  Future<Map<String, dynamic>> login(String phone, String password) async {
    return await _request('POST', '${AppConfig.authUrl}/login', body: {
      'phone': phone, 'password': password,
    });
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    return await _request('POST', '${AppConfig.authUrl}/register', body: data);
  }

  // ==================== 个人信息 ====================

  Future<Map<String, dynamic>?> getProfile() async {
    final res = await _request('GET', '${AppConfig.companionUrl}/profile');
    return res['success'] == true ? res['data'] as Map<String, dynamic>? : null;
  }

  Future<Map<String, dynamic>?> getStats() async {
    final res = await _request('GET', '${AppConfig.companionUrl}/stats');
    return res['success'] == true ? res['data'] as Map<String, dynamic>? : null;
  }

  // ==================== 订单 ====================

  /// 获取待接订单列表
  Future<List<dynamic>> getAvailableOrders() async {
    final res = await _request('GET', '${AppConfig.companionUrl}/orders/available');
    if (res['success'] == true) return res['data'] ?? [];
    debugPrint('获取待接订单失败: ${res['message']}');
    return [];
  }

  /// 获取我的任务列表
  Future<List<dynamic>> getMyOrders() async {
    final res = await _request('GET', '${AppConfig.companionUrl}/orders/mine');
    if (res['success'] == true) return res['data'] ?? [];
    debugPrint('获取我的订单失败: ${res['message']}');
    return [];
  }

  /// 获取订单详情
  Future<Map<String, dynamic>?> getOrderDetail(String orderId) async {
    final res = await _request('GET', '${AppConfig.companionUrl}/orders/$orderId/detail');
    if (res['success'] == true) return res['data'] as Map<String, dynamic>?;
    return null;
  }

  /// 接单
  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    return await _request('POST', '${AppConfig.companionUrl}/orders/$orderId/accept');
  }

  /// 开始服务
  Future<Map<String, dynamic>> startService(String orderId) async {
    return await _request('POST', '${AppConfig.companionUrl}/orders/$orderId/start');
  }

  /// 完成服务
  Future<Map<String, dynamic>> completeService(String orderId) async {
    return await _request('POST', '${AppConfig.companionUrl}/orders/$orderId/complete');
  }

  /// 取消订单
  Future<Map<String, dynamic>> cancelOrder(String orderId, {String reason = ''}) async {
    return await _request('POST', '${AppConfig.companionUrl}/orders/$orderId/cancel', body: {
      'reason': reason,
    });
  }

  // ==================== WebSocket ====================
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onNotification;

  void connectWebSocket() {
    if (_token == null) return;
    try {
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConfig.wsUrl}?token=$_token'),
      );
      _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String);
            onNotification?.call(msg);
          } catch (_) {}
        },
        onError: (e) {
          debugPrint('WebSocket 错误: $e');
          Future.delayed(const Duration(seconds: 5), connectWebSocket);
        },
        onDone: () {
          debugPrint('WebSocket 断开，5秒后重连');
          Future.delayed(const Duration(seconds: 5), connectWebSocket);
        },
      );
    } catch (e) {
      debugPrint('WebSocket 连接失败: $e');
    }
  }

  void disconnectWebSocket() {
    _channel?.sink.close();
    _channel = null;
  }

  // ==================== 通知 ====================
  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20, bool unreadOnly = false}) async {
    if (_token == null) return {'success': false, 'data': {'notifications': [], 'pagination': {'total': 0}}};
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (unreadOnly) query['unread_only'] = 'true';
    return _request('GET', '/realtime/notifications', query: query);
  }

  Future<Map<String, dynamic>> markNotificationRead({String? notificationId}) async {
    if (_token == null) return {'success': false};
    final body = notificationId != null ? <String, dynamic>{'notification_id': notificationId} : <String, dynamic>{};
    return _request('POST', '/realtime/notifications/mark-read', body: body);
  }

  void dispose() {
    disconnectWebSocket();
    _client.close();
  }
}
