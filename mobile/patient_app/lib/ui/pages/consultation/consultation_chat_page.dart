import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../main.dart';

/// 问诊聊天室 — 患者与医生实时对话，支持 WebSocket 实时推送 + HTTP 兜底
class ConsultationChatPage extends StatefulWidget {
  const ConsultationChatPage({super.key});

  @override
  State<ConsultationChatPage> createState() => _ConsultationChatPageState();
}

class _ConsultationChatPageState extends State<ConsultationChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  String _consultationId = '';
  Map<String, dynamic>? _doctor;
  Map<String, dynamic>? _consultation;
  bool _loading = true;
  bool _submitting = false;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  bool _wsConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _consultationId = args['consultation_id'] as String? ?? '';
        _doctor = args['doctor'] as Map<String, dynamic>?;
        _loadConsultation();
        _listenWs();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _wsSubscription?.cancel();
    super.dispose();
  }

  /// 监听 WebSocket 实时新消息
  void _listenWs() {
    final appState = context.read<AppState>();
    _wsConnected = appState.ws.isConnected;
    _wsSubscription = appState.ws.messages.listen((msg) {
      if (msg['type'] == 'consultation_message') {
        final data = msg['data'] as Map<String, dynamic>?;
        if (data != null) {
          final msgConsultId = data['consultation_id']?.toString() ?? '';
          if (msgConsultId == _consultationId) {
            if (mounted) {
              setState(() {
                _messages.add(_ChatMessage.fromApi(data));
              });
              _scrollToBottom();
            }
          }
        }
      }
    });

    // 监听 WS 连接状态
    appState.ws.connectionState.listen((connected) {
      if (mounted) setState(() => _wsConnected = connected);
    });
  }

  Future<void> _loadConsultation() async {
    if (_consultationId.isEmpty) return;

    final appState = context.read<AppState>();
    final res = await appState.api.getConsultationDetail(_consultationId);

    if (!mounted) return;
    if (res != null) {
      setState(() {
        _consultation = res;
        _loading = false;
      });
      _loadMessages();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    final appState = context.read<AppState>();
    final data = await appState.api.getConsultationDetail(_consultationId);
    if (data == null || !mounted) return;

    final msgs = data['messages'] as List? ?? [];
    final status = data['status'] as String? ?? '';
    setState(() {
      _messages.clear();
      for (final m in msgs) {
        _messages.add(_ChatMessage.fromApi(m as Map<String, dynamic>));
      }
      _consultation = data;
      if (!_loading) _consultation?['status'] = status;
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty || _submitting) return;

    final appState = context.read<AppState>();
    final token = appState.token;
    if (token.isEmpty) return;

    setState(() => _submitting = true);

    // 本地先显示
    final tempMsg = _ChatMessage(
      id: 'sending_${DateTime.now().millisecondsSinceEpoch}',
      senderId: appState.userName,
      content: content,
      msgType: 'text',
      timestamp: DateTime.now(),
      isSent: true,
    );
    setState(() => _messages.add(tempMsg));
    _textController.clear();
    _scrollToBottom();

    try {
      final res = await appState.api.getConsultationDetail(_consultationId);
      await Future.delayed(const Duration(milliseconds: 100));

      // 直接用 ApiService 发消息
      final state = context.read<AppState>();
      await state.api.createConsultation({'dummy': true}); // 实际用 http 发

      // 用 http 直接发
      await _httpSendMessage(content);
    } catch (e) {
      debugPrint('发送消息失败: $e');
    }

    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _httpSendMessage(String content) async {
    final appState = context.read<AppState>();
    final token = appState.token;
    if (token.isEmpty) return;

    try {
      final uri = Uri.parse('/api/consultations/$_consultationId/messages');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'msg_type': 'text',
          'content': content,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        // 不重复加载，等 WebSocket 推送回消息
      } else {
        _loadMessages();
      }
    } catch (e) {
      debugPrint('HTTP发送消息失败: $e');
      _loadMessages(); // 兜底刷新
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = _doctor?['name'] as String? ?? '医生';
    final doctorTitle = _doctor?['title'] as String? ?? '';
    final doctorDept = _doctor?['department'] as String? ?? '';

    final status = _consultation?['status'] as String? ?? 'active';
    final isActive = status == 'active' || status == 'in_progress';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(doctorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                if (_wsConnected)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34A853),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            if (doctorTitle.isNotEmpty)
              Text('$doctorTitle · $doctorDept',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_information_outlined),
            tooltip: '查看处方',
            onPressed: () {
              Navigator.pushNamed(context, '/consultation/prescription',
                arguments: {'consultation_id': _consultationId},
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 状态栏
          if (!isActive && _consultation != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(_statusText(status),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),

          // 消息列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyChat(context, doctorName)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
                      ),
          ),

          // 输入区域
          if (isActive)
            _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(BuildContext context, String doctorName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 36, color: Color(0xFF1A73E8)),
          ),
          const SizedBox(height: 16),
          Text('开始与 $doctorName 医生沟通',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text('请详细描述您的病情，医生会尽快回复',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isMe = msg.isSent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.1),
              child: Text(_doctor?['name']?[0] ?? '医',
                style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1A73E8) : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (msg.msgType == 'image' && msg.mediaUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        msg.mediaUrl!,
                        width: 200, height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
                      ),
                    )
                  else
                    Text(msg.content,
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    // TODO: 集成图片选择器
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.image_outlined, color: Colors.grey[600], size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: '输入病情描述...',
                      hintStyle: TextStyle(color: Color(0xFF9AA0A6), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (v) => _sendMessage(v),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: _textController.text.isNotEmpty
                    ? const Color(0xFF1A73E8)
                    : Colors.grey[300],
                shape: const CircleBorder(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _sendMessage(_textController.text),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending': return '等待医生接诊...';
      case 'active': case 'in_progress': return '问诊进行中...';
      case 'completed': return '问诊已完成';
      case 'cancelled': return '问诊已取消';
      case 'rated': return '已评价';
      default: return '状态: $status';
    }
  }
}

class _ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final String msgType;
  final DateTime timestamp;
  final bool isSent;
  final String? mediaUrl;
  final String? mediaThumbnail;

  _ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    this.msgType = 'text',
    required this.timestamp,
    this.isSent = false,
    this.mediaUrl,
    this.mediaThumbnail,
  });

  factory _ChatMessage.fromApi(Map<String, dynamic> data) {
    final isSent = data['sender_role'] == 'patient' || data['role'] == 'patient';
    return _ChatMessage(
      id: data['id']?.toString() ?? '',
      senderId: data['sender_id']?.toString() ?? '',
      content: data['content'] as String? ?? '',
      msgType: data['msg_type'] as String? ?? 'text',
      timestamp: data['created_at'] != null
          ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
          : DateTime.now(),
      isSent: isSent,
      mediaUrl: data['media_url'] as String?,
      mediaThumbnail: data['media_thumbnail'] as String?,
    );
  }
}

