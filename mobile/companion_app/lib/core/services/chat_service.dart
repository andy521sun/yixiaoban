import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/chat_message.dart';

/// 聊天服务 - 管理聊天历史、WebSocket通信
class ChatService {
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

  /// 获取聊天历史
  Future<List<ChatMessage>> getChatHistory({
    required String otherUserId,
    String? orderId,
    int limit = 50,
    int page = 1,
  }) async {
    try {
      final params = {
        'otherUserId': otherUserId,
        'limit': limit.toString(),
        'page': page.toString(),
      };
      if (orderId != null) params['orderId'] = orderId;

      final uri = Uri.parse('${AppConfig.baseUrl}/realtime/chat/history')
          .replace(queryParameters: params);

      final res = await _client.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final messages = data['data']?['messages'] as List? ?? [];
          return messages.map((m) => ChatMessage.fromJson(m)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('获取聊天历史失败: $e');
      return [];
    }
  }

  /// 获取对话列表（会话列表）
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final res = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/realtime/chat/conversations'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          return (data['data']?['conversations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('获取对话列表失败: $e');
      return [];
    }
  }

  /// 通过HTTP发送消息（WebSocket的备用方案）
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
    String? orderId,
    String messageType = 'text',
  }) async {
    try {
      final res = await _client.post(
        Uri.parse('${AppConfig.baseUrl}/realtime/chat/send'),
        headers: _headers,
        body: jsonEncode({
          'receiver_id': receiverId,
          'content': content,
          'message_type': messageType,
          'order_id': orderId,
        }),
      );
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('发送消息失败: $e');
      return false;
    }
  }

  /// 标记消息已读
  Future<bool> markAsRead(String otherUserId) async {
    try {
      final res = await _client.post(
        Uri.parse('${AppConfig.baseUrl}/realtime/chat/mark-read'),
        headers: _headers,
        body: jsonEncode({'other_user_id': otherUserId}),
      );
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('标记已读失败: $e');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
