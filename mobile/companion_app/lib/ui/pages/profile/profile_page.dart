import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/companion_state.dart';
import 'earnings_page.dart';
import 'reviews_page.dart';
import '../schedule/schedule_page.dart';
import '../settings/settings_page.dart';

/// 个人中心页面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CompanionState>();
    final profile = state.profile ?? {};
    final stats = state.stats ?? {};

    final name = profile['real_name'] ?? profile['name'] ?? state.userName;
    final exp = profile['experience_years'] ?? '-';
    final rating = profile['average_rating'] ?? profile['rating'] ?? '-';
    final rate = profile['hourly_rate'] ?? 0;
    final spec = profile['specialty'] ?? '';
    final total = stats['total_orders'] ?? '0';
    final today = stats['today_orders'] ?? '0';
    final active = stats['in_progress'] ?? '0';
    final earnings = stats['today_earnings'] ?? '0';

    return RefreshIndicator(
      onRefresh: state.refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 个人信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppConfig.primaryColor,
                    child: Text(
                      name.toString()[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exp}年经验 · ¥$rate/时 · $rating评分',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        if (spec.toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '擅长: $spec',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 数据统计
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem(total.toString(), '累计订单'),
                  _statItem(today.toString(), '今日任务'),
                  _statItem(active.toString(), '服务中'),
                  _statItem('¥$earnings', '今日营收'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 连接状态
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: state.connectionStatus == '已连接'
                          ? AppConfig.primaryColor
                          : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '通知服务: ${state.connectionStatus}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Spacer(),
                  if (state.notificationCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.notificationCount} 条新通知',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 功能菜单
          Card(
            child: Column(
              children: [
                _menuItem(Icons.calendar_today, '我的日程', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulePage()))),
                const Divider(height: 1, indent: 56),
                _menuItem(Icons.star_outline, '服务评价', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsPage()))),
                const Divider(height: 1, indent: 56),
                _menuItem(Icons.monetization_on_outlined, '收入明细', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsPage()))),
                const Divider(height: 1, indent: 56),
                _menuItem(Icons.settings_outlined, '设置', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 退出登录
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('退出登录'),
                    content: const Text('确定要退出登录吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          state.logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text('确定',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDB4437),
                side: const BorderSide(color: Color(0xFFDB4437)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('退出登录'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConfig.primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
