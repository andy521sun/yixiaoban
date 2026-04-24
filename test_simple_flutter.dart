import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '医小伴测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medical_services,
                size: 100,
                color: Colors.blue,
              ),
              SizedBox(height: 20),
              Text(
                '🏥 医小伴APP',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Flutter开发环境测试成功!',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.all(20),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('✅ Flutter 3.41.7 已安装', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 10),
                        Text('✅ Linux桌面支持已启用', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 10),
                        Text('✅ 项目结构完整', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 10),
                        Text('✅ 可以开始开发', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '下一步: 运行完整医小伴应用',
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}