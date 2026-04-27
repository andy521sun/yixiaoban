import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'companion_token';
  static const String _userKey = 'companion_user';
  static const String _settingsKey = 'companion_settings';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ========== Token ==========
  Future<void> saveToken(String token) async {
    final p = await prefs;
    await p.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final p = await prefs;
    return p.getString(_tokenKey);
  }

  Future<void> removeToken() async {
    final p = await prefs;
    await p.remove(_tokenKey);
  }

  // ========== 用户信息 ==========
  Future<void> saveUser(Map<String, dynamic> user) async {
    final p = await prefs;
    await p.setString(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final p = await prefs;
    final raw = p.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> removeUser() async {
    final p = await prefs;
    await p.remove(_userKey);
  }

  // ========== 设置 ==========
  Future<void> saveSetting(String key, dynamic value) async {
    final p = await prefs;
    final raw = p.getString(_settingsKey);
    final settings = raw != null ? jsonDecode(raw) as Map<String, dynamic> : <String, dynamic>{};
    settings[key] = value;
    await p.setString(_settingsKey, jsonEncode(settings));
  }

  Future<dynamic> getSetting(String key) async {
    final p = await prefs;
    final raw = p.getString(_settingsKey);
    if (raw == null) return null;
    final settings = jsonDecode(raw) as Map<String, dynamic>;
    return settings[key];
  }

  // ========== 清除 ==========
  Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }

  Future<void> clearSession() async {
    await removeToken();
    await removeUser();
  }
}
