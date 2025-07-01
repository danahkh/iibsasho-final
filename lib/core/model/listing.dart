import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  String id;
  String title;
  String description;
  List<String> images;
  List<String> videos; // Added videos field
  double price;
  GeoPoint location;
  String address;
  String condition; // 'new' or 'used'
  String userId;
  DateTime createdAt;
  bool isActive;
  String category;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.videos, // Added
    required this.price,
    required this.location,
    required this.address,
    required this.condition,
    required this.userId,
    required this.createdAt,
    required this.isActive,
    required this.category,
  });

  factory Listing.fromMap(Map<String, dynamic> map, String docId) {
    return Listing(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      videos: List<String>.from(map['videos'] ?? []), // Added
      price: (map['price'] ?? 0).toDouble(),
      location: map['location'] ?? GeoPoint(0, 0),
      address: map['address'] ?? '',
      condition: map['condition'] ?? 'used',
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'images': images,
      'videos': videos, // Added
      'price': price,
      'location': location,
      'address': address,
      'condition': condition,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'category': category,
    };
  }
}
