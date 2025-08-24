import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;

  // Expose client for internal service use
  static SupabaseClient get client => _client;

  // Get current Supabase user
  static User? get currentUser => _client.auth.currentUser;

  // Get current user ID
  static String? get currentUserId => _client.auth.currentUser?.id;

  // ============================================================================
  // USERS
  // ============================================================================

  /// Get user by Supabase ID
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      AppLogger.e('getUserById failed', e);
      return null;
    }
  }

  /// Get current user profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    
    return await getUserById(user.id);
  }

  /// Create or update user profile in Supabase
  static Future<Map<String, dynamic>?> createOrUpdateUser(Map<String, dynamic> userData) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Check if user exists
      final existingUser = await getUserById(user.id);
      
      if (existingUser != null) {
        // Update existing user
        userData['updated_at'] = DateTime.now().toIso8601String();
        final response = await _client
            .from('users')
            .update(userData)
            .eq('id', user.id)
            .select()
            .single();
        return response;
      } else {
        // Create new user
        userData['id'] = user.id;
        userData['created_at'] = DateTime.now().toIso8601String();
        userData['updated_at'] = DateTime.now().toIso8601String();
        
        final response = await _client
            .from('users')
            .insert(userData)
            .select()
            .single();
        return response;
      }
    } catch (e) {
      AppLogger.e('createOrUpdateUser failed', e);
      return null;
    }
  }

  /// Check if user is admin
  static Future<bool> isUserAdmin([String? userId]) async {
    try {
      final targetUserId = userId ?? currentUserId;
      if (targetUserId == null) return false;

      final user = await getUserById(targetUserId);
      return user?['is_admin'] == true || user?['role'] == 'admin';
    } catch (e) {
      AppLogger.e('isUserAdmin failed', e);
      return false;
    }
  }

  // ============================================================================
  // LISTINGS
  // ============================================================================

  /// Get all active listings
  static Future<List<Map<String, dynamic>>> getActiveListings() async {
    try {
      final response = await _client
          .from('listings')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('getActiveListings failed', e);
      return [];
    }
  }

  /// Get listings by user
  static Future<List<Map<String, dynamic>>> getUserListings([String? userId]) async {
    try {
      final targetUserId = userId ?? currentUserId;
      if (targetUserId == null) return [];

      final response = await _client
          .from('listings')
          .select()
          .eq('seller_id', targetUserId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('getUserListings failed', e);
      return [];
    }
  }

  /// Create a new listing
  static Future<Map<String, dynamic>?> createListing(Map<String, dynamic> listingData) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No authenticated user');

      listingData['seller_id'] = user.id;
      listingData['created_at'] = DateTime.now().toIso8601String();
      listingData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('listings')
          .insert(listingData)
          .select()
          .single();
      return response;
    } catch (e) {
      AppLogger.e('createListing failed', e);
      return null;
    }
  }

  /// Update listing
  static Future<Map<String, dynamic>?> updateListing(String listingId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('listings')
          .update(updates)
          .eq('id', listingId)
          .select()
          .single();
      return response;
    } catch (e) {
      AppLogger.e('updateListing failed', e);
      return null;
    }
  }

  /// Delete listing
  static Future<bool> deleteListing(String listingId) async {
    try {
      await _client
          .from('listings')
          .delete()
          .eq('id', listingId);
      return true;
    } catch (e) {
      AppLogger.e('deleteListing failed', e);
      return false;
    }
  }

  // ============================================================================
  // FAVORITES
  // ============================================================================

  /// Get user's favorites
  static Future<List<Map<String, dynamic>>> getUserFavorites([String? userId]) async {
    try {
      final targetUserId = userId ?? currentUserId;
      if (targetUserId == null) return [];

      final response = await _client
          .from('favorites')
          .select('''
            id,
            created_at,
            listing_id,
            listings!inner(*)
          ''')
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('getUserFavorites failed', e);
      return [];
    }
  }

  /// Add to favorites
  static Future<bool> addToFavorites(String listingId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      await _client
          .from('favorites')
          .insert({
            'user_id': user.id,
            'listing_id': listingId,
            'created_at': DateTime.now().toIso8601String(),
          });
      return true;
    } catch (e) {
      AppLogger.e('addToFavorites failed', e);
      return false;
    }
  }

  /// Remove from favorites
  static Future<bool> removeFromFavorites(String listingId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      await _client
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('listing_id', listingId);
      return true;
    } catch (e) {
      AppLogger.e('removeFromFavorites failed', e);
      return false;
    }
  }

  // ============================================================================
  // SUPPORT REQUESTS
  // ============================================================================

  /// Create support request
  static Future<Map<String, dynamic>?> createSupportRequest(Map<String, dynamic> supportData) async {
    try {
      final user = currentUser;
      if (user != null) {
        supportData['user_id'] = user.id;
      }
      supportData['created_at'] = DateTime.now().toIso8601String();
      supportData['updated_at'] = DateTime.now().toIso8601String();
      try {
        final response = await _client
            .from('support_requests')
            .insert(supportData)
            .select()
            .single();
        return response;
      } catch (e) {
        final msg = e.toString();
        // Remove columns that might not exist (email, phone, description variants)
        if (msg.contains("'email' column") || msg.contains('email') || msg.contains('PGRST204')) {
          supportData.remove('email');
        }
        if (msg.contains("'phone' column") || msg.contains('phone')) {
          supportData.remove('phone');
        }
        if (msg.contains("description") && supportData.containsKey('description')) {
          // Remove or rename description if column doesn't exist
            final value = supportData.remove('description');
            // Try common alternative key
            supportData['details'] = value;
            try {
              final response2 = await _client
                  .from('support_requests')
                  .insert(supportData)
                  .select()
                  .single();
              return response2;
            } catch (e2) {
              // Final fallback: remove the alt key too
              supportData.remove('details');
              try {
                final response3 = await _client
                    .from('support_requests')
                    .insert(supportData)
                    .select()
                    .single();
                return response3;
              } catch (_) {}
            }
        } else {
          // Generic fallback: strip unknown keys based on error text and retry once
          final unknownCols = <String>[];
          for (final k in List<String>.from(supportData.keys)) {
            if (msg.contains("'$k' column")) unknownCols.add(k);
          }
          for (final k in unknownCols) {
            supportData.remove(k);
          }
          if (unknownCols.isNotEmpty) {
            try {
              final response4 = await _client
                  .from('support_requests')
                  .insert(supportData)
                  .select()
                  .single();
              return response4;
            } catch (_) {}
          }
        }
        rethrow;
      }
    } catch (e) {
      AppLogger.e('createSupportRequest failed', e);
      return null;
    }
  }

  /// Get support requests
  static Future<List<Map<String, dynamic>>> getSupportRequests() async {
    try {
      final response = await _client
          .from('support_requests')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('getSupportRequests failed', e);
      return [];
    }
  }

  /// Update support request status
  static Future<bool> updateSupportRequestStatus(String requestId, String status) async {
    try {
      await _client
          .from('support_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
      return true;
    } catch (e) {
      AppLogger.e('updateSupportRequestStatus failed', e);
      return false;
    }
  }

  // ============================================================================
  // PROMOTION REQUESTS
  // ============================================================================

  /// Create promotion request
  static Future<Map<String, dynamic>?> createPromotionRequest(Map<String, dynamic> promotionData) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No authenticated user');

      promotionData['user_id'] = user.id;
      promotionData['created_at'] = DateTime.now().toIso8601String();
      promotionData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('promotion_requests')
          .insert(promotionData)
          .select()
          .single();
      return response;
    } catch (e) {
      AppLogger.e('createPromotionRequest failed', e);
      return null;
    }
  }

  /// Get promotion requests
  static Future<List<Map<String, dynamic>>> getPromotionRequests() async {
    try {
      final response = await _client
          .from('promotion_requests')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('getPromotionRequests failed', e);
      return [];
    }
  }

  // ============================================================================
  // NOTIFICATIONS
  // ============================================================================

  /// Create notification
  static Future<Map<String, dynamic>?> createNotification(Map<String, dynamic> notificationData) async {
    try {
      notificationData['created_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('notifications')
          .insert(notificationData)
          .select()
          .single();
      return response;
    } catch (e) {
      AppLogger.e('createNotification failed', e);
      return null;
    }
  }

  /// Get user notifications
  static Future<List<Map<String, dynamic>>> getUserNotifications([String? userId]) async {
    try {
      final targetUserId = userId ?? currentUserId;
      if (targetUserId == null) return [];

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('getUserNotifications failed', e);
      return [];
    }
  }

  // ============================================================================
  // ADDITIONAL MISSING METHODS
  // ============================================================================

  /// Get all listings
  static Future<List<Map<String, dynamic>>> getListings() async {
    try {
      AppLogger.d('DatabaseService.getListings query');
      
      final response = await _client
          .from('listings')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);
          
  AppLogger.d('getListings response type=${response.runtimeType} len=${response.length}');
      
      if (response.isNotEmpty) {
  AppLogger.d('getListings first=${response.first}');
      }
      
      final result = List<Map<String, dynamic>>.from(response);
  AppLogger.d('getListings returning ${result.length}');
      return result;
    } catch (e) {
  AppLogger.e('getListings failed', e);
      return [];
    }
  }

  /// Get listings by category
  static Future<List<Map<String, dynamic>>> getListingsByCategory(String category) async {
    try {
      AppLogger.d('getListingsByCategory category=$category');
      
      final response = await _client
          .from('listings')
          .select()
          .eq('status', 'active')
          .eq('category', category)
          .order('created_at', ascending: false);
          
  AppLogger.d('getListingsByCategory len=${response.length}');
      
      final result = List<Map<String, dynamic>>.from(response);
  AppLogger.d('getListingsByCategory returning ${result.length}');
      return result;
    } catch (e) {
  AppLogger.e('getListingsByCategory failed', e);
      return [];
    }
  }

  /// Get listings owned by current user
  static Future<List<Map<String, dynamic>>> getMyListings() async {
    try {
      final user = currentUser;
      if (user == null) return [];
      final response = await _client
          .from('listings')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('getMyListings failed', e);
      return [];
    }
  }

  /// Get listings by category and subcategory
  static Future<List<Map<String, dynamic>>> getListingsByCategoryAndSubcategory(String category, String subcategory) async {
    try {
      AppLogger.d('getListingsByCategoryAndSubcategory category=$category sub=$subcategory');
      
      final response = await _client
          .from('listings')
          .select()
          .eq('status', 'active')
          .eq('category', category)
          .eq('subcategory', subcategory)
          .order('created_at', ascending: false);
          
  AppLogger.d('getListingsByCategoryAndSubcategory len=${response.length}');
      
      final result = List<Map<String, dynamic>>.from(response);
  AppLogger.d('getListingsByCategoryAndSubcategory returning ${result.length}');
      return result;
    } catch (e) {
  AppLogger.e('getListingsByCategoryAndSubcategory failed', e);
      return [];
    }
  }

  /// Check if listing is favorited by user
  static Future<bool> isListingFavorited(String listingId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final response = await _client
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('listing_id', listingId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      AppLogger.e('isListingFavorited failed', e);
      return false;
    }
  }

  /// Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      AppLogger.e('markNotificationAsRead failed', e);
      return false;
    }
  }

  /// Get listing by ID
  static Future<Map<String, dynamic>?> getListingById(String listingId) async {
    try {
      final response = await _client
          .from('listings')
          .select()
          .eq('id', listingId)
          .maybeSingle();
      return response;
    } catch (e) {
      AppLogger.e('getListingById failed', e);
      return null;
    }
  }

  /// Search listings
  static Future<List<Map<String, dynamic>>> searchListings(String query) async {
    try {
      final response = await _client
          .from('listings')
          .select()
          .eq('status', 'active')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('searchListings failed', e);
      return [];
    }
  }

  /// Get featured listings
  static Future<List<Map<String, dynamic>>> getFeaturedListings() async {
    try {
      final response = await _client
          .from('listings')
          .select()
          .eq('status', 'active')
          .eq('is_featured', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('getFeaturedListings failed', e);
      return [];
    }
  }

  /// Get categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('getCategories failed', e);
      return [];
    }
  }
}
