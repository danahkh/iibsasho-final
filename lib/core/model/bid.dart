class Bid {
  final String id;
  final String listingId;
  final String userId;
  final double amount;
  final DateTime timestamp;

  Bid({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.amount,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'listingId': listingId,
    'userId': userId,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
  };
}
