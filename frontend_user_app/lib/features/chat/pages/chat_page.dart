import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_text_styles.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_button.dart';

class ChatPage extends StatefulWidget {
  final String roomId;
  
  const ChatPage({
    super.key,
    required this.roomId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  late io.Socket _socket;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isSending = false;
  
  @override
  void initState() {
    super.initState();
    _initSocket();
    _loadMessages();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _socket.disconnect();
    super.dispose();
  }
  
  void _initSocket() {
    _socket = io.io(
      'http://localhost:3000',
      io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build()
    );
    
    _socket.onConnect((_) {
      print('Socket connected');
      _socket.emit('join-room', widget.roomId);
    });
    
    _socket.onDisconnect((_) {
      print('Socket disconnected');
    });
    
    _socket.on('new-message', (data) {
      _handleNewMessage(data);
    });
    
    _socket.connect();
  }
  
  Future<void> _loadMessages() async {
    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.get('/chat/messages/${widget.roomId}');
      
      if (response['success']) {
        setState(() {
          _messages = (response['data']['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg))
              .toList();
          _isLoading = false;
        });
        
        // 滚动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('加载消息失败: $e');
      setState(() => _isLoading = false);
    }
  }
  
  void _handleNewMessage(dynamic data) {
    final message = ChatMessage.fromJson(data);
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }
  
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    setState(() => _isSending = true);
    
    try {
      final apiService = context.read<ApiService>();
      final authService = context.read<AuthService>();
      final currentUser = authService.user;
      
      // 获取对方用户ID（这里需要根据业务逻辑实现）
      final otherUserId = _getOtherUserId();
      
      final response = await apiService.post('/chat/send', {
        'room_id': widget.roomId,
        'receiver_id': otherUserId,
        'message_type': 'text',
        'content': text,
      });
      
      if (response['success']) {
        final message = ChatMessage.fromJson(response['data']['message']);
        message.sender = ChatUser(
          id: currentUser!.id,
          name: currentUser.name,
          avatar: currentUser.avatar,
        );
        
        // 通过Socket发送
        _socket.emit('send-message', {
          'roomId': widget.roomId,
          'senderId': currentUser.id,
          'receiverId': otherUserId,
          'messageType': 'text',
          'content': text,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        setState(() {
          _messages.add(message);
          _messageController.clear();
        });
        
        _scrollToBottom();
      }
    } catch (e) {
      print('发送消息失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发送失败，请重试')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }
  
  Future<void> _sendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        // 上传图片并发送
        final apiService = context.read<ApiService>();
        final authService = context.read<AuthService>();
        final currentUser = authService.user;
        
        // 这里需要实现图片上传逻辑
        final uploadResponse = await apiService.post('/chat/upload/image', {
          'image': await image.readAsBytes(),
        });
        
        if (uploadResponse['success']) {
          final otherUserId = _getOtherUserId();
          
          await apiService.post('/chat/send', {
            'room_id': widget.roomId,
            'receiver_id': otherUserId,
            'message_type': 'image',
            'content': uploadResponse['data']['url'],
          });
          
          // 通过Socket发送
          _socket.emit('send-message', {
            'roomId': widget.roomId,
            'senderId': currentUser!.id,
            'receiverId': otherUserId,
            'messageType': 'image',
            'content': uploadResponse['data']['url'],
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('发送图片失败: $e');
    }
  }
  
  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      setState(() => _isRecording = true);
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
      );
    }
  }
  
  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    
    if (path != null) {
      // 上传语音并发送
      _sendVoiceMessage(path);
    }
  }
  
  Future<void> _sendVoiceMessage(String filePath) async {
    try {
      final apiService = context.read<ApiService>();
      final authService = context.read<AuthService>();
      final currentUser = authService.user;
      
      // 这里需要实现语音上传逻辑
      final uploadResponse = await apiService.post('/chat/upload/voice', {
        'voice': filePath,
      });
      
      if (uploadResponse['success']) {
        final otherUserId = _getOtherUserId();
        
        await apiService.post('/chat/send', {
          'room_id': widget.roomId,
          'receiver_id': otherUserId,
          'message_type': 'voice',
          'content': uploadResponse['data']['url'],
        });
        
        // 通过Socket发送
        _socket.emit('send-message', {
          'roomId': widget.roomId,
          'senderId': currentUser!.id,
          'receiverId': otherUserId,
          'messageType': 'voice',
          'content': uploadResponse['data']['url'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('发送语音失败: $e');
    }
  }
  
  int _getOtherUserId() {
    // 这里需要根据业务逻辑获取对方用户ID
    // 可以从消息列表中获取，或者从路由参数获取
    if (_messages.isNotEmpty) {
      final firstMessage = _messages.first;
      final currentUser = context.read<AuthService>().user;
      return firstMessage.senderId == currentUser!.id
          ? firstMessage.receiverId
          : firstMessage.senderId;
    }
    return 0; // 默认值，实际应用中需要正确处理
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
    final currentUser = context.watch<AuthService>().user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // 显示更多选项
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('暂无消息'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.w),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == currentUser?.id;
                          
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),
          
          // 输入区域
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.gray200),
              ),
            ),
            child: Row(
              children: [
                // 语音按钮
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? Colors.red : AppColors.primary,
                  ),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                
                // 图片按钮
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _sendImage,
                ),
                
                // 输入框
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(24.w),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '输入消息...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                // 发送按钮
                _isSending
                    ? Padding(
                        padding: EdgeInsets.all(8.w),
                        child: SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.send,
                            size: 20.w,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: _sendMessage,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16.w,
              backgroundImage: message.sender?.avatar != null
                  ? NetworkImage(message.sender!.avatar!)
                  : null,
              child: message.sender?.avatar == null
                  ? Icon(Icons.person, size: 16.w)
                  : null,
            ),
            SizedBox(width: 8.w),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe && message.sender != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      message.sender!.name,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.gray100,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.w),
                      topRight: Radius.circular(16.w),
                      bottomLeft: isMe
                          ? Radius.circular(16.w)
                          : Radius.circular(4.w),
                      bottomRight: isMe
                          ? Radius.circular(4.w)
                          : Radius.circular(16.w),
                    ),
                  ),
                  child: _buildMessageContent(message),
                ),
                
                SizedBox(height: 4.h),
                
                Text(
                  _formatTime(message.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          
          if (isMe) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 16.w,
              backgroundImage: message.sender?.avatar != null
                  ? NetworkImage(message.sender!.avatar!)
                  : null,
              child: message.sender?.avatar == null
                  ? Icon(Icons.person, size: 16.w)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMessageContent(ChatMessage message) {
    switch (message.messageType) {
      case 'text':
        return Text(
          message.content,
          style: AppTextStyles.body1.copyWith(
            color: message.senderId == context.read<AuthService>().user?.id
                ? Colors.white
                : AppColors.gray900,
          ),
        );
        
      case 'image':
        return GestureDetector(
          onTap: () {
            // 查看大图
          },
          child: Container(
            width: 200.w,
            height: 200.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.w),
              image: DecorationImage(
                image: NetworkImage(message.content),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
        
      case 'voice':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic,
              size: 20.w,
              color: message.senderId == context.read<AuthService>().user?.id
                  ? Colors.white
                  : AppColors.primary,
            ),
            SizedBox(width: 8.w),
            Text(
              '语音消息',
              style: AppTextStyles.body1.copyWith(
                color: message.senderId == context.read<AuthService>().user?.id
                    ? Colors.white
                    : AppColors.gray900,
              ),
            ),
          ],
        );
        
      case 'system':
        return Text(
          message.content,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.gray600,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        );
        
      default:
        return Text(
          message.content,
          style: AppTextStyles.body1,
        );
    }
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      return '昨天 ${DateFormat('HH:mm').format(time)}';
    } else {
      return DateFormat('MM/dd HH:mm').format(time);
    }
  }
}

class ChatMessage {
  final int id;
  final String roomId;
  final int senderId;
  final int receiverId;
  final String messageType;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  ChatUser? sender;
  
  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.receiverId,
    required this.messageType,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.sender,
  });
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      roomId: json['room_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      messageType: json['message_type'],
      content: json['content'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
      sender: json['sender'] != null
          ? ChatUser.fromJson(json['sender'])
          : null,
    );
  }
}

class ChatUser {
  final int id;
  final String name;
  final String? avatar;
  
  ChatUser({
    required this.id,
    required this.name,
    this.avatar,
  });
  
  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
    );
  }
}