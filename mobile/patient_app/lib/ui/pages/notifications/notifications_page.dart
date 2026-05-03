import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';

/// 通知中心 — 集中查看所有系统通知
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  int _unreadCount = 0;
  final int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _listenWs();
  }

  void _listenWs() {
    final appState = context.read<AppState>();
    appState.ws.messages.listen((msg) {
      final type = msg['type'] as String?;
      if (type == 'system_notification') {
        _loadNotifications();
      }
    });
  }

  Future<void> _loadNotifications() async {
    final appState = context.read<AppState>();
    setState(() => _loading = true);

    final res = await appState.api.getNotifications(limit: _pageSize);
    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final list = (data['notifications'] as List?) ?? [];
      setState(() {
        _notifications = list.cast<Map<String, dynamic>>();
        _unreadCount = _notifications.where((n) => n['is_read'] != true).length;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    final appState = context.read<AppState>();
    await appState.api.markNotificationRead();
    _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已全部标记为已读'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _markOneRead(Map<String, dynamic> notification) async {
    final id = notification['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final appState = context.read<AppState>();
    await appState.api.markNotificationRead(notificationId: id);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息通知'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('全部已读 ($_unreadCount)',
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A73E8)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) => _buildItem(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('暂无通知', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          const SizedBox(height: 8),
          Text('医生回复、问诊状态变化都会通知您',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> notification) {
    final unread = notification['is_read'] != true;
    final title = notification['title'] as String? ?? '';
    final content = notification['content'] as String? ?? '';
    final createdAt = notification['created_at'] as String? ?? '';
    final date = createdAt.length >= 16 ? createdAt.substring(0, 16).replaceFirst('T', ' ') : createdAt;
    final type = notification['notification_type'] as String? ?? '';

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'order_status':
      case 'consultation':
        icon = Icons.chat_bubble_outline;
        iconColor = const Color(0xFF1A73E8);
        break;
      case 'new_order':
        icon = Icons.new_releases_outlined;
        iconColor = const Color(0xFFE6A23C);
        break;
      case 'system':
      default:
        icon = Icons.info_outline;
        iconColor = Colors.grey;
    }

    return ListTile(
      leading: Stack(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          if (unread)
            Positioned(
              right: 0, top: 0,
              child: Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFDB4437),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(content,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: unread
          ? Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFDB4437),
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () {
        if (unread) _markOneRead(notification);
      },
      onLongPress: () {
        if (unread && notification['id']?.toString()?.isNotEmpty == true) {
          _markOneRead(notification);
        }
      },
    );
  }
}
