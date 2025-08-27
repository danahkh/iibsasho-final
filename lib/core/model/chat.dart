import 'dart:convert';
class Chat {
  final String id;
  final String listingId;
  final String sellerId;
  final String buyerId;
  final String listingTitle;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String otherUserName;
  final String? otherUserAvatar;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.listingId,
    required this.sellerId,
    required this.buyerId,
    required this.listingTitle,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.createdAt,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    // unread_count may be an int, string, or json (per-user map). Default to 0.
    int parseUnread(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      if (v is Map) return 0; // per-user map not resolvable here
      return 0;
    }
    return Chat(
      id: map['id'] ?? '',
      listingId: map['listing_id'] ?? '',
      sellerId: map['seller_id'] ?? '',
      buyerId: map['buyer_id'] ?? '',
      listingTitle: map['listing_title'] ?? '',
      lastMessage: map['last_message'] ?? '',
      lastMessageTime: DateTime.parse(map['last_message_time'] ?? DateTime.now().toIso8601String()),
      unreadCount: parseUnread(map['unread_count']),
      otherUserName: map['other_user_name'] ?? '',
      otherUserAvatar: map['other_user_avatar'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listing_id': listingId,
      'seller_id': sellerId,
      'buyer_id': buyerId,
      'listing_title': listingTitle,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
      'other_user_name': otherUserName,
      'other_user_avatar': otherUserAvatar,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? type; // e.g., 'text', 'listing_ref'
  final Map<String, dynamic>? metadata; // optional payload for rich messages

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    required this.isRead,
  this.type,
  this.metadata,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    // Pass through optional type/metadata when present; otherwise, null
    final dynamicMeta = map['metadata'];
    Map<String, dynamic>? metaMap;
    if (dynamicMeta is Map) {
      metaMap = Map<String, dynamic>.from(dynamicMeta);
    } else if (dynamicMeta is String && dynamicMeta.trim().isNotEmpty) {
      // If metadata stored as JSON string
      try {
        metaMap = Map<String, dynamic>.from(jsonDecode(dynamicMeta));
      } catch (_) {}
    }
    return Message(
      id: map['id'] ?? '',
      chatId: map['chat_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: map['is_read'] ?? false,
      type: map['type'],
      metadata: metaMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
  if (type != null) 'type': type,
  if (metadata != null) 'metadata': metadata,
    };
  }
}
