class UserInteraction {
  final String userId;
  final String listingId;
  final String type; // view, favorite, search, bid
  final DateTime timestamp;

  UserInteraction({
    required this.userId,
    required this.listingId,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'listingId': listingId,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
  };
}
