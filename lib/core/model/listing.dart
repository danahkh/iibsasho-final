class Listing {
  String id;
  String title;
  String description;
  List<String> images;
  List<String> videos;
  double price;
  String category;
  String subcategory;
  String location; // Location name/address
  double latitude;
  double longitude;
  String condition;
  String userId;
  String userName;
  String userEmail;
  String userPhotoUrl;
  DateTime createdAt;
  DateTime updatedAt;
  bool isActive;
  int viewCount;
  bool isFeatured;
  bool isPromoted; // Higher than featured (golden layout)
  bool isDraft; // New: saved as draft (not publicly visible)

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.videos,
    required this.price,
    required this.category,
    required this.subcategory,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.condition,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.viewCount,
  required this.isFeatured,
  required this.isPromoted,
  required this.isDraft,
  });

  // Create from Supabase database response
  factory Listing.fromMap(Map<String, dynamic> map) {
    return Listing(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      images: _parseStringList(map['images']),
      videos: _parseStringList(map['videos']),
      price: _parseDouble(map['price']),
      category: map['category']?.toString() ?? '',
      subcategory: map['subcategory']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      latitude: _parseDouble(map['latitude']),
      longitude: _parseDouble(map['longitude']),
      condition: map['condition']?.toString() ?? 'used',
      userId: map['user_id']?.toString() ?? '',
      userName: _getUserData(map, 'name'),
      userEmail: _getUserData(map, 'email'),
      userPhotoUrl: _getUserData(map, 'photo_url'),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
      isActive: _parseBool(map['is_active']),
      viewCount: _parseInt(map['view_count']),
  isFeatured: _parseBool(map['is_featured']),
  isPromoted: _parseBool(map['is_promoted']),
  isDraft: _parseBool(map['is_draft']),
    );
  }

  // Convert to map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'images': images,
      'videos': videos,
      'price': price,
      'category': category,
      'subcategory': subcategory,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'condition': condition,
      'is_active': isActive,
      'view_count': viewCount,
  'is_featured': isFeatured,
  'is_promoted': isPromoted,
  'is_draft': isDraft,
    };
  }

  // Alternative constructor for backward compatibility
  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing.fromMap(json);
  }

  // Helper methods for parsing data safely
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) {
      try {
        // Handle JSON string format
        final decoded = value.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
        return decoded.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } catch (e) {
        return [value];
      }
    }
    return [];
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static String _getUserData(Map<String, dynamic> map, String field) {
    final users = map['users'];
    if (users is Map<String, dynamic>) {
      return users[field]?.toString() ?? '';
    }
    return '';
  }

  // Convenience methods for location
  void setLocation(double lat, double lng, String locationName) {
    latitude = lat;
    longitude = lng;
    location = locationName;
  }

  // Get formatted price
  String get formattedPrice {
    if (price == 0) return 'Free';
    return '\$${price.toStringAsFixed(2)}';
  }

  // Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() != 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
