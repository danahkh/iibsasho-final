import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/app_logger.dart';

class SupabaseService {
  static SupabaseClient? _client;
  
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static Future<void> initialize() async {
    if (SupabaseConfig.supabaseUrl == 'YOUR_SUPABASE_URL_HERE') {
      throw Exception('Please configure your Supabase URL and anon key in SupabaseConfig');
    }
    
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    
    _client = Supabase.instance.client;
  }

  // User operations
  static Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('user_id', userId)
          .single();
      return response;
    } catch (e) {
      AppLogger.e('Error getting user', e);
      return null;
    }
  }

  static Future<bool> createOrUpdateUser(Map<String, dynamic> userData) async {
    try {
      await client
          .from(SupabaseConfig.usersTable)
          .upsert(userData);
      return true;
    } catch (e) {
      AppLogger.e('Error creating/updating user', e);
      return false;
    }
  }

  // Listings operations
  static Future<List<Map<String, dynamic>>> getListings({
    int? limit,
    String? category,
    String? searchQuery,
    String? userId,
  }) async {
    try {
      var query = client.from(SupabaseConfig.listingsTable).select();
      
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }
      
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      
      if (limit != null) {
        final response = await query.limit(limit).order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      }
      
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('Error getting listings', e);
      return [];
    }
  }

  static Future<String?> createListing(Map<String, dynamic> listingData) async {
    try {
      final response = await client
          .from(SupabaseConfig.listingsTable)
          .insert(listingData)
          .select()
          .single();
      return response['id'].toString();
    } catch (e) {
      AppLogger.e('Error creating listing', e);
      return null;
    }
  }

  static Future<bool> updateListing(String listingId, Map<String, dynamic> updates) async {
    try {
      await client
          .from(SupabaseConfig.listingsTable)
          .update(updates)
          .eq('id', listingId);
      return true;
    } catch (e) {
      AppLogger.e('Error updating listing', e);
      return false;
    }
  }

  static Future<bool> deleteListing(String listingId) async {
    try {
      await client
          .from(SupabaseConfig.listingsTable)
          .delete()
          .eq('id', listingId);
      return true;
    } catch (e) {
      AppLogger.e('Error deleting listing', e);
      return false;
    }
  }

  // Support requests operations
  static Future<List<Map<String, dynamic>>> getSupportRequests({
    String? status,
    String? userId,
  }) async {
    try {
      var query = client.from(SupabaseConfig.supportRequestsTable).select();
      
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('Error getting support requests', e);
      return [];
    }
  }

  static Future<String?> createSupportRequest(Map<String, dynamic> requestData) async {
    try {
      final response = await client
          .from(SupabaseConfig.supportRequestsTable)
          .insert(requestData)
          .select()
          .single();
      return response['id'].toString();
    } catch (e) {
      AppLogger.e('Error creating support request', e);
      return null;
    }
  }

  static Future<bool> updateSupportRequest(String requestId, Map<String, dynamic> updates) async {
    try {
      await client
          .from(SupabaseConfig.supportRequestsTable)
          .update(updates)
          .eq('id', requestId);
      return true;
    } catch (e) {
      AppLogger.e('Error updating support request', e);
      return false;
    }
  }

  // Favorites operations
  static Future<List<Map<String, dynamic>>> getUserFavorites(String userId) async {
    try {
      final response = await client
          .from(SupabaseConfig.favoritesTable)
          .select('*, listings(*)')
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('Error getting favorites', e);
      return [];
    }
  }

  static Future<bool> addToFavorites(String userId, String listingId) async {
    try {
      await client
          .from(SupabaseConfig.favoritesTable)
          .insert({
        'user_id': userId,
        'listing_id': listingId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      AppLogger.e('Error adding to favorites', e);
      return false;
    }
  }

  static Future<bool> removeFromFavorites(String userId, String listingId) async {
    try {
      await client
          .from(SupabaseConfig.favoritesTable)
          .delete()
          .eq('user_id', userId)
          .eq('listing_id', listingId);
      return true;
    } catch (e) {
      AppLogger.e('Error removing from favorites', e);
      return false;
    }
  }

  // Real-time subscriptions
  static RealtimeChannel subscribeToListings(Function(List<Map<String, dynamic>>) onData) {
    return client
        .channel('listings_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.listingsTable,
          callback: (payload) {
            // Refetch all listings when changes occur
            getListings().then(onData);
          },
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToSupportRequests(Function(List<Map<String, dynamic>>) onData) {
    return client
        .channel('support_requests_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.supportRequestsTable,
          callback: (payload) {
            // Refetch all support requests when changes occur
            getSupportRequests().then(onData);
          },
        )
        .subscribe();
  }

  // Utility methods
  static String getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id ?? '';
  }

  static Map<String, dynamic> addTimestamps(Map<String, dynamic> data, {bool isUpdate = false}) {
    final now = DateTime.now().toIso8601String();
    
    if (!isUpdate) {
      data['created_at'] = now;
    }
    data['updated_at'] = now;
    
    return data;
  }
}
