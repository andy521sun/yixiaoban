import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import 'storage_service.dart';

class WebSocketService extends ChangeNotifier {
  static WebSocketService? _instance;
  io.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final int _reconnectDelay = 3000; // 3秒
  
  // 消息队列（连接断开时缓存消息）
  final List<Map<String, dynamic>> _messageQueue = [];
  
  // 事件监听器
  final Map<String, List<Function>> _eventListeners = {};
  
  // 单例模式
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }
  
  WebSocketService._internal();
  
  // 获取连接状态
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  
  // 初始化WebSocket连接
  Future<void> connect() async {
    if (_isConnecting || _isConnected) {
      return;
    }
    
    final token = StorageService.getToken();
    if (token == null) {
      debugPrint('🔐 未找到认证令牌，无法连接WebSocket');
      return;
    }
    
    _isConnecting = true;
    notifyListeners();
    
    try {
      // 创建Socket连接
      _socket = io.io(
        AppConfig.wsBaseUrl,
        io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setQuery({'token': token})
          .build(),
      );
      
      // 设置事件监听器
      _setupEventListeners();
      
      // 连接Socket
      _socket!.connect();
      
      debugPrint('🔌 WebSocket连接中...');
    } catch (e) {
      _isConnecting = false;
      notifyListeners();
      debugPrint('❌ WebSocket连接失败: $e');
      _scheduleReconnect();
    }
  }
  
  // 设置事件监听器
  void _setupEventListeners() {
    if (_socket == null) return;
    
    // 连接成功
    _socket!.onConnect((_) {
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _cancelReconnectTimer();
      
      debugPrint('✅ WebSocket连接成功');
      
      // 发送队列中的消息
      _flushMessageQueue();
      
      notifyListeners();
      
      // 触发连接成功事件
      _emitEvent(AppConfig.WsEvents.connectionEstablished, {
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    
    // 连接断开
    _socket!.onDisconnect((_) {
      _isConnected = false;
      _isConnecting = false;
      
      debugPrint('🔌 WebSocket连接断开');
      
      notifyListeners();
      _scheduleReconnect();
    });
    
    // 连接错误
    _socket!.onConnectError((data) {
      _isConnecting = false;
      debugPrint('❌ WebSocket连接错误: $data');
      
      notifyListeners();
      _scheduleReconnect();
    });
    
    // 接收消息
    _socket!.on('message', (data) {
      _handleIncomingMessage(data);
    });
    
    // 特定事件监听
    _setupSpecificEventListeners();
  }
  
  // 设置特定事件监听器
  void _setupSpecificEventListeners() {
    if (_socket == null) return;
    
    // 聊天消息
    _socket!.on(AppConfig.WsEvents.chatMessage, (data) {
      _handleChatMessage(data);
    });
    
    // 消息已发送回执
    _socket!.on(AppConfig.WsEvents.messageSent, (data) {
      _emitEvent(AppConfig.WsEvents.messageSent, data);
    });
    
    // 消息已读回执
    _socket!.on(AppConfig.WsEvents.messageRead, (data) {
      _emitEvent(AppConfig.WsEvents.messageRead, data);
    });
    
    // 输入状态
    _socket!.on(AppConfig.WsEvents.typing, (data) {
      _emitEvent(AppConfig.WsEvents.typing, data);
    });
    
    // 通话请求
    _socket!.on(AppConfig.WsEvents.callRequest, (data) {
      _emitEvent(AppConfig.WsEvents.callRequest, data);
    });
    
    // 通话响应
    _socket!.on(AppConfig.WsEvents.callResponse, (data) {
      _emitEvent(AppConfig.WsEvents.callResponse, data);
    });
    
    // 通话建立
    _socket!.on(AppConfig.WsEvents.callEstablished, (data) {
      _emitEvent(AppConfig.WsEvents.callEstablished, data);
    });
    
    // 用户状态更新
    _socket!.on(AppConfig.WsEvents.userStatus, (data) {
      _emitEvent(AppConfig.WsEvents.userStatus, data);
    });
    
    // 订单通知
    _socket!.on(AppConfig.WsEvents.orderNotification, (data) {
      _emitEvent(AppConfig.WsEvents.orderNotification, data);
    });
    
    // 系统通知
    _socket!.on(AppConfig.WsEvents.systemNotification, (data) {
      _emitEvent(AppConfig.WsEvents.systemNotification, data);
    });
    
    // 错误
    _socket!.on(AppConfig.WsEvents.error, (data) {
      _emitEvent(AppConfig.WsEvents.error, data);
    });
    
    // 心跳响应
    _socket!.on(AppConfig.WsEvents.pong, (data) {
      _emitEvent(AppConfig.WsEvents.pong, data);
    });
  }
  
  // 处理接收到的消息
  void _handleIncomingMessage(dynamic data) {
    try {
      if (data is String) {
        final message = json.decode(data);
        _dispatchMessage(message);
      } else if (data is Map) {
        _dispatchMessage(data);
      }
    } catch (e) {
      debugPrint('❌ 解析WebSocket消息失败: $e, data: $data');
    }
  }
  
  // 分发消息
  void _dispatchMessage(Map<String, dynamic> message) {
    final type = message['type'];
    final data = message['data'];
    
    if (type != null) {
      _emitEvent(type, data);
    }
  }
  
  // 处理聊天消息
  void _handleChatMessage(dynamic data) {
    _emitEvent(AppConfig.WsEvents.chatMessage, data);
  }
  
  // 发送消息
  void sendMessage(String type, Map<String, dynamic> data) {
    final message = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (_isConnected && _socket != null) {
      _socket!.emit('message', json.encode(message));
      
      if (AppConfig.enableLogging) {
        debugPrint('📤 WebSocket发送消息: $type');
      }
    } else {
      // 连接断开，将消息加入队列
      _messageQueue.add(message);
      debugPrint('📦 消息加入队列 (连接断开): $type');
      
      // 尝试重新连接
      if (!_isConnecting) {
        connect();
      }
    }
  }
  
  // 发送聊天消息
  void sendChatMessage({
    required String receiverId,
    required String content,
    String? orderId,
    String messageType = 'text',
  }) {
    sendMessage('chat_message', {
      'receiverId': receiverId,
      'content': content,
      'orderId': orderId,
      'messageType': messageType,
    });
  }
  
  // 发送输入状态
  void sendTypingStatus({
    required String receiverId,
    required bool isTyping,
    String? orderId,
  }) {
    sendMessage('typing', {
      'receiverId': receiverId,
      'isTyping': isTyping,
      'orderId': orderId,
    });
  }
  
  // 发送已读回执
  void sendReadReceipt(String messageId) {
    sendMessage('read_receipt', {
      'messageId': messageId,
    });
  }
  
  // 发送通话请求
  void sendCallRequest({
    required String receiverId,
    String? orderId,
    String callType = 'audio',
  }) {
    sendMessage('call_request', {
      'receiverId': receiverId,
      'orderId': orderId,
      'callType': callType,
    });
  }
  
  // 发送通话响应
  void sendCallResponse({
    required String callId,
    required bool accepted,
    String reason = '',
  }) {
    sendMessage('call_response', {
      'callId': callId,
      'accepted': accepted,
      'reason': reason,
    });
  }
  
  // 发送心跳
  void sendPing() {
    sendMessage('ping', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  // 断开连接
  void disconnect() {
    _cancelReconnectTimer();
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.clearListeners();
      _socket = null;
    }
    
    _isConnected = false;
    _isConnecting = false;
    _messageQueue.clear();
    
    debugPrint('🔌 WebSocket手动断开连接');
    notifyListeners();
  }
  
  // 安排重连
  void _scheduleReconnect() {
    if (_reconnectTimer != null || _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }
    
    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;
    
    debugPrint('🔄 安排重连 ($_reconnectAttempts/$_maxReconnectAttempts) 在 ${delay}ms 后');
    
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      _reconnectTimer = null;
      if (!_isConnected && !_isConnecting) {
        connect();
      }
    });
  }
  
  // 取消重连定时器
  void _cancelReconnectTimer() {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }
  }
  
  // 清空消息队列
  void _flushMessageQueue() {
    if (_messageQueue.isEmpty) return;
    
    debugPrint('📦 发送队列中的 ${_messageQueue.length} 条消息');
    
    for (final message in _messageQueue) {
      if (_socket != null) {
        _socket!.emit('message', json.encode(message));
      }
    }
    
    _messageQueue.clear();
  }
  
  // 添加事件监听器
  void addEventListener(String event, Function callback) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    _eventListeners[event]!.add(callback);
  }
  
  // 移除事件监听器
  void removeEventListener(String event, Function callback) {
    if (_eventListeners.containsKey(event)) {
      _eventListeners[event]!.remove(callback);
    }
  }
  
  // 触发事件
  void _emitEvent(String event, dynamic data) {
    if (_eventListeners.containsKey(event)) {
      for (final callback in _eventListeners[event]!) {
        try {
          callback(data);
        } catch (e) {
          debugPrint('❌ 事件监听器执行失败 ($event): $e');
        }
      }
    }
    
    // 同时通过ChangeNotifier通知
    notifyListeners();
  }
  
  // 清理资源
  void dispose() {
    disconnect();
    _eventListeners.clear();
    super.dispose();
  }
}