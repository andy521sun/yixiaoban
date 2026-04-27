import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/providers/companion_state.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/config/app_config.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/message_input.dart';

/// 聊天详情页 - 与患者实时沟通
class ChatDetailPage extends StatefulWidget {
  final String sessionId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String currentUserId;
  final String? orderId;

  const ChatDetailPage({
    super.key,
    required this.sessionId,
    required this.otherUserId,
    required this.otherUserName,
    required this.currentUserId,
    this.otherUserAvatar,
    this.orderId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chatService.setToken(context.read<CompanionState>().token);
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);

    final messages = await _chatService.getChatHistory(
      otherUserId: widget.otherUserId,
      orderId: widget.orderId,
    );

    if (!mounted) return;
    setState(() {
      // 如果没有历史记录，加载示例消息
      if (messages.isEmpty) {
        _messages.addAll(_mockMessages());
      } else {
        _messages.addAll(messages);
      }
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  List<ChatMessage> _mockMessages() {
    return [
      ChatMessage(
        id: 'sys_1',
        senderId: 'system',
        receiverId: widget.currentUserId,
        content: '您已与${widget.otherUserName}建立联系，请注意服务礼仪',
        messageType: MessageType.system,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        id: 'msg_1',
        senderId: widget.otherUserId,
        receiverId: widget.currentUserId,
        content: '您好，请问明天几点到医院比较方便？',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_2',
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        content: '您好！建议您9点前到，我会在一楼大厅等您',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_3',
        senderId: widget.otherUserId,
        receiverId: widget.currentUserId,
        content: '好的，那我明天8:45到，到了联系您',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_4',
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        content: '没问题！记得带好身份证和医保卡',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'msg_5',
        senderId: widget.otherUserId,
        receiverId: widget.currentUserId,
        content: '好的，谢谢提醒 🙏',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        status: MessageStatus.read,
      ),
    ];
  }

  void _sendMessage(String text) {
    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: widget.currentUserId,
      receiverId: widget.otherUserId,
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      orderId: widget.orderId,
    );

    setState(() => _messages.add(msg));
    _scrollToBottom();

    // 通过API发送
    _chatService.sendMessage(
      receiverId: widget.otherUserId,
      content: text,
      orderId: widget.orderId,
    ).then((ok) {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx != -1) {
          _messages[idx] = msg.copyWith(status: ok ? MessageStatus.sent : MessageStatus.failed);
        }
      });
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // 头像
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConfig.accentColor.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0]
                      : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConfig.accentColor,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '在线',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppConfig.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.orderId != null)
            IconButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/order/detail',
                arguments: {'order_id': widget.orderId},
              ),
              icon: const Icon(Icons.receipt_outlined),
            ),
          PopupMenuButton(
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'info', child: Text('用户信息')),
              const PopupMenuItem(value: 'clear', child: Text('清空聊天记录')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 订单关联提示
          if (widget.orderId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppConfig.accentColor.withValues(alpha: 0.05),
              child: Row(
                children: [
                  const Icon(Icons.receipt, size: 16, color: AppConfig.accentColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '订单相关聊天',
                      style: TextStyle(
                        color: AppConfig.accentColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '订单号: ${widget.orderId}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),

          // 消息列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final msg = _messages[i];
                          return MessageBubble(
                            message: msg,
                            isMe: msg.senderId == widget.currentUserId,
                          );
                        },
                      ),
          ),

          // 输入栏
          MessageInputBar(
            onSend: _sendMessage,
            onAttachment: () => _showAttachmentSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '开始与${widget.otherUserName}聊天',
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
        ],
      ),
    );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: AppConfig.primaryColor),
              title: const Text('发送图片'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: AppConfig.accentColor),
              title: const Text('发送位置'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
