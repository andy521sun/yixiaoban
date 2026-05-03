import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctor_app/core/providers/doctor_state.dart';

/// 医生端通知中心
class DoctorNotificationsPage extends StatefulWidget {
  const DoctorNotificationsPage({super.key});

  @override
  State<DoctorNotificationsPage> createState() => _DoctorNotificationsPageState();
}

class _DoctorNotificationsPageState extends State<DoctorNotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _listenWs();
  }

  void _listenWs() {
    final state = context.read<DoctorAppState>();
    state.ws.messages.listen((msg) {
      if (msg['type'] == 'system_notification') _load();
    });
  }

  Future<void> _load() async {
    final state = context.read<DoctorAppState>();
    setState(() => _loading = true);
    final res = await state.api.getNotifications(limit: 30);
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
    final state = context.read<DoctorAppState>();
    await state.api.markNotificationRead();
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已全部标记为已读'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _markOneRead(Map<String, dynamic> n) async {
    final id = n['id']?.toString() ?? '';
    if (id.isEmpty) return;
    await context.read<DoctorAppState>().api.markNotificationRead(notificationId: id);
    _load();
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
                  onRefresh: _load,
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
          Text('患者问诊、状态变化都会通知您',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> n) {
    final unread = n['is_read'] != true;
    final title = n['title'] as String? ?? '';
    final content = n['content'] as String? ?? '';
    final createdAt = n['created_at'] as String? ?? '';
    final date = createdAt.length >= 16 ? createdAt.substring(0, 16).replaceFirst('T', ' ') : createdAt;
    final type = n['notification_type'] as String? ?? '';

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'new_order':
      case 'consultation':
        icon = Icons.chat_bubble_outline;
        iconColor = const Color(0xFF1A73E8);
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
                decoration: const BoxDecoration(color: Color(0xFFDB4437), shape: BoxShape.circle),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(child: Text(title,
            style: TextStyle(fontSize: 14, fontWeight: unread ? FontWeight.w600 : FontWeight.normal),
          )),
          Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(content,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          maxLines: 2, overflow: TextOverflow.ellipsis,
        ),
      ),
      onTap: () { if (unread) _markOneRead(n); },
    );
  }
}
