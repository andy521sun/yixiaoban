import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/companion_state.dart';
import 'settlements_page.dart';

/// 收入明细/钱包页
class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CompanionState>();
    final stats = state.stats ?? {};
    final profile = state.profile ?? {};

    final todayEarnings = stats['today_earnings'] ?? 0;
    final totalOrders = stats['total_orders'] ?? 0;
    final completedOrders = stats['completed_orders'] ?? 0;
    final totalEarnings = stats['total_earnings'] ?? 0;
    final rate = profile['hourly_rate'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('收入明细')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 总收入卡片
          Card(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppConfig.primaryColor,
                    AppConfig.primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '累计收入',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥$totalEarnings',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statCol('今日', '¥$todayEarnings'),
                      _statCol('时薪', '¥$rate'),
                      _statCol('完成', '$completedOrders单'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 统计卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statNum('$totalOrders', '总订单'),
                  _statNum('$completedOrders', '已完成'),
                  _statNum('$totalEarnings', '总收入(元)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 提现说明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '提现说明',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _tipItem('订单完成后，收入自动计入账户余额'),
                  _tipItem('每月1日和15日可申请提现'),
                  _tipItem('提现金额最低100元，最高不超过账户余额'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettlementsPage())),
                      child: const Text('查看结算记录'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _statNum(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConfig.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppConfig.primaryColor)),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
        ],
      ),
    );
  }
}
