
enum NotificationType {
  comment,
  message,
  favorite,
  alert,
}

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;
  final String type; // 'comment', 'message', 'favorite'
  final String? relatedId; // For linking to specific chat, listing, etc.
  final String? relatedType; // 'listing', 'chat', etc.
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
    this.relatedId,
    this.relatedType,
    this.metadata,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: map['is_read'] ?? false,
      type: map['type'] ?? 'alert',
      relatedId: map['related_id'],
      relatedType: map['related_type'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'type': type,
      'related_id': relatedId,
      'related_type': relatedType,
      'metadata': metadata,
    };
  }

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? type,
    String? relatedId,
    String? relatedType,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      metadata: metadata ?? this.metadata,
    );
  }
}
