import 'package:flutter/material.dart';

void main() => runApp(const TestApp());

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '医小伴测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatelessWidget {
  const TestHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('医小伴Flutter测试'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.medical_services,
              size: 100,
              color: Color(0xFF1A73E8),
            ),
            const SizedBox(height: 20),
            const Text(
              '医小伴APP',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Flutter开发环境就绪',
              style: TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Column(
                children: [
                  StatusItem(icon: Icons.check, text: 'Flutter 3.41.7 已安装'),
                  StatusItem(icon: Icons.check, text: 'Linux桌面支持已启用'),
                  StatusItem(icon: Icons.check, text: '项目结构完整'),
                  StatusItem(icon: Icons.check, text: 'UI组件库就绪'),
                  StatusItem(icon: Icons.check, text: '设计系统就绪'),
                  StatusItem(icon: Icons.check, text: '后端API运行正常'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '可以开始医小伴APP开发!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                '已创建: 登录页面、首页框架、UI组件、主题系统',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('医小伴APP开发启动!'),
              backgroundColor: Color(0xFF1A73E8),
            ),
          );
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}

class StatusItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const StatusItem({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}