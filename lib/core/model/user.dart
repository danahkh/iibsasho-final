import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String role; // 'user' or 'admin'
  final double? lastLat;
  final double? lastLng;
  final String? deviceModel;
  final String? deviceOs;
  final DateTime? lastSeenAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.role = 'user',
  this.lastLat,
  this.lastLng,
  this.deviceModel,
  this.deviceOs,
  this.lastSeenAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'user',
  lastLat: (map['last_lat'] as num?)?.toDouble(),
  lastLng: (map['last_lng'] as num?)?.toDouble(),
  deviceModel: map['device_model'],
  deviceOs: map['device_os'],
  lastSeenAt: map['last_seen_at'] != null ? DateTime.tryParse(map['last_seen_at']) : null,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser.fromMap(json, json['id']?.toString() ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
  'last_lat': lastLat,
  'last_lng': lastLng,
  'device_model': deviceModel,
  'device_os': deviceOs,
  'last_seen_at': lastSeenAt?.toIso8601String(),
    };
  }

  static Future<AppUser?> fetchById(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return AppUser.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
