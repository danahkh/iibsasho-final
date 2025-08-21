import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_logger.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../constant/app_color.dart';
import '../../views/screens/login_page.dart';

/// Simplified Firebase-to-Supabase utility class
/// This provides common patterns for migrating Firebase code to Supabase
class SupabaseHelper {
  static final SupabaseClient client = Supabase.instance.client;
  
  /// Get current authenticated user
  static User? get currentUser => client.auth.currentUser;
  
  /// Get current user ID
  static String? get currentUserId => client.auth.currentUser?.id;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;
  
  /// Create or update user profile in users table
  static Future<void> upsertUserProfile(Map<String, dynamic> userData) async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';
    
    userData['id'] = userId;
    userData['updated_at'] = DateTime.now().toIso8601String();
    
    await client.from('users').upsert(userData);
  }
  
  /// Insert data into a table
  static Future<List<dynamic>> insert(String table, Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    
    return await client.from(table).insert(data).select();
  }
  
  /// Update data in a table
  static Future<List<dynamic>> update(String table, Map<String, dynamic> data, String idColumn, dynamic idValue) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    
    return await client.from(table).update(data).eq(idColumn, idValue).select();
  }
  
  /// Delete data from a table
  static Future<void> delete(String table, String idColumn, dynamic idValue) async {
    await client.from(table).delete().eq(idColumn, idValue);
  }
  
  /// Get data from a table
  static Future<List<dynamic>> select(String table, {String? orderBy, bool ascending = true}) async {
    var query = client.from(table).select();
    
    if (orderBy != null) {
      return await query.order(orderBy, ascending: ascending);
    }
    
    return await query;
  }
  
  /// Get single record from a table
  static Future<dynamic> selectSingle(String table, String idColumn, dynamic idValue) async {
    return await client.from(table).select().eq(idColumn, idValue).maybeSingle();
  }
  
  /// Common user operations
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    return await selectSingle('users', 'id', userId);
  }

  /// Update user profile
  static Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    final userId = currentUserId;
    if (userId == null) return false;
    
    try {
      await client.from('users').update(profileData).eq('id', userId);
      return true;
    } catch (e) {
      AppLogger.e('Error updating user profile', e);
      return false;
    }
  }
  
  /// Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
  final profile = await getCurrentUserProfile();
  if (profile == null) return false;
  return profile['is_admin'] == true || profile['role'] == 'admin';
  }
  
  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  /// Sign out current user
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Show login required dialog/toast
  static void showLoginRequired(BuildContext context, {String? feature}) {
    final featureText = feature != null ? 'use $feature' : 'use this feature';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.login, color: AppColor.primary),
              SizedBox(width: 8),
              Text(
                'Login Required',
                style: TextStyle(
                  color: AppColor.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'You must log in to $featureText.',
            style: TextStyle(
              color: AppColor.textSecondary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColor.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: AppColor.textLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Log In'),
            ),
          ],
        );
      },
    );
  }

  /// Check if user is authenticated and show login dialog if not
  static bool requireAuth(BuildContext context, {String? feature}) {
    if (currentUser == null) {
      showLoginRequired(context, feature: feature);
      return false;
    }
    return true;
  }

  /// Simple connectivity check (DNS lookup to a reliable host)
  static Future<bool> hasConnectivity() async {
    // On web we optimistically assume connectivity (dart:io lookups not supported reliably)
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on UnsupportedError {
      // Fallback – treat as online to avoid false negatives
      return true;
    } catch (_) {
      // Be permissive to prevent blocking actions with false offline
      return true;
    }
  }

  /// Wrap a Supabase call with connectivity + friendly errors
  static Future<T?> guardNetwork<T>(BuildContext context, Future<T> Function() action, {String actionName = 'perform this action'}) async {
    final online = await hasConnectivity();
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No internet connection. Please reconnect to $actionName.')),
      );
      return null;
    }
    try {
      return await action();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Network')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network issue. Check your connection and try again.')),
        );
        return null;
      }
      rethrow;
    }
  }
}
