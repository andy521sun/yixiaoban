/// 聊天消息数据模型
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final DateTime timestamp;
  final MessageStatus status;
  final String? orderId;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.orderId,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? messageType,
    DateTime? timestamp,
    MessageStatus? status,
    String? orderId,
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
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? json['message_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      content: json['content'] ?? json['message'] ?? '',
      messageType: _parseType(json['message_type'] ?? json['type'] ?? 'text'),
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      status: _parseStatus(json['status'] ?? 'sent'),
      orderId: json['order_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'content': content,
    'message_type': messageType.name,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'order_id': orderId,
  };

  static MessageType _parseType(String type) {
    switch (type) {
      case 'image': return MessageType.image;
      case 'audio': return MessageType.audio;
      case 'system': return MessageType.system;
      default: return MessageType.text;
    }
  }

  static MessageStatus _parseStatus(String status) {
    switch (status) {
      case 'sending': return MessageStatus.sending;
      case 'sent': return MessageStatus.sent;
      case 'read': return MessageStatus.read;
      default: return MessageStatus.sent;
    }
  }
}

enum MessageType { text, image, audio, system }

enum MessageStatus { sending, sent, read, failed }
