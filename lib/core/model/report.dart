class Report {
  final String id;
  final String reportedId; // listingId or userId
  final String type; // 'listing' or 'user'
  final String reason;
  final String details;
  final String reporterId;
  final DateTime createdAt;
  final bool resolved;

  Report({
    required this.id,
    required this.reportedId,
    required this.type,
    required this.reason,
    required this.details,
    required this.reporterId,
    required this.createdAt,
    required this.resolved,
  });

  Map<String, dynamic> toMap() => {
    'reportedId': reportedId,
    'type': type,
    'reason': reason,
    'details': details,
    'reporterId': reporterId,
    'createdAt': createdAt.toIso8601String(),
    'resolved': resolved,
  };

  static Report fromMap(Map<String, dynamic> map, String id) => Report(
    id: id,
    reportedId: map['reportedId'] ?? '',
    type: map['type'] ?? '',
    reason: map['reason'] ?? '',
    details: map['details'] ?? '',
    reporterId: map['reporterId'] ?? '',
    createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    resolved: map['resolved'] ?? false,
  );
}
