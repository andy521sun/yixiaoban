import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String _statusFilter = '';
  final _statuses = ['', 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().api.getOrders(
      status: _statusFilter.isNotEmpty ? _statusFilter : null,
    );
    if (!mounted) return;
    setState(() {
      _orders = result['data']?['orders'] ?? result['data'] ?? [];
      _loading = false;
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending': return const Color(0xFFF4B400);
      case 'confirmed': return const Color(0xFF1A73E8);
      case 'in_progress': return const Color(0xFF34A853);
      case 'completed': return Colors.grey;
      case 'cancelled': return const Color(0xFFDB4437);
      default: return Colors.grey;
    }
  }

  String _statusText(String s) {
    switch (s) {
      case 'pending': return '待确认';
      case 'confirmed': return '已确认';
      case 'in_progress': return '服务中';
      case 'completed': return '已完成';
      case 'cancelled': return '已取消';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 状态筛选
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['全部', '待确认', '已确认', '服务中', '已完成', '已取消'].asMap().entries.map((e) {
                  final isAll = e.key == 0;
                  final status = isAll ? '' : _statuses[e.key];
                  final isSelected = _statusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(e.value, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                      selected: isSelected,
                      selectedColor: _statusColor(status.isNotEmpty ? status : 'pending'),
                      onSelected: (_) {
                        setState(() => _statusFilter = status);
                        _load();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // 列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _orders.isEmpty
                        ? SizedBox(height: 300, child: Center(child: Text('暂无订单', style: TextStyle(color: Colors.grey[500]))))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final o = order as Map<String, dynamic>;
    final status = o['status'] ?? '';
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(_statusText(status), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                Text('¥${o['total_amount'] ?? o['price'] ?? 0}', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('患者: ${o['patient_name'] ?? '未知'}', style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
                if (o['companion_name'] != null) ...[
                  const SizedBox(width: 16),
                  Text('陪诊师: ${o['companion_name']}', style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text('${o['hospital_name'] ?? ''} · ${o['appointment_date'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
