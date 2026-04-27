import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/companion_state.dart';
import '../../../core/config/app_config.dart';
import '../home/available_orders_page_v2.dart';
import '../tasks/my_tasks_page_v2.dart';
import '../chat/chat_list_page.dart';
import '../profile/profile_page.dart';

/// 陪诊师主页 v2（底部导航 + 页面切换）
/// 增强：操作反馈提示、连接状态实时更新
class CompanionHomePage extends StatefulWidget {
  const CompanionHomePage({super.key});

  @override
  State<CompanionHomePage> createState() => _CompanionHomePageState();
}

class _CompanionHomePageState extends State<CompanionHomePage> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final state = context.read<CompanionState>();
    state.refreshAll();
    state.connectWebSocket();
  }

  /// 显示操作反馈（成功/错误消息后自动清除）
  void _checkFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<CompanionState>();
      
      if (state.lastSuccessMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(state.lastSuccessMessage!)),
              ],
            ),
            backgroundColor: AppConfig.primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        state.clearMessages();
      }
      
      if (state.lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(state.lastError!)),
              ],
            ),
            backgroundColor: AppConfig.errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        state.clearMessages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CompanionState>();
    final titles = ['待接订单', '我的任务', '消息', '个人中心'];

    // 检查是否有操作反馈
    _checkFeedback();

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          // 连接状态
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (state.connectionStatus == '已连接'
                      ? AppConfig.primaryColor
                      : Colors.red)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: state.connectionStatus == '已连接'
                        ? AppConfig.primaryColor
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  state.connectionStatus == '已连接' ? '在线' : '离线',
                  style: TextStyle(
                    color: state.connectionStatus == '已连接'
                        ? AppConfig.primaryColor
                        : Colors.red,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // 头像
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppConfig.primaryColor,
              child: Text(
                state.userName.isNotEmpty ? state.userName[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          AvailableOrdersPage(),
          MyTasksPage(),
          ChatListPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: state.availableOrderCount > 0
                ? Badge(
                    label: Text('${state.availableOrderCount}'),
                    child: const Icon(Icons.assignment_outlined),
                  )
                : const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: '待接',
          ),
          const NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: '任务',
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: '消息',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
