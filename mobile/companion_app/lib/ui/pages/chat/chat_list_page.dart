import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/companion_state.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/config/app_config.dart';
import 'chat_detail_page.dart';

/// 聊天列表页 - 显示所有对话
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chatService.setToken(context.read<CompanionState>().token);
    _loadConversations();
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    final conversations = await _chatService.getConversations();
    if (!mounted) return;
    setState(() {
      _conversations = conversations;
      _loading = false;
    });
  }

  void _openChat(Map<String, dynamic> conv) {
    final otherUser = conv['other_user'] as Map<String, dynamic>? ?? {};

    // 尝试获取 currentUserId
    final state = context.read<CompanionState>();
    final currentUserId = state.profile?['user_id'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          sessionId: conv['room_id'] ?? '',
          otherUserId: otherUser['id'] ?? '',
          otherUserName: otherUser['name'] ?? '用户',
          currentUserId: currentUserId,
        ),
      ),
    ).then((_) => _loadConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('暂无消息',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('开始接单后，即可与患者沟通',
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final conv = _conversations[i];
                      return _buildConversationItem(conv);
                    },
                  ),
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conv) {
    final otherUser = conv['other_user'] as Map<String, dynamic>? ?? {};
    final lastMsg = conv['last_message'] as Map<String, dynamic>? ?? {};
    final userName = otherUser['name'] ?? '用户';
    final userAvatar = otherUser['avatar'] as String?;
    final lastContent = lastMsg['content'] ?? '';
    final lastTime = lastMsg['created_at'] ?? '';
    final unread = conv['unread_count'] ?? 0;

    String timeStr = '';
    if (lastTime is String && lastTime.isNotEmpty) {
      try {
        final dt = DateTime.parse(lastTime);
        final now = DateTime.now();
        if (dt.day == now.day) {
          timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else if (dt.day == now.day - 1) {
          timeStr = '昨天';
        } else {
          timeStr = '${dt.month}/${dt.day}';
        }
      } catch (_) {
        timeStr = '';
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppConfig.primaryColor.withValues(alpha: 0.1),
            backgroundImage: userAvatar != null
                ? NetworkImage(userAvatar)
                : null,
            child: userAvatar == null
                ? Text(
                    userName.toString()[0],
                    style: const TextStyle(
                      color: AppConfig.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          if (unread > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        userName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        lastContent.toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 13,
        ),
      ),
      trailing: Text(
        timeStr,
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
      onTap: () => _openChat(conv),
    );
  }
}
