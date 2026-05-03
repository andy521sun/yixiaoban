import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/services/api_service.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _api = ApiService();
  List<dynamic> _hospitals = [];
  List<dynamic> _companions = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final appState = context.read<AppState>();
    if (!appState.loggedIn) return;
    final res = await appState.api.getNotifications(limit: 20, unreadOnly: true);
    if (!mounted) return;
    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final notifications = (data['notifications'] as List?) ?? [];
      setState(() => _unreadCount = notifications.length);
    }
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getHospitals(),
        _api.getCompanions(),
      ]);
      if (!mounted) return;
      setState(() {
        _hospitals = results[0];
        _companions = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '加载失败: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('医小伴', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          // 通知入口
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDB4437),
                        shape: BoxShape.circle,
                      ),
                      child: Text('$_unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: '通知',
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          // AI问诊入口
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF34A853)),
            tooltip: 'AI智能问诊',
            onPressed: () => Navigator.pushNamed(context, '/ai/consult'),
          ),
          if (!appState.loggedIn)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('登录'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1A73E8),
                child: Text(
                  appState.userName.isNotEmpty ? appState.userName[0] : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Banner
                      _buildBanner(),
                      const SizedBox(height: 24),

                      // 功能快捷入口
                      _buildSectionTitle('快捷服务'),
                      const SizedBox(height: 12),
                      _buildQuickServices(),
                      const SizedBox(height: 24),

                      // 在线问诊推广 Banner 2
                      _buildConsultationBanner(),
                      const SizedBox(height: 24),

                      // 推荐医院
                      _buildSectionTitle('推荐医院', action: '查看全部'),
                      const SizedBox(height: 12),
                      ...(_hospitals.take(3).map((h) => _buildHospitalCard(h))),
                      const SizedBox(height: 24),

                      // 推荐陪诊师
                      _buildSectionTitle('推荐陪诊师', action: '查看全部'),
                      const SizedBox(height: 12),
                      ...(_companions.take(3).map((c) => _buildCompanionCard(c))),
                      const SizedBox(height: 32),

                      // 底部信息
                      Center(
                        child: Text(
                          '医小伴 v2.0 · 在线问诊 · 专业陪诊',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.medical_services, size: 120, color: Colors.white.withValues(alpha: 0.15)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('专业陪诊服务', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('上海三甲医院 · 资深陪诊师', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/appointment'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('立即预约', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/consultation/type-select'),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF34A853), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.white.withValues(alpha: 0.15)),
            ),
            Positioned(
              right: 30,
              top: 10,
              child: Icon(Icons.medical_information, size: 40, color: Colors.white.withValues(alpha: 0.12)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('在线问诊', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('三甲医生在线 · 图文/电话/视频咨询', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('立即咨询', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        if (action != null)
          TextButton(
            onPressed: () {},
            child: Text(action, style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildQuickServices() {
    final services = [
      {'icon': Icons.local_hospital, 'label': '医院查询', 'route': ''},
      {'icon': Icons.person_search, 'label': '陪诊预约', 'route': ''},
      {'icon': Icons.receipt_long, 'label': '我的预约', 'route': '/order/list'},
      {'icon': Icons.chat, 'label': '在线咨询', 'route': '/consultation/type-select'},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: services.map((s) {
        return GestureDetector(
          onTap: () {
            if ((s['route'] as String?)?.isNotEmpty == true) {
              Navigator.pushNamed(context, s['route'] as String);
            }
          },
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(s['icon'] as IconData, color: const Color(0xFF1A73E8), size: 26),
              ),
              const SizedBox(height: 8),
              Text(s['label'] as String, style: const TextStyle(fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHospitalCard(dynamic h) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_hospital, color: Color(0xFF1A73E8)),
        ),
        title: Text(h['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${h['level'] ?? ''} · ${h['address'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, '/hospital/detail', arguments: Map<String, dynamic>.from(h)),
      ),
    );
  }

  Widget _buildCompanionCard(dynamic c) {
    final rating = c['rating'] ?? c['average_rating'] ?? 0;
    final name = c['name'] ?? c['real_name'] ?? '';
    final spec = c['specialty'] ?? '';
    final intro = c['introduction'] ?? '';
    final services = c['service_count'] ?? 0;
    final rate = c['hourly_rate'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF34A853).withValues(alpha: 0.15),
          child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Color(0xFF34A853), fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (intro.isNotEmpty)
              Text(intro, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                if (rating > 0) ...[
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  Text(' $rating', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                ],
                if (services > 0)
                  Text('$services单', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const Spacer(),
                if (rate > 0)
                  Text('¥$rate/时', style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, '/companion/detail', arguments: Map<String, dynamic>.from(c as Map)),
      ),
    );
  }
}
