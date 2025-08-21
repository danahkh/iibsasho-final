import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/user.dart';
import '../utils/app_logger.dart';

class AdminAccessService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response == null) return false;

      return response['role'] == 'admin';
    } catch (e) {
      AppLogger.e('Error checking admin status', e);
      return false;
    }
  }

  /// Get current user role
  static Future<String> getCurrentUserRole() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 'guest';

      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response == null) return 'user';

      return response['role'] ?? 'user';
    } catch (e) {
      AppLogger.e('Error getting user role', e);
      return 'user';
    }
  }

  /// Promote user to admin (only by existing admin)
  static Future<bool> promoteUserToAdmin(String userId) async {
    try {
      // Check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Only admins can promote users');
      }

      await _supabase.from('users').update({
        'role': 'admin',
        'promoted_at': DateTime.now().toIso8601String(),
        'promoted_by': _supabase.auth.currentUser?.id,
      }).eq('id', userId);

      return true;
    } catch (e) {
      AppLogger.e('Error promoting user to admin', e);
      return false;
    }
  }

  /// Demote admin to user (only by existing admin)
  static Future<bool> demoteAdminToUser(String userId) async {
    try {
      // Check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Only admins can demote users');
      }

      // Prevent self-demotion
      if (userId == _supabase.auth.currentUser?.id) {
        throw Exception('Cannot demote yourself');
      }

      await _supabase.from('users').update({
        'role': 'user',
        'demoted_at': DateTime.now().toIso8601String(),
        'demoted_by': _supabase.auth.currentUser?.id,
      }).eq('id', userId);

      return true;
    } catch (e) {
      AppLogger.e('Error demoting admin to user', e);
      return false;
    }
  }

  /// Get all admin users
  static Future<List<AppUser>> getAllAdmins() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'admin');

      return response
          .map((userData) => AppUser.fromMap(userData, userData['id']))
          .toList();
    } catch (e) {
      AppLogger.e('Error getting admin users', e);
      return [];
    }
  }

  /// Get all users with their roles
  static Future<List<AppUser>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return response
          .map((userData) => AppUser.fromMap(userData, userData['id']))
          .toList();
    } catch (e) {
      AppLogger.e('Error getting all users', e);
      return [];
    }
  }

  /// Check admin permissions for specific actions
  static Future<bool> hasAdminPermission(String action) async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) return false;

    // Define admin permissions
    const adminPermissions = [
      'delete_listing',
      'ban_user',
      'view_reports',
      'manage_users',
      'access_analytics',
      'moderate_content',
    ];

    return adminPermissions.contains(action);
  }

  /// Log admin action for audit trail
  static Future<void> logAdminAction({
    required String action,
    required String targetId,
    String? details,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      await _supabase.from('admin_actions').insert({
        'admin_id': currentUser.id,
        'admin_email': currentUser.email,
        'action': action,
        'target_id': targetId,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.e('Error logging admin action', e);
    }
  }
}
