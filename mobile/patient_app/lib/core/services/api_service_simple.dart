import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hospital.dart';
import '../models/companion.dart';

class ApiServiceSimple {
  static const String _baseUrl = 'http://localhost:3000/api';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // 获取医院列表 - 使用不需要认证的端点
  Future<List<Hospital>> getHospitals() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/hospitals'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> hospitalsData = data['data'];
          return hospitalsData.map((json) => Hospital.fromJson(json)).toList();
        }
      }
      throw Exception('获取医院列表失败: ${response.statusCode}');
    } catch (e) {
      print('API错误 - 获取医院列表: $e');
      // 返回模拟数据
      return _getMockHospitals();
    }
  }
  
  // 获取陪诊师列表 - 使用不需要认证的端点
  Future<List<Companion>> getCompanions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/companions'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> companionsData = data['data'];
          return companionsData.map((json) => Companion.fromJson(json)).toList();
        }
      }
      throw Exception('获取陪诊师列表失败: ${response.statusCode}');
    } catch (e) {
      print('API错误 - 获取陪诊师列表: $e');
      // 返回模拟数据
      return _getMockCompanions();
    }
  }
  
  // 创建订单 - 模拟实现
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      // 模拟API调用延迟
      await Future.delayed(const Duration(seconds: 1));
      
      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
      final price = _calculateMockPrice(
        orderData['service_type'] ?? '普通陪诊',
        orderData['duration_minutes'] ?? 120,
        '高级', // 模拟陪诊师等级
      );
      
      return {
        'success': true,
        'order_id': orderId,
        'payment_info': {
          'order_id': orderId,
          'amount': price,
          'currency': 'CNY',
          'payment_url': 'https://payment.example.com/pay/$orderId',
        },
      };
    } catch (e) {
      print('API错误 - 创建订单: $e');
      // 返回模拟响应
      return {
        'success': true,
        'order_id': 'ORD${DateTime.now().millisecondsSinceEpoch}',
        'payment_info': {
          'order_id': 'ORD${DateTime.now().millisecondsSinceEpoch}',
          'amount': 229.0,
          'currency': 'CNY',
          'payment_url': 'https://payment.example.com/pay/ORD123456',
        },
      };
    }
  }
  
  // 支付订单 - 模拟实现
  Future<Map<String, dynamic>> payOrder(String orderId, Map<String, dynamic> paymentData) async {
    try {
      // 模拟API调用延迟
      await Future.delayed(const Duration(seconds: 2));
      
      return {
        'success': true,
        'payment_status': 'paid',
        'order_status': 'confirmed',
      };
    } catch (e) {
      print('API错误 - 支付订单: $e');
      // 返回模拟响应
      return {
        'success': true,
        'payment_status': 'paid',
        'order_status': 'confirmed',
      };
    }
  }
  
  // 模拟医院数据
  List<Hospital> _getMockHospitals() {
    return [
      Hospital(
        id: 'hosp_001',
        name: '上海市第一人民医院',
        level: '三甲',
        address: '上海市虹口区武进路85号',
        rating: 4.8,
        distance: 2.5,
        departments: ['内科', '外科', '儿科', '妇产科'],
        phone: '021-63240090',
        imageUrl: 'https://example.com/hospital1.jpg',
      ),
      Hospital(
        id: 'hosp_002',
        name: '复旦大学附属华山医院',
        level: '三甲',
        address: '上海市静安区乌鲁木齐中路12号',
        rating: 4.9,
        distance: 3.2,
        departments: ['神经内科', '皮肤科', '感染科', '骨科'],
        phone: '021-52889999',
        imageUrl: 'https://example.com/hospital2.jpg',
      ),
      Hospital(
        id: 'hosp_003',
        name: '上海交通大学医学院附属瑞金医院',
        level: '三甲',
        address: '上海市黄浦区瑞金二路197号',
        rating: 4.7,
        distance: 4.1,
        departments: ['内分泌科', '血液科', '消化科', '心血管科'],
        phone: '021-64370045',
        imageUrl: 'https://example.com/hospital3.jpg',
      ),
    ];
  }
  
  // 模拟陪诊师数据
  List<Companion> _getMockCompanions() {
    return [
      Companion(
        id: 'comp_001',
        name: '张医生',
        experienceYears: 5,
        specialty: '全科陪诊',
        level: '高级',
        rating: 4.8,
        pricePerHour: 150,
        available: true,
        avatarUrl: 'https://example.com/avatar1.jpg',
        tags: ['耐心细致', '经验丰富', '沟通能力强'],
      ),
      Companion(
        id: 'comp_002',
        name: '李护士',
        experienceYears: 3,
        specialty: '儿科陪诊',
        level: '中级',
        rating: 4.5,
        pricePerHour: 120,
        available: true,
        avatarUrl: 'https://example.com/avatar2.jpg',
        tags: ['温柔亲切', '儿科专业', '有爱心'],
      ),
      Companion(
        id: 'comp_003',
        name: '王医生',
        experienceYears: 8,
        specialty: '老年科陪诊',
        level: '专家',
        rating: 4.9,
        pricePerHour: 200,
        available: false,
        avatarUrl: 'https://example.com/avatar3.jpg',
        tags: ['资深专家', '老年病专业', '责任心强'],
      ),
    ];
  }
  
  // 模拟价格计算
  double _calculateMockPrice(String serviceType, int durationMinutes, String companionLevel) {
    double basePrice = 199.0;
    const double serviceFee = 30.0;
    
    // 根据服务类型调整价格
    switch (serviceType) {
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
    final hours = durationMinutes / 60;
    basePrice *= hours;
    
    // 陪诊师等级加成
    switch (companionLevel) {
      case '高级':
        basePrice *= 1.3;
        break;
      case '专家':
        basePrice *= 1.5;
        break;
    }
    
    return basePrice + serviceFee;
  }
  
  // 健康检查
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/health'),
        headers: _headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('健康检查失败: $e');
      return false;
    }
  }
}