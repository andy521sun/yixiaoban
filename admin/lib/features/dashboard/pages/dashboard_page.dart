import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await context.read<AuthProvider>().api.getDashboardStats();
    if (mounted) setState(() { _stats = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final userStats = _stats?['user_stats']  ?? {};
    final orderStats = _stats?['order_stats']  ?? {};
    final hospitalStats = _stats?['hospital_stats']  ?? {};
    final activeCompanions = (_stats?['active_companions'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 统计卡片行
          Text('今日概况', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 12),
          _buildNumberRow([
            _StatCard('用户总数', '${userStats['total_users'] ?? 0}', Icons.people, Colors.blue),
            _StatCard('今日新增', '${userStats['today_new_users'] ?? 0}', Icons.person_add, Colors.indigo),
            _StatCard('今日订单', '${orderStats['today_orders'] ?? 0}', Icons.receipt, Colors.orange),
            _StatCard('今日营收', '¥${orderStats['today_revenue'] ?? 0}', Icons.payments, Colors.green),
          ]),
          const SizedBox(height: 12),
          _buildNumberRow([
            _StatCard('总订单', '${orderStats['total_orders'] ?? 0}', Icons.receipt_long, Colors.teal),
            _StatCard('已完成', '${orderStats['completed_orders'] ?? 0}', Icons.check_circle, Colors.green),
            _StatCard('待处理', '${orderStats['pending_orders'] ?? 0}', Icons.pending, Colors.amber),
            _StatCard('医院数', '${hospitalStats['total_hospitals'] ?? 0}', Icons.local_hospital, Colors.red),
          ]),
          const SizedBox(height: 24),

          // 订单状态
          Text('订单状态', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 12),
          _buildStatusCards(orderStats),
          const SizedBox(height: 24),

          // 活跃陪诊师
          Row(
            children: [
              Text('活跃陪诊师 Top 10', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('查看全部')),
            ],
          ),
          const SizedBox(height: 8),
          if (activeCompanions.isEmpty)
            Card(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey[500]))),
            ))
          else
            ...activeCompanions.take(5).map((c) => _buildCompanionRow(c)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNumberRow(List<Widget> cards) {
    return LayoutBuilder(builder: (_, constraints) {
      final width = constraints.maxWidth;
      final crossAxisCount = width > 600 ? 4 : 2;
      return Wrap(
        spacing: 12, runSpacing: 12,
        children: cards.map((c) => SizedBox(
          width: (width - 12 * (crossAxisCount - 1)) / crossAxisCount,
          child: c,
        )).toList(),
      );
    });
  }

  Widget _buildStatusCards(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _statusRow('待确认', '${stats['pending_orders'] ?? 0}', const Color(0xFFF4B400)),
            const Divider(height: 16),
            _statusRow('已确认', '${stats['confirmed_orders'] ?? 0}', const Color(0xFF1A73E8)),
            const Divider(height: 16),
            _statusRow('已完成', '${stats['completed_orders'] ?? 0}', const Color(0xFF34A853)),
            const Divider(height: 16),
            _statusRow('已取消', '${stats['cancelled_orders'] ?? 0}', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, String count, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368))),
        const Spacer(),
        Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildCompanionRow(dynamic c) {
    final m = c as Map<String, dynamic>;
    final name = m['name'] ?? '未知';
    final completed = m['completed_orders'] ?? 0;
    final rating = m['avg_rating'] ?? '-';
    final earnings = m['total_earnings'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF34A853).withValues(alpha: 0.1),
          child: Text(name.toString()[0], style: const TextStyle(color: Color(0xFF34A853), fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('完成 $completed 单 · 评分 $rating'),
        trailing: Text('¥$earnings', style: const TextStyle(color: Color(0xFF34A853), fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
