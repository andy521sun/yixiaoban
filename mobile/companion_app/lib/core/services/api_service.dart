import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:3000/api';
  static const Duration _timeout = Duration(seconds: 30);

  final StorageService _storageService;

  ApiService(this._storageService);

  // 获取认证头
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // 通用请求方法
  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl$endpoint').replace(
        queryParameters: queryParams,
      );

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(_timeout);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(_timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          throw Exception('不支持的HTTP方法: $method');
      }

      return _handleResponse(response);
    } on SocketException {
      return {
        'success': false,
        'message': '网络连接失败，请检查网络设置',
        'error': 'network_error',
      };
    } on http.ClientException {
      return {
        'success': false,
        'message': '网络请求失败，请稍后重试',
        'error': 'client_error',
      };
    } catch (e) {
      if (kDebugMode) {
        print('API请求异常: $e');
      }
      return {
        'success': false,
        'message': '请求失败，请稍后重试',
        'error': 'unknown_error',
      };
    }
  }

  // 处理响应
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final responseBody = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': responseBody,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseBody['message'] ?? '请求失败',
          'error': responseBody['error'] ?? 'server_error',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('响应解析失败: $e, 响应体: ${response.body}');
      }
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': '服务器响应格式错误',
        'error': 'parse_error',
      };
    }
  }

  // 认证相关API
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    return await _request('POST', '/auth/login', body: {
      'phone': phone,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String name,
    required String idCard,
    required String certificationNumber,
  }) async {
    return await _request('POST', '/auth/register', body: {
      'phone': phone,
      'password': password,
      'name': name,
      'id_card': idCard,
      'certification_number': certificationNumber,
      'role': 'companion',
    });
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await _request('GET', '/auth/profile');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profile) async {
    return await _request('PUT', '/auth/profile', body: profile);
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await _request('POST', '/auth/change-password', body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  // 任务相关API
  Future<Map<String, dynamic>> getTasks({
    int page = 1,
    int limit = 20,
    String? status,
    String? date,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
      if (date != null) 'date': date,
    };

    return await _request('GET', '/companion/tasks', queryParams: queryParams);
  }

  Future<Map<String, dynamic>> getTaskDetail(String taskId) async {
    return await _request('GET', '/companion/tasks/$taskId');
  }

  Future<Map<String, dynamic>> acceptTask(String taskId) async {
    return await _request('POST', '/companion/tasks/$taskId/accept');
  }

  Future<Map<String, dynamic>> rejectTask(String taskId, String reason) async {
    return await _request('POST', '/companion/tasks/$taskId/reject', body: {
      'reason': reason,
    });
  }

  Future<Map<String, dynamic>> startTask(String taskId) async {
    return await _request('POST', '/companion/tasks/$taskId/start');
  }

  Future<Map<String, dynamic>> completeTask(String taskId) async {
    return await _request('POST', '/companion/tasks/$taskId/complete');
  }

  Future<Map<String, dynamic>> cancelTask(String taskId, String reason) async {
    return await _request('POST', '/companion/tasks/$taskId/cancel', body: {
      'reason': reason,
    });
  }

  Future<Map<String, dynamic>> updateTaskLocation(
    String taskId,
    double latitude,
    double longitude,
  ) async {
    return await _request('POST', '/companion/tasks/$taskId/location', body: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  // 收入相关API
  Future<Map<String, dynamic>> getIncomeSummary({
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    return await _request('GET', '/companion/income/summary', queryParams: queryParams);
  }

  Future<Map<String, dynamic>> getIncomeDetails({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    return await _request('GET', '/companion/income/details', queryParams: queryParams);
  }

  Future<Map<String, dynamic>> withdrawIncome(double amount) async {
    return await _request('POST', '/companion/income/withdraw', body: {
      'amount': amount,
    });
  }

  // 日程相关API
  Future<Map<String, dynamic>> getSchedule({
    required String date,
  }) async {
    return await _request('GET', '/companion/schedule', queryParams: {
      'date': date,
    });
  }

  Future<Map<String, dynamic>> updateSchedule(Map<String, dynamic> schedule) async {
    return await _request('PUT', '/companion/schedule', body: schedule);
  }

  Future<Map<String, dynamic>> setAvailability({
    required bool available,
    String? reason,
  }) async {
    return await _request('POST', '/companion/availability', body: {
      'available': available,
      'reason': reason,
    });
  }

  // 评价相关API
  Future<Map<String, dynamic>> getReviews({
    int page = 1,
    int limit = 20,
  }) async {
    return await _request('GET', '/companion/reviews', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  Future<Map<String, dynamic>> replyToReview(
    String reviewId,
    String reply,
  ) async {
    return await _request('POST', '/companion/reviews/$reviewId/reply', body: {
      'reply': reply,
    });
  }

  // 聊天相关API
  Future<Map<String, dynamic>> getChatRooms() async {
    return await _request('GET', '/chat/rooms');
  }

  Future<Map<String, dynamic>> getChatMessages(
    String roomId, {
    int page = 1,
    int limit = 50,
  }) async {
    return await _request('GET', '/chat/messages/$roomId', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String receiverId,
    required String content,
    String? orderId,
    String messageType = 'text',
  }) async {
    return await _request('POST', '/chat/messages', body: {
      'room_id': roomId,
      'receiver_id': receiverId,
      'content': content,
      'order_id': orderId,
      'message_type': messageType,
    });
  }

  Future<Map<String, dynamic>> markMessageAsRead(String messageId) async {
    return await _request('PUT', '/chat/messages/$messageId/read');
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    return await _request('GET', '/chat/unread/count');
  }

  // 通知相关API
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    return await _request('GET', '/companion/notifications', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    return await _request('PUT', '/companion/notifications/$notificationId/read');
  }

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    return await _request('POST', '/companion/notifications/read-all');
  }

  // 设置相关API
  Future<Map<String, dynamic>> getSettings() async {
    return await _request('GET', '/companion/settings');
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    return await _request('PUT', '/companion/settings', body: settings);
  }

  // 统计相关API
  Future<Map<String, dynamic>> getStatistics({
    String? period,
  }) async {
    final queryParams = {
      if (period != null) 'period': period,
    };

    return await _request('GET', '/companion/statistics', queryParams: queryParams);
  }

  // 文件上传
  Future<Map<String, dynamic>> uploadFile(
    String filePath,
    String fileType,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);

      // 添加认证头
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // 添加文件
      final file = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(file);

      // 添加其他参数
      request.fields['type'] = fileType;

      // 发送请求
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('文件上传失败: $e');
      }
      return {
        'success': false,
        'message': '文件上传失败',
        'error': 'upload_error',
      };
    }
  }

  // 健康检查
  Future<Map<String, dynamic>> healthCheck() async {
    return await _request('GET', '/health');
  }

  // 模拟数据生成（开发环境使用）
  Map<String, dynamic> _generateMockData(String endpoint) {
    switch (endpoint) {
      case '/companion/tasks':
        return {
          'success': true,
          'data': {
            'tasks': [
              {
                'id': 'task_001',
                'order_id': 'order_001',
                'patient_name': '李女士',
                'patient_age': 65,
                'hospital_name': '北京协和医院',
                'department': '心血管内科',
                'appointment_time': '2026-04-13 09:00:00',
                'duration_hours': 3,
                'fee': 150.0,
                'status': 'pending',
                'created_at': '2026-04-12 10:30:00',
              },
              {
                'id': 'task_002',
                'order_id': 'order_002',
                'patient_name': '王先生',
                'patient_age': 42,
                'hospital_name': '北京大学第一医院',
                'department': '骨科',
                'appointment_time': '2026-04-13 14:00:00',
                'duration_hours': 2,
                'fee': 120.0,
                'status': 'accepted',
                'created_at': '2026-04-12 11:15:00',
              },
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 15,
              'total_pages': 1,
            },
          },
        };

      case '/companion/income/summary':
        return {
          'success': true,
          'data': {
            'total_income': 12580.0,
            'monthly_income': 3250.0,
            'weekly_income': 850.0,
            'today_income': 150.0,
            'completed_orders': 156,
            'average_rating': 4.8,
          },
        };

      default:
        return {
          'success': true,
          'data': {'message': 'Mock data for $endpoint'},
        };
    }
  }
}