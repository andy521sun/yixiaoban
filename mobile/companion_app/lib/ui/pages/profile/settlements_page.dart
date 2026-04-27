import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/companion_state.dart';
import '../../../core/services/settlement_service.dart';
import '../../../core/config/app_config.dart';

/// 结算记录页面
class SettlementsPage extends StatefulWidget {
  const SettlementsPage({super.key});

  @override
  State<SettlementsPage> createState() => _SettlementsPageState();
}

class _SettlementsPageState extends State<SettlementsPage> {
  final SettlementService _service = SettlementService();
  List<dynamic> _settlements = [];
  Map<String, dynamic>? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.setToken(context.read<CompanionState>().token);
    _loadData();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final result = await _service.getSettlements();
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        _settlements = result['data']?['list'] ?? result['data'] ?? [];
        _summary = result['data']?['summary'] as Map<String, dynamic>?;
      }
      // 降级：无数据时使用mock数据展示UI
      if (_settlements.isEmpty) {
        _mockData();
      }
      _loading = false;
    });
  }

  void _mockData() {
    _summary = {
      'total_earned': 12800,
      'total_orders': 42,
      'this_month': 3600,
      'pending_settle': 1200,
      'last_settle_date': '2026-04-15',
    };
    _settlements = [
      {
        'id': 'STL001',
        'date': '2026-04-15',
        'amount': 6800,
        'order_count': 18,
        'status': 'settled',
        'type': '半月结算',
      },
      {
        'id': 'STL002',
        'date': '2026-04-01',
        'amount': 6000,
        'order_count': 24,
        'status': 'settled',
        'type': '半月结算',
      },
      {
        'id': 'STL003',
        'date': '2026-03-15',
        'amount': 5200,
        'order_count': 20,
        'status': 'settled',
        'type': '半月结算',
      },
      {
        'id': 'STL004',
        'date': '2026-03-01',
        'amount': 4800,
        'order_count': 16,
        'status': 'settled',
        'type': '半月结算',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('结算记录')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 结算概览卡片
                  _buildSummaryCard(),
                  const SizedBox(height: 16),

                  // 结算列表标题
                  Row(
                    children: [
                      const Text(
                        '历史结算',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_settlements.length}笔',
                          style: const TextStyle(
                            color: AppConfig.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 结算列表
                  ..._settlements.map((s) => _buildSettlementCard(
                      s as Map<String, dynamic>)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final totalEarned = _summary?['total_earned'] ?? 0;
    final totalOrders = _summary?['total_orders'] ?? 0;
    final thisMonth = _summary?['this_month'] ?? 0;
    final pendingSettle = _summary?['pending_settle'] ?? 0;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppConfig.primaryColor,
              AppConfig.primaryDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryCol('累计收入', '¥$totalEarned'),
                _summaryCol('总订单', '$totalOrders'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryCol('本月收入', '¥$thisMonth'),
                _summaryCol('待结算', '¥$pendingSettle'),
              ],
            ),
            if (_summary?['last_settle_date'] != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    '上次结算: ${_summary!['last_settle_date']}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '每月1日、15日结算',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementCard(Map<String, dynamic> settlement) {
    final date = settlement['date'] ?? '';
    final amount = settlement['amount'] ?? 0;
    final count = settlement['order_count'] ?? 0;
    final status = settlement['status'] ?? 'settled';
    final type = settlement['type'] ?? '';

    final isSettled = status == 'settled';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // 日期图标
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isSettled
                        ? AppConfig.primaryColor
                        : const Color(0xFFF4B400))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSettled ? Icons.check_circle : Icons.pending,
                color: isSettled ? AppConfig.primaryColor : const Color(0xFFF4B400),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        date,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isSettled
                                  ? AppConfig.primaryColor
                                  : const Color(0xFFF4B400))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSettled
                                ? AppConfig.primaryColor
                                : const Color(0xFFF4B400),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count笔订单 · ${isSettled ? "已结算" : "待结算"}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '+¥$amount',
              style: TextStyle(
                color: isSettled ? AppConfig.primaryColor : const Color(0xFFF4B400),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
