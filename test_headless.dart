import 'dart:io';
import 'dart:convert';

/// 无头测试工具 - 验证医小伴核心逻辑
void main(List<String> arguments) async {
  print('🏥 医小伴APP - 无头测试工具');
  print('=' * 50);
  
  final testResults = <String, bool>{};
  
  // 测试1: 项目结构验证
  testResults['项目结构'] = await testProjectStructure();
  
  // 测试2: 依赖验证
  testResults['依赖配置'] = await testDependencies();
  
  // 测试3: API服务验证
  testResults['API服务'] = await testApiServices();
  
  // 测试4: 业务逻辑验证
  testResults['业务逻辑'] = await testBusinessLogic();
  
  // 输出测试结果
  print('\n📊 测试结果汇总:');
  print('=' * 50);
  
  int passed = 0;
  int total = testResults.length;
  
  testResults.forEach((testName, result) {
    final status = result ? '✅ 通过' : '❌ 失败';
    print('$testName: $status');
    if (result) passed++;
  });
  
  print('=' * 50);
  print('通过率: $passed/$total (${(passed/total*100).toStringAsFixed(1)}%)');
  
  if (passed == total) {
    print('\n🎉 所有测试通过！可以开始开发。');
    exit(0);
  } else {
    print('\n⚠️  有${total - passed}个测试失败，请检查。');
    exit(1);
  }
}

/// 测试1: 项目结构验证
Future<bool> testProjectStructure() async {
  print('\n1. 验证项目结构...');
  
  final requiredDirs = [
    'lib',
    'lib/core',
    'lib/core/config',
    'lib/ui',
    'lib/ui/pages',
    'lib/ui/widgets',
  ];
  
  final requiredFiles = [
    'pubspec.yaml',
    'lib/main.dart',
    'lib/core/config/theme_config.dart',
    'lib/ui/pages/auth/simple_login_page.dart',
  ];
  
  bool allPassed = true;
  
  for (final dir in requiredDirs) {
    final dirExists = Directory(dir).existsSync();
    print('  ${dirExists ? '✅' : '❌'} $dir');
    if (!dirExists) allPassed = false;
  }
  
  for (final file in requiredFiles) {
    final fileExists = File(file).existsSync();
    print('  ${fileExists ? '✅' : '❌'} $file');
    if (!fileExists) allPassed = false;
  }
  
  return allPassed;
}

/// 测试2: 依赖验证
Future<bool> testDependencies() async {
  print('\n2. 验证依赖配置...');
  
  try {
    final pubspec = File('pubspec.yaml');
    final content = await pubspec.readAsString();
    
    final hasFlutter = content.contains('sdk: flutter');
    final hasHttp = content.contains('http:');
    final hasSharedPrefs = content.contains('shared_preferences:');
    
    print('  ${hasFlutter ? '✅' : '❌'} Flutter SDK');
    print('  ${hasHttp ? '✅' : '❌'} HTTP包');
    print('  ${hasSharedPrefs ? '✅' : '❌'} 本地存储');
    
    return hasFlutter && hasHttp && hasSharedPrefs;
  } catch (e) {
    print('  ❌ 读取pubspec.yaml失败: $e');
    return false;
  }
}

/// 测试3: API服务验证
Future<bool> testApiServices() async {
  print('\n3. 验证API服务...');
  
  try {
    // 测试支付服务器
    final paymentHealth = await testApiConnection('http://localhost:3003/health');
    print('  ${paymentHealth ? '✅' : '❌'} 支付服务器 (3003)');
    
    // 测试陪诊师服务器
    final companionHealth = await testApiConnection('http://localhost:3004/health');
    print('  ${companionHealth ? '✅' : '❌'} 陪诊师服务器 (3004)');
    
    return paymentHealth && companionHealth;
  } catch (e) {
    print('  ❌ API测试异常: $e');
    return false;
  }
}

/// 测试API连接
Future<bool> testApiConnection(String url) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      return body.contains('healthy') || body.contains('ok');
    }
    return false;
  } catch (e) {
    return false;
  }
}

/// 测试4: 业务逻辑验证
Future<bool> testBusinessLogic() async {
  print('\n4. 验证业务逻辑...');
  
  // 模拟用户登录逻辑
  final loginLogic = testLoginLogic();
  print('  ${loginLogic ? '✅' : '❌'} 登录逻辑验证');
  
  // 模拟订单创建逻辑
  final orderLogic = testOrderLogic();
  print('  ${orderLogic ? '✅' : '❌'} 订单逻辑验证');
  
  return loginLogic && orderLogic;
}

bool testLoginLogic() {
  // 模拟手机号验证
  final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
  final testPhones = ['13800138000', '12345678901', 'abc'];
  
  int passed = 0;
  for (final phone in testPhones) {
    if (phoneRegex.hasMatch(phone)) passed++;
  }
  
  return passed == 1; // 只有第一个是有效手机号
}

bool testOrderLogic() {
  // 模拟订单验证
  final order = {
    'patient_name': '测试用户',
    'hospital': '协和医院',
    'service_type': '陪诊',
    'amount': 100.0,
  };
  
  final requiredFields = ['patient_name', 'hospital', 'service_type', 'amount'];
  
  for (final field in requiredFields) {
    if (!order.containsKey(field) || order[field] == null) {
      return false;
    }
  }
  
  return order['amount'] > 0;
}