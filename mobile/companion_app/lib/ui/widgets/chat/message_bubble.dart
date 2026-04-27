import 'package:flutter/material.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/config/app_config.dart';

/// 消息气泡组件
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    // 系统消息
    if (message.messageType == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // 对方头像
            CircleAvatar(
              radius: 16,
              backgroundColor: AppConfig.accentColor.withValues(alpha: 0.1),
              child: const Icon(Icons.person, size: 18, color: AppConfig.accentColor),
            ),
            const SizedBox(width: 8),
          ],
          if (isMe) const Spacer(),

          // 消息内容
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppConfig.primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(context),
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 8),
            // 已读/已发送状态
            if (message.status == MessageStatus.read)
              const Icon(Icons.done_all, size: 14, color: AppConfig.accentColor)
            else if (message.status == MessageStatus.sent)
              const Icon(Icons.done_all, size: 14, color: Colors.grey)
            else if (message.status == MessageStatus.sending)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.grey[400],
                ),
              )
            else
              const Icon(Icons.error_outline, size: 14, color: Colors.red),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.messageType) {
      case MessageType.image:
        return _buildImageContent();
      case MessageType.audio:
        return _buildAudioContent();
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    return Text(
      message.content,
      style: TextStyle(
        color: isMe ? Colors.white : AppConfig.textPrimary,
        fontSize: 15,
      ),
    );
  }

  Widget _buildImageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: Center(
            child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '查看图片',
          style: TextStyle(
            color: isMe ? Colors.white70 : AppConfig.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_circle_filled,
          size: 20,
          color: isMe ? Colors.white : AppConfig.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          '语音消息',
          style: TextStyle(
            color: isMe ? Colors.white : AppConfig.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
