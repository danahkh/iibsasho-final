import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class SupabaseAuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Get current user
  static User? get currentUser => _client.auth.currentUser;

  /// Get current user ID
  static String? get currentUserId => _client.auth.currentUser?.id;

  /// Check if user is logged in
  static bool get isLoggedIn => _client.auth.currentUser != null;

  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign up with email and password
  static Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
  AppLogger.d('Attempting signup with email: $email');
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      
  AppLogger.d('Signup response: ${response.user?.id}');
      return response;
    } on AuthException catch (e) {
  AppLogger.e('AuthException during signup: ${e.message} (status: ${e.statusCode})');
      rethrow;
    } catch (e) {
  AppLogger.e('Unexpected error during signup', e);
      throw Exception('Sign up failed: $e');
    }
  }

  /// Test Supabase connection
  static Future<bool> testConnection() async {
    try {
      // Try to access the users table to test connection
      await _client
          .from('users')
          .select('id')
          .limit(1);
      
  AppLogger.d('Connection test successful');
      return true;
    } catch (e) {
  AppLogger.e('Connection test failed', e);
      return false;
    }
  }

  /// Ensure user profile exists in database
  static Future<bool> ensureUserProfileExists() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Check if profile exists
      final existingProfile = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Create profile
  AppLogger.i('Creating missing user profile for ${user.id}');
        await createUserProfile(
          email: user.email ?? '',
          displayName: user.userMetadata?['display_name'] ?? user.email?.split('@')[0],
        );
        AppLogger.i('User profile created successfully');
        return true;
      }
      
      return true;
    } catch (e) {
      AppLogger.e('Error ensuring user profile exists', e);
      return false;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Get user profile from database
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      AppLogger.e('Error getting user profile', e);
      return null;
    }
  }

  /// Create or update user profile
  static Future<void> createUserProfile({
    required String email,
    String? displayName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      final profileData = {
        'id': user.id,
        'email': email,
        'display_name': displayName,
        'phone_number': phoneNumber,
        'profile_image_url': profileImageUrl,
        'is_verified': user.emailConfirmedAt != null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Try upsert first (this should work with proper RLS)
  await _client.from('users').upsert(profileData);
  AppLogger.i('User profile created/updated successfully');
    } catch (e) {
  AppLogger.e('Failed to create/update user profile', e);
      
      // If RLS is blocking, try a different approach
      try {
        // Check if profile exists first
        final existing = await _client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
            
        if (existing == null) {
          // Try insert instead of upsert
          await _client.from('users').insert({
            'id': user.id,
            'email': email,
            'display_name': displayName,
            'phone_number': phoneNumber,
            'profile_image_url': profileImageUrl,
            'is_verified': user.emailConfirmedAt != null,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          AppLogger.i('User profile inserted successfully');
        } else {
          // Update existing
          await _client.from('users').update({
            'display_name': displayName,
            'phone_number': phoneNumber,
            'profile_image_url': profileImageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', user.id);
          AppLogger.i('User profile updated successfully');
        }
      } catch (e2) {
        AppLogger.e('Alternative profile creation also failed', e2);
        throw Exception('Failed to create user profile: $e2');
      }
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final user = currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _client.from('users').update(updates).eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}
