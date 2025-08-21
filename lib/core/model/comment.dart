class Comment {
  final String id;
  final String listingId;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String text;
  final DateTime createdAt;

  final String? parentId; // null for top-level
  final int likeCount;

  Comment({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.likeCount = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Attempt to pull display info from flattened columns first, then joined users relation
    final usersRel = json['users'];
    String derivedName = json['user_name'] ?? '';
    if ((derivedName.isEmpty) && usersRel is Map) {
      derivedName = usersRel['display_name'] ?? usersRel['name'] ?? '';
    }
    String derivedPhoto = json['user_photo_url'] ?? '';
    if ((derivedPhoto.isEmpty) && usersRel is Map) {
      derivedPhoto = usersRel['photo_url'] ?? '';
    }

    return Comment(
      id: json['id'] ?? '',
      listingId: json['listing_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: derivedName,
      userPhotoUrl: derivedPhoto,
      text: json['text'] ?? json['content'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      parentId: json['parent_id'],
      likeCount: (json['like_count'] is int)
          ? json['like_count']
          : int.tryParse(json['like_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'user_id': userId,
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
      // Provide both keys for forward/backward compatibility
      'text': text,
      'content': text,
      'created_at': createdAt.toIso8601String(),
  'parent_id': parentId,
  'like_count': likeCount,
    };
  }
}
