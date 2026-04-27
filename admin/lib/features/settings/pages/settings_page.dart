import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('管理员信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(auth.adminName),
                  subtitle: const Text('管理员'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('系统信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              ListTile(title: const Text('应用名称'), trailing: const Text('医小伴管理后台')),
              const Divider(height: 1, indent: 16),
              ListTile(title: const Text('版本'), trailing: const Text('v1.0.0')),
              const Divider(height: 1, indent: 16),
              ListTile(title: const Text('API服务器'), trailing: Text('https://andysun521.online', style: TextStyle(color: Colors.grey[500], fontSize: 13))),
              const Divider(height: 1, indent: 16),
              ListTile(title: const Text('数据库状态'), trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF34A853), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('已连接'),
                ],
              )),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              auth.logout();
              (context as Element).markNeedsBuild();
            },
            icon: const Icon(Icons.logout, color: Color(0xFFDB4437)),
            label: const Text('退出登录', style: TextStyle(color: Color(0xFFDB4437))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFDB4437)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
