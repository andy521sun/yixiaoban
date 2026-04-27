import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _loggedIn = false;
  String _token = '';
  String _name = '管理员';

  bool get isLoggedIn => _loggedIn;
  String get token => _token;
  String get adminName => _name;
  ApiService get api => _api;

  Future<String?> login(String phone, String password) async {
    final result = await _api.login(phone, password);
    if (result['success'] == true) {
      final data = result['data'] ?? result;
      _token = data['token'] ?? '';
      _name = data['user']?['name'] ?? '管理员';
      _loggedIn = true;
      _api.setToken(_token);
      notifyListeners();
      return null;
    }
    return result['message'] ?? '登录失败';
  }

  void logout() {
    _loggedIn = false;
    _token = '';
    _name = '管理员';
    _api.setToken(null);
    notifyListeners();
  }
}
