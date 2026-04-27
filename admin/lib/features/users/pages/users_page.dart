import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> _users = [];
  bool _loading = true;
  String _roleFilter = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().api.getUsers(
      role: _roleFilter.isNotEmpty ? _roleFilter : null,
      search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
    );
    if (!mounted) return;
    setState(() {
      _users = result['data']?['users'] ?? result['data'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: '搜索用户...', prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true, fillColor: const Color(0xFFF5F7FA),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _roleFilter.isEmpty ? null : _roleFilter,
                  hint: const Text('全部角色'),
                  items: ['patient', 'companion', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) { setState(() => _roleFilter = v ?? ''); _load(); },
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _load, child: const Text('搜索')),
              ],
            ),
          ),
          // 表格
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(child: Text('暂无用户', style: TextStyle(color: Colors.grey[500])))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _users.length,
                        itemBuilder: (_, i) => _buildUserCard(_users[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final u = user as Map<String, dynamic>;
    final name = u['name'] ?? '未知';
    final phone = u['phone'] ?? '';
    final role = u['role'] ?? '';
    final createdAt = u['created_at'] ?? '';

    final Color roleColor;
    String roleText;
    switch (role) {
      case 'admin': roleColor = Colors.purple; roleText = '管理员'; break;
      case 'companion': roleColor = const Color(0xFF34A853); roleText = '陪诊师'; break;
      default: roleColor = Colors.blue; roleText = '患者'; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.1),
          child: Text(name.toString()[0], style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$phone · $createdAt', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(roleText, style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
