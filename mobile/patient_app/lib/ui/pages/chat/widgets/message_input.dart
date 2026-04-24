import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final ValueChanged<String> onSendMessage;
  final VoidCallback? onAttachmentPressed;
  final VoidCallback? onVoicePressed;
  final bool isRecording;
  final String? recordingDuration;

  const MessageInput({
    Key? key,
    required this.onSendMessage,
    this.onAttachmentPressed,
    this.onVoicePressed,
    this.isRecording = false,
    this.recordingDuration,
  }) : super(key: key);

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;
  bool _isVoiceMode = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
    }
  }

  void _toggleVoiceMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 语音/键盘切换按钮
          IconButton(
            onPressed: _toggleVoiceMode,
            icon: Icon(
              _isVoiceMode ? Icons.keyboard : Icons.mic,
              color: colorScheme.primary,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          // 输入区域
          Expanded(
            child: _isVoiceMode ? _buildVoiceInput() : _buildTextInput(),
          ),
          const SizedBox(width: 4),
          // 发送/录音按钮
          _buildActionButton(),
        ],
      ),
    );
  }

  // 构建文本输入
  Widget _buildTextInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // 附件按钮
          if (widget.onAttachmentPressed != null)
            GestureDetector(
              onTap: widget.onAttachmentPressed,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.add_circle_outline,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
            ),
          // 文本输入框
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '输入消息...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
              ),
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  // 构建语音输入
  Widget _buildVoiceInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTapDown: (_) {
        // 开始录音
        if (widget.onVoicePressed != null) {
          widget.onVoicePressed!();
        }
      },
      onTapUp: (_) {
        // 结束录音
        if (widget.onVoicePressed != null) {
          widget.onVoicePressed!();
        }
      },
      onTapCancel: () {
        // 取消录音
        if (widget.onVoicePressed != null) {
          widget.onVoicePressed!();
        }
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: widget.isRecording ? Colors.red.shade50 : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isRecording ? Colors.red : colorScheme.outline.withOpacity(0.2),
            width: widget.isRecording ? 2 : 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic,
                color: widget.isRecording ? Colors.red : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isRecording
                    ? widget.recordingDuration ?? '录音中...'
                    : '按住说话',
                style: TextStyle(
                  color: widget.isRecording ? Colors.red : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建操作按钮
  Widget _buildActionButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isVoiceMode) {
      // 语音模式：表情按钮
      return IconButton(
        onPressed: () {
          // 表情按钮功能
        },
        icon: Icon(
          Icons.emoji_emotions_outlined,
          color: colorScheme.primary,
        ),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      );
    } else {
      // 文本模式：发送按钮
      return GestureDetector(
        onTap: _hasText ? _sendMessage : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hasText ? colorScheme.primary : colorScheme.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              _hasText ? Icons.send : Icons.mic,
              color: _hasText ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      );
    }
  }
}