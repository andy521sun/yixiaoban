import 'dart:async';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  final StorageService _storageService;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String? _userId;
  String? _userName;
  String? _userRole;

  AuthService() : _storageService = StorageService();

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userRole => _userRole;

  Future<void> init() async {
    try {
      await _storageService.init();
      await _checkLoginStatus();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('AuthService初始化失败: $e');
      }
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> checkLoginStatus() async {
    await _checkLoginStatus();
    return _isLoggedIn;
  }

  Future<void> _checkLoginStatus() async {
    try {
      final token = await _storageService.getToken();
      final userInfo = await _storageService.getUserInfo();
      
      _isLoggedIn = token != null && userInfo != null;
      
      if (userInfo != null) {
        _userId = userInfo['id'];
        _userName = userInfo['name'];
        _userRole = userInfo['role'];
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('检查登录状态失败: $e');
      }
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      // 模拟登录API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 模拟成功响应
      final response = {
        'success': true,
        'data': {
          'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 'companion_001',
            'name': '张医生',
            'phone': phone,
            'role': 'companion',
            'avatar': null,
            'certification_status': 'verified',
            'rating': 4.8,
            'completed_orders': 156,
          }
        }
      };
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;
        
        // 保存token和用户信息
        await _storageService.saveToken(token);
        await _storageService.saveUserInfo(user);
        
        // 更新状态
        _isLoggedIn = true;
        _userId = user['id'];
        _userName = user['name'];
        _userRole = user['role'];
        
        notifyListeners();
        
        return {
          'success': true,
          'message': '登录成功',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': '登录失败，请检查手机号和密码',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('登录失败: $e');
      }
      return {
        'success': false,
        'message': '网络错误，请稍后重试',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String name,
    required String idCard,
    required String certificationNumber,
  }) async {
    try {
      // 模拟注册API调用
      await Future.delayed(const Duration(seconds: 2));
      
      // 模拟成功响应
      final response = {
        'success': true,
        'data': {
          'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 'companion_${DateTime.now().millisecondsSinceEpoch}',
            'name': name,
            'phone': phone,
            'role': 'companion',
            'avatar': null,
            'certification_status': 'pending',
            'rating': 0.0,
            'completed_orders': 0,
          }
        }
      };
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;
        
        // 保存token和用户信息
        await _storageService.saveToken(token);
        await _storageService.saveUserInfo(user);
        
        // 更新状态
        _isLoggedIn = true;
        _userId = user['id'];
        _userName = user['name'];
        _userRole = user['role'];
        
        notifyListeners();
        
        return {
          'success': true,
          'message': '注册成功，请等待审核',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': '注册失败，请稍后重试',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('注册失败: $e');
      }
      return {
        'success': false,
        'message': '网络错误，请稍后重试',
      };
    }
  }

  Future<void> logout() async {
    try {
      await _storageService.clearAll();
      
      _isLoggedIn = false;
      _userId = null;
      _userName = null;
      _userRole = null;
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('退出登录失败: $e');
      }
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profile) async {
    try {
      // 模拟更新API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 获取当前用户信息
      final currentUser = await _storageService.getUserInfo();
      if (currentUser == null) {
        return {
          'success': false,
          'message': '用户未登录',
        };
      }
      
      // 合并更新
      final updatedUser = {...currentUser, ...profile};
      await _storageService.saveUserInfo(updatedUser);
      
      // 更新状态
      _userName = updatedUser['name'];
      
      notifyListeners();
      
      return {
        'success': true,
        'message': '资料更新成功',
        'user': updatedUser,
      };
    } catch (e) {
      if (kDebugMode) {
        print('更新资料失败: $e');
      }
      return {
        'success': false,
        'message': '更新失败，请稍后重试',
      };
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // 模拟修改密码API调用
      await Future.delayed(const Duration(seconds: 1));
      
      return {
        'success': true,
        'message': '密码修改成功',
      };
    } catch (e) {
      if (kDebugMode) {
        print('修改密码失败: $e');
      }
      return {
        'success': false,
        'message': '修改失败，请稍后重试',
      };
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(String phone) async {
    try {
      // 模拟重置密码API调用
      await Future.delayed(const Duration(seconds: 1));
      
      return {
        'success': true,
        'message': '验证码已发送到您的手机',
      };
    } catch (e) {
      if (kDebugMode) {
        print('请求重置密码失败: $e');
      }
      return {
        'success': false,
        'message': '请求失败，请稍后重试',
      };
    }
  }
}