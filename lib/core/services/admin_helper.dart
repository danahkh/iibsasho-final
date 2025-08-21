import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class AdminHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  /// This method should only be called in development to create the first admin
  /// For production, use Supabase Dashboard or RLS policies
  static Future<bool> makeUserAdmin(String email) async {
    try {
      // Find user by email
      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .limit(1);
      
      if (response.isEmpty) {
        AppLogger.w('User with email $email not found');
        return false;
      }
      
      final user = response.first;
      
      // Update user role to admin
      await _supabase.from('users').update({
        'role': 'admin',
        'promotedAt': DateTime.now().toIso8601String(),
        'promotedBy': 'system', // Since this is initial admin creation
        'updatedAt': DateTime.now().toIso8601String(),
      }).eq('id', user['id']);
      
  AppLogger.i('Successfully made $email an admin');
      return true;
    } catch (e) {
  AppLogger.e('Error making user admin', e);
      return false;
    }
  }
  
  /// Check if user is admin by email (for development purposes)
  static Future<bool> isUserAdmin(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('email', email)
          .limit(1);
      
      if (response.isEmpty) return false;
      
      final user = response.first;
      return user['role'] == 'admin';
    } catch (e) {
      AppLogger.e('Error checking admin status', e);
      return false;
    }
  }
  
  /// List all admin users
  static Future<void> listAllAdmins() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, email, name')
          .eq('role', 'admin');
      
      AppLogger.i('Admin users:');
      for (var user in response) {
        AppLogger.i('- ${user['email']} (${user['name']})');
      }
    } catch (e) {
      AppLogger.e('Error listing admins', e);
    }
  }
}

// Usage examples:
// await AdminHelper.makeUserAdmin('your-email@example.com');
// await AdminHelper.isUserAdmin('your-email@example.com');
// await AdminHelper.listAllAdmins();
