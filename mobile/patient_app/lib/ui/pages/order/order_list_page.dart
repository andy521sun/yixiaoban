import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/services/api_service.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final ApiService _api = ApiService();
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final appState = context.read<AppState>();
    _api.setToken(appState.token);
    final orders = await _api.getOrders();
    if (!mounted) return;
    setState(() { _orders = orders; _loading = false; });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return const Color(0xFF34A853);
      case 'in_progress': return const Color(0xFF1A73E8);
      case 'completed': return Colors.grey;
      case 'cancelled': return const Color(0xFFDB4437);
      default: return const Color(0xFFF4B400);
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending': return '待确认';
      case 'confirmed': return '已确认';
      case 'in_progress': return '服务中';
      case 'completed': return '已完成';
      case 'cancelled': return '已取消';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的订单')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('请先登录查看订单', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('去登录'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('我的订单')),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('暂无订单', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final o = _orders[index];
                      final status = o['status'] ?? 'pending';
                      final hName = o['hospital_name'] ?? '未知医院';
                      final cName = o['companion_name'] ?? '待分配';
                      final price = o['price'] ?? o['total_amount'] ?? 0;
                      final time = o['appointment_time'] ?? o['appointment_date'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pushNamed(context, '/order/detail', arguments: Map<String, dynamic>.from(o as Map)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(hName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _statusText(status),
                                        style: TextStyle(color: _statusColor(status), fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (time.isNotEmpty)
                                  Text('预约: $time', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('陪诊师: $cName', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    Text('¥$price', style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600, fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
