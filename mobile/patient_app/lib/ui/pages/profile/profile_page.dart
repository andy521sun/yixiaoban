import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: !appState.loggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    child: Icon(Icons.person, size: 40, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  const Text('登录体验完整功能', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(200, 44)),
                    child: const Text('登录/注册'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 用户信息卡片
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF1A73E8),
                          child: Text(
                            appState.userName.isNotEmpty ? appState.userName[0] : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appState.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(appState.userPhone, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 订单统计
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statItem('0', '待服务'),
                        _statItem('0', '服务中'),
                        _statItem('0', '已完成'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 功能菜单
                Card(
                  child: Column(
                    children: [
                      _menuItem(Icons.receipt_long, '我的订单', '/order/list'),
                      const Divider(height: 1, indent: 56),
                      _menuItem(Icons.favorite_border, '常用陪诊师', null),
                      const Divider(height: 1, indent: 56),
                      _menuItem(Icons.location_on_outlined, '常用医院', null),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Column(
                    children: [
                      _menuItem(Icons.settings_outlined, '设置', null),
                      const Divider(height: 1, indent: 56),
                      _menuItem(Icons.info_outline, '关于医小伴', null),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<AppState>().setLoggedIn(false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDB4437),
                      side: const BorderSide(color: Color(0xFFDB4437)),
                    ),
                    child: const Text('退出登录'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, String? route) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
    );
  }
}
