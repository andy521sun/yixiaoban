import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/app_config.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static late Box _box;
  
  // 初始化存储服务
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await Hive.initFlutter();
    _box = await Hive.openBox('app_storage');
  }
  
  // ========== SharedPreferences 方法 ==========
  
  // 保存字符串
  static Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }
  
  // 获取字符串
  static String? getString(String key) {
    return _prefs.getString(key);
  }
  
  // 保存整数
  static Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }
  
  // 获取整数
  static int? getInt(String key) {
    return _prefs.getInt(key);
  }
  
  // 保存布尔值
  static Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }
  
  // 获取布尔值
  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }
  
  // 保存双精度浮点数
  static Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }
  
  // 获取双精度浮点数
  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }
  
  // 保存字符串列表
  static Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }
  
  // 获取字符串列表
  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }
  
  // 删除键
  static Future<bool> remove(String key) {
    return _prefs.remove(key);
  }
  
  // 清除所有数据
  static Future<bool> clear() {
    return _prefs.clear();
  }
  
  // 检查键是否存在
  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  // ========== Hive 方法 ==========
  
  // 保存对象
  static Future<void> put(String key, dynamic value) {
    return _box.put(key, value);
  }
  
  // 获取对象
  static dynamic get(String key, {dynamic defaultValue}) {
    return _box.get(key, defaultValue: defaultValue);
  }
  
  // 删除对象
  static Future<void> delete(String key) {
    return _box.delete(key);
  }
  
  // 检查对象是否存在
  static bool has(String key) {
    return _box.containsKey(key);
  }
  
  // 获取所有键
  static List<String> getKeys() {
    return _box.keys.cast<String>().toList();
  }
  
  // 清除Hive数据
  static Future<void> clearHive() {
    return _box.clear();
  }
  
  // ========== 应用特定方法 ==========
  
  // 保存认证令牌
  static Future<void> saveToken(String token) async {
    await setString(AppConfig.storageTokenKey, token);
  }
  
  // 获取认证令牌
  static String? getToken() {
    return getString(AppConfig.storageTokenKey);
  }
  
  // 清除认证令牌
  static Future<void> clearToken() async {
    await remove(AppConfig.storageTokenKey);
  }
  
  // 保存用户信息
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await put(AppConfig.storageUserKey, user);
  }
  
  // 获取用户信息
  static Map<String, dynamic>? getUser() {
    final user = get(AppConfig.storageUserKey);
    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }
    return null;
  }
  
  // 清除用户信息
  static Future<void> clearUser() async {
    await delete(AppConfig.storageUserKey);
  }
  
  // 保存搜索历史
  static Future<void> saveSearchHistory(List<String> history) async {
    await setStringList(AppConfig.storageHistoryKey, history);
  }
  
  // 获取搜索历史
  static List<String> getSearchHistory() {
    return getStringList(AppConfig.storageHistoryKey) ?? [];
  }
  
  // 添加搜索项
  static Future<void> addSearchItem(String item) async {
    List<String> history = getSearchHistory();
    
    // 移除重复项
    history.remove(item);
    
    // 添加到开头
    history.insert(0, item);
    
    // 限制历史记录数量
    if (history.length > 20) {
      history = history.sublist(0, 20);
    }
    
    await saveSearchHistory(history);
  }
  
  // 清除搜索历史
  static Future<void> clearSearchHistory() async {
    await remove(AppConfig.storageHistoryKey);
  }
  
  // 保存应用设置
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await put(AppConfig.storageSettingsKey, settings);
  }
  
  // 获取应用设置
  static Map<String, dynamic> getSettings() {
    final settings = get(AppConfig.storageSettingsKey);
    if (settings is Map) {
      return Map<String, dynamic>.from(settings);
    }
    return {
      'theme': 'light',
      'language': 'zh',
      'notification': true,
      'sound': true,
      'vibration': true,
    };
  }
  
  // 更新应用设置
  static Future<void> updateSettings(Map<String, dynamic> updates) async {
    Map<String, dynamic> settings = getSettings();
    settings.addAll(updates);
    await saveSettings(settings);
  }
  
  // 检查是否已登录
  static bool isLoggedIn() {
    return getToken() != null && getUser() != null;
  }
  
  // 获取用户ID
  static String? getUserId() {
    final user = getUser();
    return user?['id'];
  }
  
  // 获取用户角色
  static String? getUserRole() {
    final user = getUser();
    return user?['role'];
  }
  
  // 获取用户姓名
  static String? getUserName() {
    final user = getUser();
    return user?['name'];
  }
  
  // 获取用户手机号
  static String? getUserPhone() {
    final user = getUser();
    return user?['phone'];
  }
  
  // 清除所有用户数据（登出）
  static Future<void> clearAllUserData() async {
    await clearToken();
    await clearUser();
    // 可以添加其他需要清除的数据
  }
  
  // 保存缓存数据
  static Future<void> saveCache(String key, dynamic data, {Duration? duration}) async {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'duration': duration?.inMilliseconds,
    };
    await put('cache_$key', cacheData);
  }
  
  // 获取缓存数据
  static dynamic getCache(String key) {
    final cacheData = get('cache_$key');
    if (cacheData is Map) {
      final data = cacheData['data'];
      final timestamp = cacheData['timestamp'] as int?;
      final duration = cacheData['duration'] as int?;
      
      if (timestamp != null && duration != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - timestamp > duration) {
          // 缓存已过期
          delete('cache_$key');
          return null;
        }
      }
      
      return data;
    }
    return null;
  }
  
  // 清除缓存数据
  static Future<void> clearCache(String key) async {
    await delete('cache_$key');
  }
  
  // 清除所有缓存
  static Future<void> clearAllCache() async {
    final keys = getKeys().where((key) => key.startsWith('cache_')).toList();
    for (final key in keys) {
      await delete(key);
    }
  }
}