import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
// import deprecated
import '../../../core/config/app_config.dart';
import './widgets/message_bubble.dart';
import './widgets/message_input.dart';
import './models/chat_message.dart';

class ChatDetailPage extends StatefulWidget {
  final String sessionId;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String currentUserId;
  final String? orderId;

  const ChatDetailPage({
    Key? key,
    required this.sessionId,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    required this.currentUserId,
    this.orderId,
  }) : super(key: key);

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isRecording = false;
  String _recordingDuration = '00:00';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWebSocket();
  }

  Future<void> _loadMessages() async {
    // 模拟加载消息
    await Future.delayed(const Duration(milliseconds: 300));

    final mockMessages = [
      ChatMessage(
        id: '1',
        senderId: widget.otherUserId,
        receiverId: widget.currentUserId,
        content: '您好，我是${widget.otherUserName ?? '陪诊师'}',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '2',
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        content: '您好，很高兴认识您',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '3',
        senderId: widget.otherUserId,
        receiverId: widget.currentUserId,
        content: '明天的预约时间是上午9点，请准时到达',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '4',
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        content: '好的，我会准时到达的',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '5',
        senderId: widget.otherUserId,
        receiverId: widget.currentUserId,
        content: '记得带上身份证和医保卡',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '6',
        senderId: widget.otherUserId,
        receiverId: widget.currentUserId,
        content: '这是医院的路线图',
        messageType: MessageType.image,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '7',
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        content: '谢谢，我已经保存了',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        status: MessageStatus.read,
      ),
    ];

    setState(() {
      _messages.clear();
      _messages.addAll(mockMessages);
      _isLoading = false;
    });

    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setupWebSocket() {
    final wsService = context.read<dynamic>();
    
    // 连接WebSocket
    if (!wsService.isConnected && !wsService.isConnecting) {
      wsService.connect();
    }
    
    // 监听新消息
    wsService.addEventListener('chat_message', _handleNewMessage);
    wsService.addListener(_onWsConnected);
  }

  void _onWsConnected() {
    if (mounted) setState(() {});
  }

  void _handleNewMessage(dynamic data) {
    if (!mounted) return;
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final msg = ChatMessage(
      id: map['message_id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: map['sender_id'] ?? '',
      receiverId: map['receiver_id'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      orderId: map['order_id'],
    );
    setState(() => _messages.add(msg));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    final wsService = context.read<dynamic>();
    wsService.removeEventListener('chat_message', _handleNewMessage);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSendMessage(String text) {
    final newMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: widget.currentUserId,
      receiverId: widget.otherUserId,
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      orderId: widget.orderId,
    );

    setState(() {
      _messages.add(newMessage);
    });

    _sendMessageViaApi(newMessage);

    // 滚动到底部
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessageViaApi(ChatMessage message) {
    final wsService = context.read<dynamic>();
    
    if (wsService.isConnected) {
      // 通过WebSocket发送
      wsService.sendChatMessage(
        receiverId: message.receiverId,
        content: message.content,
        orderId: message.orderId,
      );
      _markMessageSent(message.id);
    } else {
      // HTTP备用
      _sendViaHttp(message);
    }
  }

  void _markMessageSent(String messageId) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(status: MessageStatus.sent);
        }
      });
    });
  }

  void _sendViaHttp(ChatMessage message) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/realtime/chat/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'receiver_id': message.receiverId,
          'content': message.content,
          'order_id': message.orderId,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        _markMessageSent(message.id);
      }
    } catch (e) {
      debugPrint('HTTP发送消息失败: $e');
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((msg) => msg.id == message.id);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(status: MessageStatus.failed);
          }
        });
      }
    }
  }

  void _receiveMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });

    // 滚动到底部
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onAttachmentPressed() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('照片'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 选择照片
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('视频'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 选择视频
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('文件'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 选择文件
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('位置'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 发送位置
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onVoicePressed() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      // 开始录音
      _startRecording();
    } else {
      // 结束录音
      _stopRecording();
    }
  }

  void _startRecording() {
    // TODO: 开始录音
    int seconds = 0;
    _recordingDuration = '00:00';

    // 模拟录音计时
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      seconds++;
      final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
      final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
      setState(() {
        _recordingDuration = '$minutes:$remainingSeconds';
      });
      return _isRecording;
    });
  }

  void _stopRecording() {
    // TODO: 停止录音并发送
    if (_recordingDuration != '00:00') {
      final voiceMessage = ChatMessage(
        id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
        senderId: widget.currentUserId,
        receiverId: widget.otherUserId,
        content: '语音消息',
        messageType: MessageType.audio,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        orderId: widget.orderId,
      );

      setState(() {
        _messages.add(voiceMessage);
      });

      _sendViaHttp(voiceMessage);
    }
  }

  String get _displayName {
    return widget.otherUserName ?? '用户${widget.otherUserId}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // 头像
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade100,
                image: widget.otherUserAvatar != null
                    ? DecorationImage(
                        image: NetworkImage(widget.otherUserAvatar!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.otherUserAvatar == null
                  ? Center(
                      child: Text(
                        _displayName.isNotEmpty
                            ? _displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    )
                  : null,
            ),
            // 名称和状态
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  '在线',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.orderId != null)
            IconButton(
              onPressed: () {
                // 查看订单详情
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('查看订单 ${widget.orderId}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.receipt),
            ),
          IconButton(
            onPressed: () {
              // 更多操作
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('用户信息'),
                          onTap: () {
                            Navigator.pop(context);
                            // 查看用户信息（待实现）
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.notifications),
                          title: const Text('消息通知设置'),
                          onTap: () {
                            Navigator.pop(context);
                            // 通知设置（待实现）
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('清空聊天记录'),
                          onTap: () {
                            Navigator.pop(context);
                            // 清空聊天记录（待实现）
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.report),
                          title: const Text('举报用户'),
                          onTap: () {
                            Navigator.pop(context);
                            // 举报功能（待实现）
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // 订单信息横幅（如果有订单）
          if (widget.orderId != null) _buildOrderBanner(),
          // 消息列表
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return MessageBubble(
                            message: message,
                            currentUserId: widget.currentUserId,
                          );
                        },
                      ),
          ),
          // 消息输入框
          MessageInput(
            onSendMessage: _onSendMessage,
            onAttachmentPressed: _onAttachmentPressed,
            onVoicePressed: _onVoicePressed,
            isRecording: _isRecording,
            recordingDuration: _recordingDuration,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          const Icon(
            Icons.receipt,
            size: 20,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '订单 ${widget.orderId} 相关聊天',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // 查看订单详情
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('跳转到订单 ${widget.orderId}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              '查看订单',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
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
            '暂无聊天记录',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始与${_displayName}沟通吧',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}