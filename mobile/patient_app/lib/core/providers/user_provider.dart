import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? _userId;
  String? _userName;
  String? _userPhone;
  String? _userAvatar;
  String? _token;
  
  // Getters
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userPhone => _userPhone;
  String? get userAvatar => _userAvatar;
  String? get token => _token;
  
  bool get isLoggedIn => _userId != null && _token != null;
  
  // 模拟登录
  void mockLogin() {
    _userId = 'user_001';
    _userName = '张三';
    _userPhone = '13800138000';
    _userAvatar = 'https://example.com/avatar.jpg';
    _token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    notifyListeners();
  }
  
  // 登出
  void logout() {
    _userId = null;
    _userName = null;
    _userPhone = null;
    _userAvatar = null;
    _token = null;
    notifyListeners();
  }
  
  // 更新用户信息
  void updateProfile({
    String? userName,
    String? userPhone,
    String? userAvatar,
  }) {
    if (userName != null) _userName = userName;
    if (userPhone != null) _userPhone = userPhone;
    if (userAvatar != null) _userAvatar = userAvatar;
    notifyListeners();
  }
  
  // 保存token
  void setToken(String token) {
    _token = token;
    notifyListeners();
  }
  
  // 获取认证头
  Map<String, String> getAuthHeaders() {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
  
  // 从本地存储加载用户信息
  Future<void> loadFromStorage() async {
    // 这里应该从SharedPreferences或其他本地存储加载
    // 暂时使用模拟数据
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 开发环境使用模拟登录
    mockLogin();
  }
  
  // 保存到本地存储
  Future<void> saveToStorage() async {
    // 这里应该保存到SharedPreferences或其他本地存储
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  // 清除本地存储
  Future<void> clearStorage() async {
    // 这里应该清除本地存储
    await Future.delayed(const Duration(milliseconds: 100));
  }
}