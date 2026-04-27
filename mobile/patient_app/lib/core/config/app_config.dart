import "package:flutter/material.dart";
class AppConfig {
  // 应用信息
  static const String appName = '医小伴陪诊';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // API配置
  static const String apiBaseUrl = 'http://122.51.179.136/api';
  static const String wsBaseUrl = 'ws://122.51.179.136/ws';
  
  // 超时配置
  static const int connectTimeout = 10000; // 10秒
  static const int receiveTimeout = 15000; // 15秒
  
  // 分页配置
  static const int defaultPageSize = 20;
  
  // 地图配置
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // 支付配置
  static const String wechatAppId = 'YOUR_WECHAT_APP_ID';
  static const String alipayAppId = 'YOUR_ALIPAY_APP_ID';
  
  // 调试配置
  static const bool debugMode = true;
  static const bool enableLogging = true;
  
  // 颜色配置
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);
  
  // 字体配置
  static const String fontFamily = 'PingFang';
  
  // 图片配置
  static const String defaultAvatar = 'assets/images/default_avatar.png';
  static const String defaultHospitalImage = 'assets/images/default_hospital.png';
  static const String logoImage = 'assets/images/logo.png';
  
  // 本地存储Key
  static const String storageTokenKey = 'auth_token';
  static const String storageUserKey = 'user_info';
  static const String storageSettingsKey = 'app_settings';
  static const String storageHistoryKey = 'search_history';
}

// API端点
class ApiEndpoints {
  // 认证
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  
  // 用户
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/update';
  
  // 医院
  static const String hospitals = '/hospitals';
  static const String hospitalDetail = '/hospitals/';
  
  // 科室
  static const String departments = '/departments';
  
  // 订单
  static const String orders = '/orders';
  static const String orderDetail = '/orders/';
  static const String createOrder = '/orders/create';
  static const String cancelOrder = '/orders/cancel';
  
  // 支付
  static const String paymentMethods = '/payment/methods';
  static const String createPayment = '/payment/create';
  static const String paymentStatus = '/payment/status/';
  static const String wallet = '/payment/wallet';
  static const String recharge = '/payment/recharge';
  static const String transactions = '/payment/transactions';
  
  // 聊天
  static const String chatHistory = '/realtime/chat/history';
  static const String conversations = '/realtime/chat/conversations';
  static const String sendMessage = '/realtime/chat/send';
  static const String markRead = '/realtime/chat/mark-read';
  
  // 通知
  static const String notifications = '/realtime/notifications';
  
  // 陪诊师
  static const String companions = '/companions';
  static const String companionDetail = '/companions/';
}

// WebSocket事件
class WsEvents {
  static const String connectionEstablished = 'connection_established';
  static const String chatMessage = 'chat_message';
  static const String messageSent = 'message_sent';
  static const String messageRead = 'message_read';
  static const String typing = 'typing';
  static const String callRequest = 'call_request';
  static const String callResponse = 'call_response';
  static const String callEstablished = 'call_established';
  static const String userStatus = 'user_status';
  static const String orderNotification = 'order_notification';
  static const String systemNotification = 'system_notification';
  static const String error = 'error';
  static const String pong = 'pong';
}