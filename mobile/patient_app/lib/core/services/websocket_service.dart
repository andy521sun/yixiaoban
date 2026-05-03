import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/html.dart';

/// WebSocket 实时通信服务（兼容后端 ws library）
/// 支持 Flutter Web & 原生平台
class WebSocketService {
  WebSocketChannel? _channel;
  bool _connected = false;
  bool _connecting = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 10;
  String? _token;
  String? _baseWsUrl;

  /// 消息事件流
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// 连接状态流
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionController.stream;

  bool get isConnected => _connected;

  void setBaseUrl(String url) {
    _baseWsUrl = url;
  }

  /// 连接 WebSocket
  void connect(String token, {String? wsUrl}) {
    if (_connected || _connecting) return;

    _token = token;
    _connecting = true;

    try {
      // 优先使用传入的 URL，否则自动从页面 URL 推导
      String uri;
      if (wsUrl != null) {
        uri = wsUrl;
      } else if (_baseWsUrl != null) {
        uri = '$_baseWsUrl/ws?token=$token';
      } else {
        // 默认：从当前页面 host 推导
        uri = '/ws?token=$token';
      }

      debugPrint('🔌 WebSocket 连接中: ${_maskToken(uri)}');

      if (kIsWeb) {
        _channel = HtmlWebSocketChannel.connect(uri);
      } else {
        _channel = IOWebSocketChannel.connect(
          Uri.parse(uri),
          pingInterval: const Duration(seconds: 30),
        );
      }

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _connected = true;
      _connecting = false;
      _reconnectAttempts = 0;
      _connectionController.add(true);
      debugPrint('✅ WebSocket 已连接');
    } catch (e) {
      debugPrint('❌ WebSocket 连接失败: $e');
      _connecting = false;
      _connected = false;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final type = json['type'] as String?;

      if (type == 'pong' || type == 'connection_established') {
        return; // 心跳/连接成功消息忽略
      }

      _messageController.add(json);
    } catch (e) {
      debugPrint('❌ 解析 WebSocket 消息失败: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('❌ WebSocket 错误: $error');
    _connected = false;
    _connecting = false;
    _connectionController.add(false);
  }

  void _onDone() {
    debugPrint('🔌 WebSocket 已关闭');
    _connected = false;
    _connecting = false;
    _channel = null;
    _heartbeatTimer?.cancel();
    _connectionController.add(false);
    _scheduleReconnect();
  }

  void send(Map<String, dynamic> message) {
    if (_channel != null && _connected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  /// 断线重连
  void _scheduleReconnect() {
    if (_reconnectTimer != null || _reconnectAttempts >= _maxReconnectAttempts) return;
    if (_token == null || _token!.isEmpty) return;

    _reconnectAttempts++;
    final delay = Duration(seconds: (_reconnectAttempts * 2).clamp(2, 30));
    debugPrint('🔄 WebSocket 重连 ($_reconnectAttempts/$_maxReconnectAttempts) ${delay.inSeconds}s后');

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!_connected && !_connecting && _token != null) {
        connect(_token!);
      }
    });
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _connecting = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }

  String _maskToken(String uri) {
    return uri.replaceAll(RegExp(r'token=[^&]+'), 'token=***');
  }
}
