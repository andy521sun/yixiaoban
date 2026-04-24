import 'package:flutter/material.dart';
import './widgets/chat_item.dart';
import './models/chat_message.dart';
import './chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final List<ChatSession> _sessions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _currentUserId = 'user_001'; // 模拟当前用户ID

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  Future<void> _loadChatSessions() async {
    // 模拟加载延迟
    await Future.delayed(const Duration(milliseconds: 500));

    // 模拟数据
    final mockSessions = [
      ChatSession(
        id: '1',
        otherUserId: 'companion_001',
        otherUserName: '张医生',
        otherUserAvatar: null,
        lastMessage: ChatMessage(
          id: 'msg_1',
          senderId: 'companion_001',
          receiverId: _currentUserId,
          content: '您好，我是您的陪诊医生，明天上午9点医院见',
          messageType: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          status: MessageStatus.read,
        ),
        unreadCount: 0,
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        orderId: 'order_001',
      ),
      ChatSession(
        id: '2',
        otherUserId: 'companion_002',
        otherUserName: '李护士',
        otherUserAvatar: null,
        lastMessage: ChatMessage(
          id: 'msg_2',
          senderId: _currentUserId,
          receiverId: 'companion_002',
          content: '好的，我会准时到达',
          messageType: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          status: MessageStatus.read,
        ),
        unreadCount: 3,
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        orderId: 'order_002',
      ),
      ChatSession(
        id: '3',
        otherUserId: 'companion_003',
        otherUserName: '王医生',
        otherUserAvatar: null,
        lastMessage: ChatMessage(
          id: 'msg_3',
          senderId: 'companion_003',
          receiverId: _currentUserId,
          content: '检查报告已经出来了，请查看',
          messageType: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          status: MessageStatus.read,
        ),
        unreadCount: 0,
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ChatSession(
        id: '4',
        otherUserId: 'companion_004',
        otherUserName: '赵医生',
        otherUserAvatar: null,
        lastMessage: ChatMessage(
          id: 'msg_4',
          senderId: _currentUserId,
          receiverId: 'companion_004',
          content: '谢谢您的帮助！',
          messageType: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          status: MessageStatus.read,
        ),
        unreadCount: 0,
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        orderId: 'order_003',
      ),
      ChatSession(
        id: '5',
        otherUserId: 'companion_005',
        otherUserName: '刘医生',
        otherUserAvatar: null,
        lastMessage: ChatMessage(
          id: 'msg_5',
          senderId: 'companion_005',
          receiverId: _currentUserId,
          content: '[图片]',
          messageType: MessageType.image,
          timestamp: DateTime.now().subtract(const Duration(days: 7)),
          status: MessageStatus.read,
        ),
        unreadCount: 1,
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];

    setState(() {
      _sessions.clear();
      _sessions.addAll(mockSessions);
      _isLoading = false;
    });
  }

  List<ChatSession> get _filteredSessions {
    if (_searchQuery.isEmpty) {
      return _sessions;
    }
    return _sessions.where((session) {
      return session.displayName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _onChatItemTap(ChatSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          sessionId: session.id,
          otherUserId: session.otherUserId,
          otherUserName: session.otherUserName,
          otherUserAvatar: session.otherUserAvatar,
          currentUserId: _currentUserId,
          orderId: session.orderId,
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onCreateNewChat() {
    // TODO: 实现创建新聊天功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('创建新聊天功能开发中...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadChatSessions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: '搜索聊天...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // 聊天列表
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredSessions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadChatSessions,
                        child: ListView.separated(
                          itemCount: _filteredSessions.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 0,
                            color: colorScheme.outline.withOpacity(0.1),
                          ),
                          itemBuilder: (context, index) {
                            final session = _filteredSessions[index];
                            return ChatItem(
                              session: session,
                              onTap: () => _onChatItemTap(session),
                              currentUserId: _currentUserId,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreateNewChat,
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? '暂无聊天记录' : '未找到相关聊天',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isEmpty)
            Text(
              '开始与陪诊师沟通吧',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty)
            ElevatedButton(
              onPressed: _onCreateNewChat,
              child: const Text('开始聊天'),
            ),
        ],
      ),
    );
  }
}