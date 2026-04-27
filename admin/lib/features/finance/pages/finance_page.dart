import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
// import '../../../core/config/theme_config.dart';

/// 财务管理页面
class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final _api = ApiService();

  Map<String, dynamic>? _orderStats;
  Map<String, dynamic>? _paymentStats;
  List<dynamic> _orders = [];
  List<dynamic> _companionEarnings = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 先获取所有订单
      final ordersResp = await _api.getOrders(limit: 50);
      // 获取dashboar统计（包含营收/支付数据）
      final dashResp = await _api.getDashboardStats();

      if (!mounted) return;

      List<dynamic> orders = [];
      if (ordersResp['success'] == true) {
        final data = ordersResp['data'];
        orders = data is Map ? (data['orders'] ?? []) : (data ?? []);
      }

      Map<String, dynamic> orderStats = <String, dynamic>{};
      Map<String, dynamic> paymentStats = <String, dynamic>{};
      List<dynamic> companionStats = <dynamic>[];
      if (dashResp?['success'] == true) {
        final resp = dashResp;
        final data = resp?['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final os = data['order_stats'];
        if (os != null) {
          orderStats = os as Map<String, dynamic>;
        }
        final ps = data['payment_stats'];
        if (ps != null) {
          paymentStats = ps as Map<String, dynamic>;
        }
        final ac = data['active_companions'];
        if (ac != null) {
          companionStats = ac as List<dynamic>;
        }
      }

      // 按陪诊师汇总收益
      final companionMap = <String, Map<String, dynamic>>{};
      for (final o in orders) {
        final cName = o['companion_name'] ?? '未分配';
        final amount = double.tryParse('${o['total_amount'] ?? 0}') ?? 0;
        if (o['status'] == 'completed') {
          companionMap.putIfAbsent(cName, () => {
            'name': cName,
            'total': 0.0,
            'count': 0,
            'orders': <Map<String, dynamic>>[],
          });
          companionMap[cName]!['total'] += amount;
          companionMap[cName]!['count'] += 1;
          (companionMap[cName]!['orders'] as List).add(o);
        }
      }

      // 合并活跃陪诊师的统计数据
      final allCompanions = <Map<String, dynamic>>[];
      final added = <String>{};
      for (final c in companionStats) {
        final name = c['name'] ?? '';
        if (companionMap.containsKey(name)) {
          final cm = companionMap[name]!;
          allCompanions.add({
            'name': name,
            'total': cm['total'],
            'count': cm['count'],
            'earnings': c['total_earnings'] ?? cm['total'],
            'avg_rating': c['avg_rating'],
          });
          added.add(name);
        } else {
          allCompanions.add({
            'name': name,
            'total': 0.0,
            'count': 0,
            'earnings': 0,
            'avg_rating': null,
          });
        }
      }
      // 添加有订单但不在活跃列表里的
      for (final e in companionMap.entries) {
        if (!added.contains(e.key)) {
          final cm = e.value;
          allCompanions.add({
            'name': e.key,
            'total': cm['total'],
            'count': cm['count'],
            'earnings': cm['total'],
            'avg_rating': null,
          });
        }
      }

      setState(() {
        _orderStats = orderStats;
        _paymentStats = paymentStats;
        _orders = orders;
        _companionEarnings = allCompanions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('财务管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _buildRevenueCards(),
                      const SizedBox(height: 16),
                      _buildPaymentSummary(),
                      const SizedBox(height: 16),
                      _buildCompanionEarnings(),
                      const SizedBox(height: 16),
                      _buildOrderFlow(),
                    ],
                  ),
                ),
    );
  }

  // ========== 营收概览卡片 ==========
  Widget _buildRevenueCards() {
    final totalRevenue = double.tryParse('${_orderStats?['total_revenue'] ?? 0}') ?? 0;
    final todayRevenue = double.tryParse('${_orderStats?['today_revenue'] ?? 0}') ?? 0;
    final completed = int.tryParse('${_orderStats?['completed_orders'] ?? 0}') ?? 0;
    final pending = int.tryParse('${_orderStats?['pending_orders'] ?? 0}') ?? 0;
    final totalOrders = _orderStats?['total_orders'] ?? 0;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.trending_up, color: Color(0xFF34A853), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('营收概览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    '总营收',
                    '¥${_formatMoney(totalRevenue)}',
                    Icons.account_balance_wallet,
                    const Color(0xFF34A853),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStat(
                    '今日营收',
                    '¥${_formatMoney(todayRevenue)}',
                    Icons.today,
                    const Color(0xFF1A73E8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    '已完成订单',
                    '$completed 单',
                    Icons.check_circle,
                    const Color(0xFF34A853),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStat(
                    '待处理',
                    '$pending 单',
                    Icons.pending_actions,
                    const Color(0xFFF4B400),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '客单价 ¥${_formatMoney(avgOrderValue)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    '共 $totalOrders 单',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ========== 支付状态汇总 ==========
  Widget _buildPaymentSummary() {
    final paid = int.tryParse('${_paymentStats?['paid_payments'] ?? 0}') ?? 0;
    final unpaid = int.tryParse('${_paymentStats?['unpaid_payments'] ?? 0}') ?? 0;
    final refunded = int.tryParse('${_paymentStats?['refunded_payments'] ?? 0}') ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payment, color: Color(0xFF1A73E8), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('支付状态', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentChip('已支付', paid, const Color(0xFF34A853), Icons.check_circle),
                ),
                Expanded(
                  child: _buildPaymentChip('未支付', unpaid, const Color(0xFFF4B400), Icons.pending),
                ),
                Expanded(
                  child: _buildPaymentChip('已退款', refunded, const Color(0xFFDB4437), Icons.replay),
                ),
              ],
            ),
            if (paid + unpaid + refunded > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Flexible(
                        flex: paid,
                        child: Container(color: const Color(0xFF34A853)),
                      ),
                      Flexible(
                        flex: unpaid,
                        child: Container(color: const Color(0xFFF4B400)),
                      ),
                      Flexible(
                        flex: refunded,
                        child: Container(color: const Color(0xFFDB4437)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // ========== 陪诊师收益排行 ==========
  Widget _buildCompanionEarnings() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_events, color: Color(0xFFFF6D00), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('陪诊师收益排行', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${_companionEarnings.length}人',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            if (_companionEarnings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey))),
              )
            else
              ...List.generate(_companionEarnings.length, (i) {
                final c = _companionEarnings[i];
                final name = c['name'] ?? '未知';
                final total = (c['total'] as num?)?.toDouble() ?? 0;
                final count = c['count'] ?? 0;
                final rating = c['avg_rating'];
                final medal = i == 0
                    ? const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 20)
                    : i == 1
                        ? const Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 20)
                        : i == 2
                            ? const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20)
                            : null;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (medal != null) medal else SizedBox(
                        width: 20,
                        child: Text('${i + 1}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text('$count 单完成', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (rating != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.star, size: 12, color: Color(0xFFF4B400)),
                                  Text('${double.tryParse('$rating')?.toStringAsFixed(1) ?? "-"}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text('¥${_formatMoney(total)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF34A853),
                          )),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ========== 订单流水 ==========
  Widget _buildOrderFlow() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xFF1A73E8), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('订单流水', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${_orders.length}笔', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            if (_orders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('暂无订单', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._orders.asMap().entries.map((entry) {
                final o = entry.value;
                final status = o['status'] ?? '';
                final amount = double.tryParse('${o['total_amount'] ?? 0}') ?? 0;
                final patientName = o['patient_name'] ?? '未知';
                final companionName = o['companion_name'] ?? '未分配';
                final date = (o['created_at'] ?? '').toString().substring(0, 10);
                final paymentStatus = o['payment_status'] ?? '';

                IconData statusIcon;
                Color statusColor;
                switch (status) {
                  case 'completed':
                    statusIcon = Icons.check_circle;
                    statusColor = const Color(0xFF34A853);
                    break;
                  case 'in_progress':
                    statusIcon = Icons.sync;
                    statusColor = const Color(0xFF1A73E8);
                    break;
                  case 'pending':
                    statusIcon = Icons.schedule;
                    statusColor = const Color(0xFFF4B400);
                    break;
                  case 'cancelled':
                    statusIcon = Icons.cancel;
                    statusColor = const Color(0xFFDB4437);
                    break;
                  default:
                    statusIcon = Icons.radio_button_unchecked;
                    statusColor = Colors.grey;
                }

                final statusLabel = {
                  'pending': '待确认',
                  'confirmed': '已确认',
                  'in_progress': '服务中',
                  'completed': '已完成',
                  'cancelled': '已取消',
                  'refunded': '已退款',
                }[status] ?? status;

                final paymentLabel = {
                  'paid': '已支付',
                  'unpaid': '未支付',
                  'refunded': '已退款',
                }[paymentStatus] ?? '';

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(patientName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(statusLabel,
                                      style: TextStyle(fontSize: 10, color: statusColor)),
                                ),
                                if (paymentLabel.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: paymentStatus == 'paid'
                                          ? const Color(0xFF34A853).withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(paymentLabel,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: paymentStatus == 'paid'
                                                ? const Color(0xFF34A853)
                                                : Colors.grey)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$date · $companionName',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text('¥${_formatMoney(amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: amount > 0 ? Colors.black87 : Colors.grey,
                          )),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatMoney(num value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(2)}万';
    }
    return value.toStringAsFixed(2);
  }
}
