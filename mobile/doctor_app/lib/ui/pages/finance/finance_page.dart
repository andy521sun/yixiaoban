import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/core/providers/doctor_state.dart';

/// 医生端财务页面 — 收入统计 + 提现
class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  Map<String, dynamic>? _stats;
  List<dynamic> _earnings = [];
  List<dynamic> _withdrawals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final state = context.read<DoctorAppState>();
    if (!state.loggedIn) return;

    final statsRes = await state.api.getFinanceStats();
    final earningsRes = await state.api.getEarnings();
    final withdrawRes = await state.api.getWithdrawals();

    if (!mounted) return;
    setState(() {
      if (statsRes['success'] == true) _stats = statsRes['data'] as Map<String, dynamic>?;
      if (earningsRes['success'] == true) _earnings = earningsRes['data'] ?? [];
      if (withdrawRes['success'] == true) _withdrawals = withdrawRes['data'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收入统计')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 统计卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            '¥${(_stats?['total_earnings'] as num? ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8)),
                          ),
                          Text('累计收入', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('本月', '¥${(_stats?['monthly_earnings'] as num? ?? 0).toStringAsFixed(1)}'),
                              _buildStatItem('今日', '¥${(_stats?['today_earnings'] as num? ?? 0).toStringAsFixed(1)}'),
                              _buildStatItem('订单', '${_stats?['total_consultations'] as num? ?? 0}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 提现按钮
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showWithdrawDialog(),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('申请提现'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('最近提现记录', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (_withdrawals.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text('暂无提现记录', style: TextStyle(color: Colors.grey[400])),
                        ),
                      ),
                    )
                  else
                    ..._withdrawals.map((w) => Card(
                      child: ListTile(
                        title: Text('¥${(w['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text((w['created_at'] as String? ?? '').substring(0, 10)),
                        trailing: _statusBadge(w['status'] as String? ?? ''),
                      ),
                    )),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'approved': color = const Color(0xFF34A853); label = '已到账'; break;
      case 'rejected': color = Colors.red; label = '已驳回'; break;
      default: color = Colors.orange; label = '审核中';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }

  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('申请提现'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('可提现余额', style: TextStyle(color: Colors.grey, fontSize: 13)),
            Text('¥${(_stats?['total_earnings'] as num? ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '提现金额', prefixText: '¥ '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;

              final state = context.read<DoctorAppState>();
              final res = await state.api.submitWithdraw({
                'amount': amount,
                'account_type': 'wechat',
                'account_name': state.doctorName,
              });

              if (res['success'] == true) {
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('提交申请'),
          ),
        ],
      ),
    );
  }
}
