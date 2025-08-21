import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_helper.dart';

class UserService {
  static final _client = Supabase.instance.client;

  /// Ensure location permission and return Position or null
  static Future<Position?> _getPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      return null;
    }
  }

  /// Collect device info (minimal fields) – platform-agnostic safe subset
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      final base = <String, dynamic>{};
      final info = await deviceInfo.deviceInfo;
      final data = info.data;
      base['device_model'] = data['model'] ?? data['name'] ?? 'unknown';
      base['device_os'] = data['operatingSystem'] ?? data['systemName'] ?? 'unknown';
      base['device_id'] = data['id']?.toString() ?? data['identifierForVendor']?.toString() ?? '';
      return base;
    } catch (_) {
      return {};
    }
  }

  /// Update user with latest location & device snapshot
  static Future<void> captureTelemetry() async {
    final uid = SupabaseHelper.currentUserId;
    if (uid == null) return;

    final pos = await _getPosition();
    final device = await _getDeviceInfo();

    final update = <String, dynamic>{
      'last_seen_at': DateTime.now().toIso8601String(),
      ...device,
    };
    if (pos != null) {
      update['last_lat'] = pos.latitude;
      update['last_lng'] = pos.longitude;
      update['last_location_accuracy'] = pos.accuracy;
    }

    try {
      await _client.from('users').update(update).eq('id', uid);
    } catch (e) {
      // swallow to avoid blocking UX
    }
  }
}
