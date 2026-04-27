import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';

/// 消息输入栏组件
class MessageInputBar extends StatefulWidget {
  final void Function(String text) onSend;
  final void Function()? onAttachment;

  const MessageInputBar({
    super.key,
    required this.onSend,
    this.onAttachment,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          // 附件按钮
          IconButton(
            onPressed: widget.onAttachment,
            icon: const Icon(Icons.add_circle_outline),
            color: AppConfig.textSecondary,
          ),
          // 输入框
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  hintStyle: TextStyle(color: Color(0xFF9AA0A6)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          // 发送按钮
          if (_hasText)
            IconButton(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded),
              color: AppConfig.primaryColor,
            )
          else
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.mic_outlined),
              color: AppConfig.textSecondary,
            ),
        ],
      ),
    );
  }
}
