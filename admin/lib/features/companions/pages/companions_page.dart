import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';

class CompanionsPage extends StatefulWidget {
  const CompanionsPage({super.key});

  @override
  State<CompanionsPage> createState() => _CompanionsPageState();
}

class _CompanionsPageState extends State<CompanionsPage> {
  List<dynamic> _companions = [];
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().api.getCompanions();
    if (!mounted) return;
    setState(() {
      _companions = result['data'] ?? [];
      _loading = false;
    });
  }

  List<dynamic> get _filtered {
    if (_tab == 0) return _companions;
    return _companions.where((c) {
      final m = c as Map<String, dynamic>;
      final cert = m['is_certified'] ?? false;
      return _tab == 1 ? cert == true : cert == false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tab
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _tabBtn('全部', 0),
                _tabBtn('已认证', 1),
                _tabBtn('待审核', 2),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const SizedBox(height: 300, child: Center(child: Text('暂无陪诊师', style: TextStyle(color: Colors.grey))))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _buildCard(_filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String text, int index) {
    final isSelected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: isSelected ? const Color(0xFF34A853) : Colors.transparent,
              width: 2,
            )),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFF34A853) : const Color(0xFF5F6368),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(dynamic companion) {
    final c = companion as Map<String, dynamic>;
    final name = c['real_name'] ?? c['name'] ?? '未知';
    final exp = c['experience_years'] ?? '-';
    final rating = c['average_rating'] ?? '-';
    final rate = c['hourly_rate'] ?? 0;
    final cert = c['is_certified'] == true;
    final phone = c['phone'] ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: (cert ? const Color(0xFF34A853) : Colors.orange).withValues(alpha: 0.1),
              child: Text(name.toString()[0], style: TextStyle(color: cert ? const Color(0xFF34A853) : Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (cert ? const Color(0xFF34A853) : Colors.orange).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cert ? '已认证' : '待审核',
                          style: TextStyle(fontSize: 10, color: cert ? const Color(0xFF34A853) : Colors.orange, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$phone · ${exp}年经验 · ¥$rate/时 · $rating评分', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            if (!cert)
              TextButton(
                onPressed: () async {
                  final ok = await context.read<AuthProvider>().api.updateUser(
                    c['user_id'] ?? c['id'] ?? '',
                    {'is_certified': true},
                  );
                  if (ok) _load();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '已认证该陪诊师' : '操作失败')));
                },
                child: const Text('认证', style: TextStyle(color: Color(0xFF34A853))),
              ),
          ],
        ),
      ),
    );
  }
}
