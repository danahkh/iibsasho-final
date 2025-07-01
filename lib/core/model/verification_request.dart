class VerificationRequest {
  final String id;
  final String userId;
  final String documentUrl;
  final String status; // pending, approved, rejected
  final DateTime createdAt;

  VerificationRequest({
    required this.id,
    required this.userId,
    required this.documentUrl,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'documentUrl': documentUrl,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };
}
