// 聊天消息数据模型
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final DateTime timestamp;
  final MessageStatus status;
  final String? orderId;
  final String? attachmentUrl;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.orderId,
    this.attachmentUrl,
    this.metadata,
  });

  // 从JSON创建消息
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      messageType: _parseMessageType(json['messageType']),
      timestamp: DateTime.parse(json['timestamp']),
      status: _parseMessageStatus(json['status']),
      orderId: json['orderId'],
      attachmentUrl: json['attachmentUrl'],
      metadata: json['metadata'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'orderId': orderId,
      'attachmentUrl': attachmentUrl,
      'metadata': metadata,
    };
  }

  // 复制消息并更新状态
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? messageType,
    DateTime? timestamp,
    MessageStatus? status,
    String? orderId,
    String? attachmentUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  // 判断是否是当前用户发送的消息
  bool isSentByMe(String currentUserId) {
    return senderId == currentUserId;
  }

  // 静态方法：解析消息类型
  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }

  // 静态方法：解析消息状态
  static MessageStatus _parseMessageStatus(String? status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  @override
  String toString() {
    return 'ChatMessage{id: $id, senderId: $senderId, content: ${content.length > 20 ? '${content.substring(0, 20)}...' : content}, status: $status}';
  }
}

// 消息类型枚举
enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  location,
}

// 消息状态枚举
enum MessageStatus {
  sending,    // 发送中
  sent,       // 已发送
  delivered,  // 已送达
  read,       // 已读
  failed,     // 发送失败
}

// 聊天会话模型
class ChatSession {
  final String id;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final String? orderId;

  ChatSession({
    required this.id,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    this.orderId,
  });

  // 从JSON创建会话
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] ?? '',
      otherUserId: json['otherUserId'] ?? '',
      otherUserName: json['otherUserName'],
      otherUserAvatar: json['otherUserAvatar'],
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: DateTime.parse(json['updatedAt']),
      orderId: json['orderId'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserAvatar': otherUserAvatar,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'updatedAt': updatedAt.toIso8601String(),
      'orderId': orderId,
    };
  }

  // 复制会话并更新
  ChatSession copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
    String? orderId,
  }) {
    return ChatSession(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      orderId: orderId ?? this.orderId,
    );
  }

  // 判断是否有未读消息
  bool get hasUnread => unreadCount > 0;

  // 获取显示名称
  String get displayName {
    return otherUserName ?? '用户$otherUserId';
  }

  @override
  String toString() {
    return 'ChatSession{id: $id, otherUser: $displayName, unread: $unreadCount}';
  }
}