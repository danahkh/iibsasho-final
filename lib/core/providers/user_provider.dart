import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';
import '../services/database_service.dart';
import '../model/user.dart';
import '../utils/app_logger.dart';

class UserProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  /// Initialize user state from current auth
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    
    try {
      final authUser = SupabaseAuthService.currentUser;
      if (authUser != null) {
        await _loadUserProfile(authUser.id);
      }
    } catch (e) {
      AppLogger.e('Error initializing user provider', e);
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  /// Load user profile from database (with caching)
  Future<void> _loadUserProfile(String userId) async {
    try {
      // Check if we already have this user cached
      if (_currentUser?.id == userId) {
        return; // Already loaded
      }

      final userProfile = await DatabaseService.getUserById(userId);
      if (userProfile != null) {
        _currentUser = AppUser(
          id: userProfile['id'],
          name: userProfile['display_name'] ?? userProfile['email']?.split('@')[0] ?? 'User',
          email: userProfile['email'] ?? '',
          photoUrl: userProfile['profile_image_url'],
          role: userProfile['role'] ?? 'user',
        );
        notifyListeners();
        AppLogger.d('User profile loaded and cached: ${_currentUser!.name}');
      } else {
        // Profile doesn't exist, try to create it
        await _createMissingProfile(userId);
      }
    } catch (e) {
      AppLogger.e('Error loading user profile', e);
    }
  }

  /// Create missing user profile
  Future<void> _createMissingProfile(String userId) async {
    try {
      final authUser = SupabaseAuthService.currentUser;
      if (authUser == null) return;

  AppLogger.i('Creating missing profile for user: $userId');
      
      await SupabaseAuthService.createUserProfile(
        email: authUser.email ?? '',
        displayName: authUser.userMetadata?['display_name'] ?? 
                    authUser.email?.split('@')[0] ?? 'User',
      );

      // Reload after creation
      await _loadUserProfile(userId);
    } catch (e) {
      AppLogger.e('Error creating missing profile', e);
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return;

    _setLoading(true);
    
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;

      final result = await DatabaseService.createOrUpdateUser(updates);
      if (result != null) {
        // Update cached user
        _currentUser = AppUser(
          id: _currentUser!.id,
          name: displayName ?? _currentUser!.name,
          email: _currentUser!.email,
          photoUrl: profileImageUrl ?? _currentUser!.photoUrl,
          role: _currentUser!.role,
        );
        notifyListeners();
        AppLogger.d('User profile updated in cache');
      }
    } catch (e) {
      AppLogger.e('Error updating profile', e);
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out and clear cache
  Future<void> signOut() async {
    try {
      await SupabaseAuthService.signOut();
      _currentUser = null;
      _isInitialized = false;
      notifyListeners();
  AppLogger.i('User signed out and cache cleared');
    } catch (e) {
  AppLogger.e('Error signing out', e);
    }
  }

  /// Force refresh user data
  Future<void> refreshUser() async {
    final authUser = SupabaseAuthService.currentUser;
    if (authUser != null) {
      _setLoading(true);
      _currentUser = null; // Clear cache to force reload
      await _loadUserProfile(authUser.id);
      _setLoading(false);
    }
  }

  /// Listen to auth state changes
  void listenToAuthChanges() {
    SupabaseAuthService.authStateChanges.listen((AuthState data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        if (data.session?.user != null) {
          _loadUserProfile(data.session!.user.id);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _isInitialized = false;
        notifyListeners();
      }
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get user display name
  String get displayName => _currentUser?.name ?? 'User';
  
  /// Get user email
  String get email => _currentUser?.email ?? '';
  
  /// Get user avatar URL
  String? get avatarUrl => _currentUser?.photoUrl;
  
  /// Check if user is admin
  bool get isAdmin => _currentUser?.role == 'admin';
}
