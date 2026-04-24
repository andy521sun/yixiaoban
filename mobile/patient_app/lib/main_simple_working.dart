import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '医小伴患者端',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = '初始化...';
  List<dynamic> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _status = '连接服务器...');
      final response = await http.get(Uri.parse('http://localhost:3002/api/hospitals'));
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body));
        setState(() {
          _hospitals = data['data'] ?? [];
          _status = '加载成功: ${_hospitals.length}家医院';
        });
      } else {
        setState(() => _status = 'API错误: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _status = '错误: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('医小伴患者端'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(_status, style: TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _hospitals.length,
              itemBuilder: (context, index) {
                final hospital = _hospitals[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(hospital['name'] ?? '未知医院'),
                    subtitle: Text(hospital['address'] ?? ''),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // 医院详情页
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
