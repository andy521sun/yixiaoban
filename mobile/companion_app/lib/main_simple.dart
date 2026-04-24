import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '医小伴陪诊师端',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: CompanionHomePage(),
    );
  }
}

class CompanionHomePage extends StatefulWidget {
  @override
  _CompanionHomePageState createState() => _CompanionHomePageState();
}

class _CompanionHomePageState extends State<CompanionHomePage> {
  String _status = '初始化...';
  List<dynamic> _tasks = [];
  bool _loggedIn = false;

  Future<void> _login() async {
    try {
      setState(() => _status = '登录中...');
      final response = await http.post(
        Uri.parse('http://localhost:3004/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': 'doctor1', 'password': '123'}),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _loggedIn = true;
          _status = '登录成功';
        });
        _loadTasks();
      } else {
        setState(() => _status = '登录失败: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _status = '登录错误: $e');
    }
  }

  Future<void> _loadTasks() async {
    if (!_loggedIn) return;
    
    try {
      setState(() => _status = '加载任务...');
      final response = await http.get(Uri.parse('http://localhost:3004/api/tasks'));
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body));
        setState(() {
          _tasks = data['tasks'] ?? [];
          _status = '任务数: ${_tasks.length}';
        });
      } else {
        setState(() => _status = '加载失败: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _status = '加载错误: $e');
    }
  }

  Future<void> _acceptTask(String taskId) async {
    try {
      setState(() => _status = '接单中...');
      final response = await http.post(
        Uri.parse('http://localhost:3004/api/tasks/$taskId/accept'),
      );
      
      if (response.statusCode == 200) {
        setState(() => _status = '接单成功');
        _loadTasks();
      } else {
        setState(() => _status = '接单失败');
      }
    } catch (e) {
      setState(() => _status = '接单错误: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('医小伴陪诊师'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(_status, style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                if (!_loggedIn)
                  ElevatedButton(
                    onPressed: _login,
                    child: Text('登录陪诊师'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(task['title'] ?? '未知任务'),
                    subtitle: Text('状态: ${task['status']}'),
                    trailing: task['status'] == 'pending'
                        ? ElevatedButton(
                            onPressed: () => _acceptTask(task['id']),
                            child: Text('接单'),
                          )
                        : Text('已接单'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
