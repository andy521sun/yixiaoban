import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

/// 医生端全局状态
class DoctorAppState extends ChangeNotifier {
  final DoctorApiService api = DoctorApiService();
  final WebSocketService ws = WebSocketService();

  bool _loggedIn = false;
  String _token = '';
  String _doctorName = '';
  String _doctorTitle = '';
  String _doctorDepartment = '';
  String _doctorHospital = '';
  String _certStatus = ''; // unsubmitted | pending | approved | rejected

  bool get loggedIn => _loggedIn;
  String get token => _token;
  String get doctorName => _doctorName;
  String get doctorTitle => _doctorTitle;
  String get doctorDepartment => _doctorDepartment;
  String get doctorHospital => _doctorHospital;
  String get certStatus => _certStatus;
  bool get isCertified => _certStatus == 'approved';

  void setLoggedIn(bool v) { _loggedIn = v; notifyListeners(); }
  void setToken(String t) {
    _token = t;
    api.setToken(t);
    ws.connect(t);
  }
  void setDoctorName(String n) { _doctorName = n; notifyListeners(); }
  void setDoctorInfo({String? name, String? title, String? department, String? hospital}) {
    if (name != null) _doctorName = name;
    if (title != null) _doctorTitle = title;
    if (department != null) _doctorDepartment = department;
    if (hospital != null) _doctorHospital = hospital;
    notifyListeners();
  }
  void setCertStatus(String s) { _certStatus = s; notifyListeners(); }

  void logout() {
    ws.disconnect();
    _loggedIn = false;
    _token = '';
    _doctorName = '';
    _doctorTitle = '';
    _doctorDepartment = '';
    _doctorHospital = '';
    _certStatus = '';
    api.setToken(null);
    notifyListeners();
  }

  @override
  void dispose() {
    ws.dispose();
    super.dispose();
  }
}
