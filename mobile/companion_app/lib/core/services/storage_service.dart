import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userInfoKey = 'user_info';
  static const String _settingsKey = 'app_settings';
  static const String _lastLoginKey = 'last_login';
  static const String _unreadCountKey = 'unread_count';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  // Token相关操作
  Future<String?> getToken() async {
    await _ensureInitialized();
    return _prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _ensureInitialized();
    await _prefs.setString(_tokenKey, token);
  }

  Future<void> removeToken() async {
    await _ensureInitialized();
    await _prefs.remove(_tokenKey);
  }

  // 用户信息相关操作
  Future<Map<String, dynamic>?> getUserInfo() async {
    await _ensureInitialized();
    final userInfoJson = _prefs.getString(_userInfoKey);
    if (userInfoJson == null) return null;
    
    try {
      return json.decode(userInfoJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    await _ensureInitialized();
    final userInfoJson = json.encode(userInfo);
    await _prefs.setString(_userInfoKey, userInfoJson);
  }

  Future<void> removeUserInfo() async {
    await _ensureInitialized();
    await _prefs.remove(_userInfoKey);
  }

  // 应用设置相关操作
  Future<Map<String, dynamic>> getSettings() async {
    await _ensureInitialized();
    final settingsJson = _prefs.getString(_settingsKey);
    if (settingsJson == null) {
      return _getDefaultSettings();
    }
    
    try {
      final settings = json.decode(settingsJson) as Map<String, dynamic>;
      return {..._getDefaultSettings(), ...settings};
    } catch (e) {
      return _getDefaultSettings();
    }
  }

  Map<String, dynamic> _getDefaultSettings() {
    return {
      'notifications_enabled': true,
      'sound_enabled': true,
      'vibration_enabled': true,
      'auto_accept_orders': false,
      'max_distance_km': 10,
      'working_hours_start': '08:00',
      'working_hours_end': '18:00',
      'theme_mode': 'light',
      'language': 'zh-CN',
    };
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _ensureInitialized();
    final settingsJson = json.encode(settings);
    await _prefs.setString(_settingsKey, settingsJson);
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await _ensureInitialized();
    final settings = await getSettings();
    settings[key] = value;
    await saveSettings(settings);
  }

  // 最后登录时间
  Future<DateTime?> getLastLogin() async {
    await _ensureInitialized();
    final timestamp = _prefs.getInt(_lastLoginKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> updateLastLogin() async {
    await _ensureInitialized();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt(_lastLoginKey, now);
  }

  // 未读消息计数
  Future<int> getUnreadCount() async {
    await _ensureInitialized();
    return _prefs.getInt(_unreadCountKey) ?? 0;
  }

  Future<void> setUnreadCount(int count) async {
    await _ensureInitialized();
    await _prefs.setInt(_unreadCountKey, count);
  }

  Future<void> incrementUnreadCount() async {
    await _ensureInitialized();
    final current = await getUnreadCount();
    await setUnreadCount(current + 1);
  }

  Future<void> resetUnreadCount() async {
    await _ensureInitialized();
    await setUnreadCount(0);
  }

  // 通用存储操作
  Future<void> saveString(String key, String value) async {
    await _ensureInitialized();
    await _prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs.getString(key);
  }

  Future<void> saveInt(String key, int value) async {
    await _ensureInitialized();
    await _prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    await _ensureInitialized();
    return _prefs.getInt(key);
  }

  Future<void> saveBool(String key, bool value) async {
    await _ensureInitialized();
    await _prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs.getBool(key);
  }

  Future<void> saveDouble(String key, double value) async {
    await _ensureInitialized();
    await _prefs.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    await _ensureInitialized();
    return _prefs.getDouble(key);
  }

  Future<void> saveStringList(String key, List<String> value) async {
    await _ensureInitialized();
    await _prefs.setStringList(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    await _ensureInitialized();
    return _prefs.getStringList(key);
  }

  Future<void> remove(String key) async {
    await _ensureInitialized();
    await _prefs.remove(key);
  }

  Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    return _prefs.containsKey(key);
  }

  Future<void> clearAll() async {
    await _ensureInitialized();
    await _prefs.clear();
  }

  // 辅助方法
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  // 特定业务数据存储
  Future<void> saveRecentSearches(List<String> searches) async {
    await saveStringList('recent_searches', searches);
  }

  Future<List<String>> getRecentSearches() async {
    return await getStringList('recent_searches') ?? [];
  }

  Future<void> saveFavoriteHospitals(List<String> hospitalIds) async {
    await saveStringList('favorite_hospitals', hospitalIds);
  }

  Future<List<String>> getFavoriteHospitals() async {
    return await getStringList('favorite_hospitals') ?? [];
  }

  Future<void> saveCompletedOrders(List<Map<String, dynamic>> orders) async {
    final ordersJson = json.encode(orders);
    await saveString('completed_orders', ordersJson);
  }

  Future<List<Map<String, dynamic>>> getCompletedOrders() async {
    final ordersJson = await getString('completed_orders');
    if (ordersJson == null) return [];
    
    try {
      final List<dynamic> ordersList = json.decode(ordersJson);
      return ordersList.map((order) => order as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }
}