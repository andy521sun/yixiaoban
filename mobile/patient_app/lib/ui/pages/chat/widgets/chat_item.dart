import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatItem extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onTap;
  final String currentUserId;

  const ChatItem({
    Key? key,
    required this.session,
    required this.onTap,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: onTap,
      splashColor: colorScheme.primary.withOpacity(0.1),
      highlightColor: colorScheme.primary.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 头像
            _buildAvatar(),
            const SizedBox(width: 12),
            // 聊天信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称和最后消息时间
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.displayName,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (session.lastMessage != null)
                        Text(
                          _formatTime(session.lastMessage!.timestamp),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 最后消息内容
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getLastMessagePreview(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: session.hasUnread
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            fontWeight: session.hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 未读消息计数
                      if (session.hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            session.unreadCount > 99
                                ? '99+'
                                : session.unreadCount.toString(),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // 订单标签（如果有）
                  if (session.orderId != null) _buildOrderTag(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建头像
  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade100,
        image: session.otherUserAvatar != null
            ? DecorationImage(
                image: NetworkImage(session.otherUserAvatar!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: session.otherUserAvatar == null
          ? Center(
              child: Text(
                session.displayName.isNotEmpty
                    ? session.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            )
          : null,
    );
  }

  // 获取最后消息预览
  String _getLastMessagePreview() {
    if (session.lastMessage == null) {
      return '暂无消息';
    }

    final message = session.lastMessage!;
    final isSentByMe = message.isSentByMe(currentUserId);
    final prefix = isSentByMe ? '你：' : '';

    switch (message.messageType) {
      case MessageType.text:
        return '$prefix${message.content}';
      case MessageType.image:
        return '${prefix}[图片]';
      case MessageType.audio:
        return '${prefix}[语音]';
      case MessageType.video:
        return '${prefix}[视频]';
      case MessageType.file:
        return '${prefix}[文件]';
      case MessageType.location:
        return '${prefix}[位置]';
      default:
        return '${prefix}[消息]';
    }
  }

  // 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) {
      // 今天：显示时间
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      // 昨天
      return '昨天';
    } else if (now.difference(messageDay).inDays < 7) {
      // 一周内：显示星期几
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[messageDay.weekday - 1];
    } else {
      // 更早：显示日期
      return '${messageDay.month}/${messageDay.day}';
    }
  }

  // 构建订单标签
  Widget _buildOrderTag() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.shade200, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt,
            size: 12,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            '订单聊天',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}