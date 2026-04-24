import 'package:flutter/material.dart';
import '../models/hospital.dart';
import '../models/companion.dart';

class AppointmentProvider extends ChangeNotifier {
  Hospital? _hospital;
  DateTime? _date;
  TimeOfDay? _time;
  Companion? _companion;
  String _serviceType = '普通陪诊';
  int _duration = 120; // 分钟
  
  // Getters
  Hospital? get hospital => _hospital;
  DateTime? get date => _date;
  TimeOfDay? get time => _time;
  Companion? get companion => _companion;
  String get serviceType => _serviceType;
  int get duration => _duration;
  
  // 检查是否所有必填项都已填写
  bool get isComplete {
    return _hospital != null && 
           _date != null && 
           _time != null && 
           _companion != null;
  }
  
  // 获取完整的预约时间
  DateTime? get appointmentDateTime {
    if (_date == null || _time == null) return null;
    
    return DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
  }
  
  // Setters
  void setHospital(Hospital hospital) {
    _hospital = hospital;
    notifyListeners();
  }
  
  void setDate(DateTime date) {
    _date = date;
    notifyListeners();
  }
  
  void setTime(TimeOfDay time) {
    _time = time;
    notifyListeners();
  }
  
  void setCompanion(Companion companion) {
    _companion = companion;
    notifyListeners();
  }
  
  void setServiceType(String serviceType) {
    _serviceType = serviceType;
    notifyListeners();
  }
  
  void setDuration(int duration) {
    _duration = duration;
    notifyListeners();
  }
  
  // 批量设置预约数据
  void setAppointmentData({
    required Hospital hospital,
    required DateTime date,
    required TimeOfDay time,
    required Companion companion,
    String serviceType = '普通陪诊',
    int duration = 120,
  }) {
    _hospital = hospital;
    _date = date;
    _time = time;
    _companion = companion;
    _serviceType = serviceType;
    _duration = duration;
    notifyListeners();
  }
  
  // 清空预约数据
  void clear() {
    _hospital = null;
    _date = null;
    _time = null;
    _companion = null;
    _serviceType = '普通陪诊';
    _duration = 120;
    notifyListeners();
  }
  
  // 计算预估价格
  double calculateEstimatedPrice() {
    if (!isComplete) return 0.0;
    
    double basePrice = 199.0;
    double serviceFee = 30.0;
    
    // 根据服务类型调整价格
    switch (_serviceType) {
      case '专业陪诊':
        basePrice *= 1.5;
        break;
      case '急诊陪诊':
        basePrice *= 2.0;
        break;
      case '长期陪护':
        basePrice *= 3.0;
        break;
    }
    
    // 根据时长调整价格
    final hours = _duration / 60;
    basePrice *= hours;
    
    // 陪诊师等级加成
    if (_companion!.level == '高级') {
      basePrice *= 1.3;
    } else if (_companion!.level == '专家') {
      basePrice *= 1.5;
    }
    
    return basePrice + serviceFee;
  }
  
  // 获取预约摘要
  String get summary {
    if (!isComplete) return '预约信息不完整';
    
    final dateTime = appointmentDateTime;
    final dateStr = dateTime != null 
        ? '${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}'
        : '时间未设置';
    
    return '${_hospital?.name} | $dateStr | ${_companion?.name}';
  }
  
  // 转换为Map（用于API调用）
  Map<String, dynamic> toMap() {
    final dateTime = appointmentDateTime;
    
    return {
      'hospital_id': _hospital?.id,
      'companion_id': _companion?.id,
      'appointment_time': dateTime?.toIso8601String(),
      'service_type': _serviceType,
      'duration_minutes': _duration,
      'estimated_price': calculateEstimatedPrice(),
    };
  }
  
  // 从Map加载数据
  void fromMap(Map<String, dynamic> data) {
    // 这里需要从API响应中加载数据
    // 实际开发中需要根据数据结构实现
  }
}