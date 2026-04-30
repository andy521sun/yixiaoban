import 'package:flutter/material.dart';

class AppConfig {
  // API 配置
  static const String baseUrl = '/api';
  static const String companionUrl = '$baseUrl/companion';
  static const String authUrl = '$baseUrl/auth';
  static const String wsUrl = 'wss://andysun521.online/ws';
  static const String uploadUrl = '$baseUrl/upload';

  // App 信息
  static const String appName = '医小伴';
  static const String appRole = '陪诊师端';
  static const String appVersion = '1.0.0';
  static const String appSlogan = '温暖就医 · 专业陪伴';

  // UI 配置
  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 10.0;

  // 主题色
  static const Color primaryColor = Color(0xFF34A853);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryDark = Color(0xFF2E7D32);
  static const Color accentColor = Color(0xFF1A73E8);
  static const Color errorColor = Color(0xFFDB4437);
  static const Color warningColor = Color(0xFFF4B400);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color cardBorderColor = Color(0xFFE8EAED);
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textHint = Color(0xFF9AA0A6);
}
