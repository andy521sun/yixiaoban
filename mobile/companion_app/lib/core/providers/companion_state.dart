import 'package:flutter/foundation.dart';
import '../services/api_service_enhanced.dart';
import '../services/storage_service.dart';

/// 订单状态枚举（前后端统一）
class OrderStatus {
  static const String pending = 'pending';       // 待接单
  static const String confirmed = 'confirmed';   // 已接单
  static const String inProgress = 'in_progress'; // 服务中
  static const String completed = 'completed';   // 已完成
  static const String cancelled = 'cancelled';   // 已取消
}

/// 陪诊师端全局状态 v2
/// 增强版：更好的错误处理、操作反馈、自动刷新
class CompanionState extends ChangeNotifier {
  final CompanionApiService api = CompanionApiService();
  final StorageService storage = StorageService();

  // 登录状态
  bool _loggedIn = false;
  String _token = '';
  String _userName = '';
  String _userPhone = '';

  // 数据
  List<dynamic> _availableOrders = [];
  List<dynamic> _myOrders = [];
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _profile;
  String _connectionStatus = '未连接';
  int _notificationCount = 0;

  // 操作状态
  bool _loading = false;
  String? _lastError;
  String? _lastSuccessMessage;

  // Getters
  bool get loggedIn => _loggedIn;
  String get token => _token;
  String get userName => _userName;
  String get userPhone => _userPhone;
  List<dynamic> get availableOrders => _availableOrders;
  List<dynamic> get myOrders => _myOrders;
  Map<String, dynamic>? get stats => _stats;
  Map<String, dynamic>? get profile => _profile;
  String get connectionStatus => _connectionStatus;
  int get notificationCount => _notificationCount;
  int get availableOrderCount => _availableOrders.length;
  bool get loading => _loading;
  String? get lastError => _lastError;
  String? get lastSuccessMessage => _lastSuccessMessage;

  // 清理消息
  void clearMessages() {
    _lastError = null;
    _lastSuccessMessage = null;
    notifyListeners();
  }

  // ========== 登录/登出 ==========

  void loginSuccess(String token, Map<String, dynamic> user) {
    _token = token;
    _userName = user['name'] ?? '陪诊师';
    _userPhone = user['phone'] ?? '';
    _loggedIn = true;
    api.setToken(token);
    notifyListeners();
  }

  void logout() {
    _token = '';
    _userName = '';
    _userPhone = '';
    _loggedIn = false;
    _availableOrders = [];
    _myOrders = [];
    _stats = null;
    _profile = null;
    _lastError = null;
    _lastSuccessMessage = null;
    api.disconnectWebSocket();
    notifyListeners();
  }

  // ========== WebSocket ==========

  void connectWebSocket() {
    api.onNotification = (msg) {
      try {
        final type = msg['type'] ?? '';
        if (type == 'connection_established') {
          _connectionStatus = '已连接';
          notifyListeners();
        } else if (type == 'order_notification') {
          _notificationCount++;
          _loadAllData();
        } else if (type == 'new_chat_message') {
          _notificationCount++;
          notifyListeners();
        } else if (type == 'new_order') {
          _notificationCount++;
          _loadAllData();
        } else if (type == 'pong') {
          // 心跳回复，无需处理
        }
      } catch (_) {}
    };
    api.connectWebSocket();
    _connectionStatus = '连接中...';
    notifyListeners();
  }

  void clearNotifications() {
    _notificationCount = 0;
    notifyListeners();
  }

  // ========== 数据加载 ==========

  Future<void> _loadAllData() async {
    _loading = true;
    try {
      final results = await Future.wait([
        api.getAvailableOrders(),
        api.getMyOrders(),
        api.getStats(),
        api.getProfile(),
      ]);
      _availableOrders = results[0] as List<dynamic>;
      _myOrders = results[1] as List<dynamic>;
      _stats = results[2] as Map<String, dynamic>?;
      _profile = results[3] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('数据加载错误: $e');
      _lastError = '数据加载失败';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await _loadAllData();
  }

  // ========== 订单操作 ==========

  /// 接单
  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final result = await api.acceptOrder(orderId);
    if (result['success'] == true) {
      _lastSuccessMessage = result['message'] ?? '接单成功';
      await _loadAllData();
    } else {
      _lastError = result['message'] ?? '接单失败';
    }
    notifyListeners();
    return result;
  }

  /// 开始服务
  Future<Map<String, dynamic>> startService(String orderId) async {
    final result = await api.startService(orderId);
    if (result['success'] == true) {
      _lastSuccessMessage = result['message'] ?? '已开始服务';
      await _loadAllData();
    } else {
      _lastError = result['message'] ?? '操作失败';
    }
    notifyListeners();
    return result;
  }

  /// 完成服务
  Future<Map<String, dynamic>> completeService(String orderId) async {
    final result = await api.completeService(orderId);
    if (result['success'] == true) {
      _lastSuccessMessage = result['message'] ?? '服务已完成';
      await _loadAllData();
    } else {
      _lastError = result['message'] ?? '操作失败';
    }
    notifyListeners();
    return result;
  }

  /// 取消订单
  Future<Map<String, dynamic>> cancelOrder(String orderId, {String reason = ''}) async {
    final result = await api.cancelOrder(orderId, reason: reason);
    if (result['success'] == true) {
      _lastSuccessMessage = '订单已取消';
      await _loadAllData();
    } else {
      _lastError = result['message'] ?? '取消失败';
    }
    notifyListeners();
    return result;
  }

  /// 获取订单详情
  Future<Map<String, dynamic>?> getOrderDetail(String orderId) async {
    return await api.getOrderDetail(orderId);
  }
}
