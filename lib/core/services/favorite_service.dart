import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/listing.dart';
import 'notification_service.dart';
import '../utils/app_logger.dart';

class FavoriteService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<bool> toggleFavorite(String listingId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        AppLogger.w('toggleFavorite: no authenticated user');
        return false;
      }
      AppLogger.d('toggleFavorite listing=$listingId user=${user.id}');

      // Check if favorite exists
      final existingFavorite = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('listing_id', listingId)
          .maybeSingle();

      if (existingFavorite != null) {
        // Remove from favorites
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('listing_id', listingId);
  AppLogger.d('Removed favorite listing=$listingId');
        return false;
      } else {
        // Add to favorites
        final favoriteData = {
          'user_id': user.id,
          'listing_id': listingId,
          'created_at': DateTime.now().toIso8601String(),
        };
        await _supabase.from('favorites').insert(favoriteData);
        
        // Send notification to listing owner
        try {
      final listingResponse = await _supabase
        .from('listings')
        .select('title, user_id')
              .eq('id', listingId)
              .maybeSingle();
              
          Map<String, dynamic>? userResponse;
          try {
            userResponse = await _supabase
                .from('users')
                .select('display_name, full_name, username, email')
                .eq('id', user.id)
                .maybeSingle();
          } catch (e) {
            // Retry with a minimal set if some columns don't exist
            try {
              userResponse = await _supabase
                  .from('users')
                  .select('display_name, username, email')
                  .eq('id', user.id)
                  .maybeSingle();
            } catch (_) {}
          }
          
          String likerName = (userResponse?['username'] ?? userResponse?['display_name'] ?? userResponse?['full_name'] ?? '').toString();
          if (likerName.isEmpty) {
            final email = (userResponse?['email'] ?? user.email ?? '').toString();
            if (email.isNotEmpty) likerName = email.split('@').first;
          }
          if (likerName.isEmpty) likerName = 'Someone';
      final listingTitle = listingResponse?['title'] ?? 'your listing';
      final ownerId = listingResponse?['user_id'];
          
  if (ownerId != user.id && ownerId != null) { // Don't notify yourself
    final ok = await NotificationService.sendFavoriteNotification(
        listingOwnerId: ownerId,
              favoriterName: likerName,
              listingTitle: listingTitle,
              listingId: listingId,
            );
    AppLogger.d('Favorite notification result=$ok owner=$ownerId listing=$listingId');
          }
        } catch (e) {
          AppLogger.w('Favorite notification failed: $e');
          // Don't fail the favorite operation if notification fails
        }
        AppLogger.d('Added favorite listing=$listingId');
        return true;
      }
    } catch (e) {
      AppLogger.e('toggleFavorite failed', e);
      return false;
    }
  }

  static Future<bool> isFavorite(String listingId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final favorite = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('listing_id', listingId)
          .maybeSingle();

      return favorite != null;
    } catch (e) {
      AppLogger.e('isFavorite failed', e);
      return false;
    }
  }

  static Stream<bool> watchFavoriteStatus(String listingId) {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _supabase
        .from('favorites')
        .stream(primaryKey: ['id'])
        .map((data) => data.where((item) => 
          item['user_id'] == user.id && item['listing_id'] == listingId).isNotEmpty);
  }

  static Stream<List<String>> getUserFavoriteIds() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) => data.map((item) => item['listing_id'] as String).toList());
  }

  static Future<List<Listing>> getUserFavoriteListings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        AppLogger.w('getUserFavoriteListings: no user');
        return [];
      }
      AppLogger.d('getUserFavoriteListings user=${user.id}');

      // Get favorite listing IDs
      final favoriteResponse = await _supabase
          .from('favorites')
          .select('listing_id')
          .eq('user_id', user.id);

      final listingIds = favoriteResponse
          .map((item) => item['listing_id'] as String)
          .toList();

      if (listingIds.isEmpty) {
        AppLogger.d('No favorites found for user');
        return [];
      }

      // Get listings for these IDs
      final listingResponse = await _supabase
          .from('listings')
          .select()
          .inFilter('id', listingIds);

      final listings = listingResponse
          .map((item) => Listing.fromMap(item))
          .toList();

  AppLogger.d('Found ${listings.length} favorite listings');
      return listings;
    } catch (e) {
  AppLogger.e('getUserFavoriteListings failed', e);
      return [];
    }
  }

  static Future<List<Listing>> getUserFavoriteListingsWithDetails() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        AppLogger.w('getUserFavoriteListingsWithDetails: no user');
        return [];
      }
      AppLogger.d('getUserFavoriteListingsWithDetails user=${user.id}');

      // Join favorites with listings to get complete data
      final response = await _supabase
          .from('favorites')
          .select('''
            *,
            listings:listing_id (*)
          ''')
          .eq('user_id', user.id);

      final listings = response
          .where((item) => item['listings'] != null)
          .map((item) {
            final listingData = item['listings'] as Map<String, dynamic>;
            return Listing.fromMap(listingData);
          })
          .toList();

  AppLogger.d('Found ${listings.length} favorites with details');
      return listings;
    } catch (e) {
  AppLogger.e('getUserFavoriteListingsWithDetails failed', e);
      return [];
    }
  }

  static Future<int> getFavoriteCount(String listingId) async {
    try {
      final response = await _supabase
          .from('favorites')
          .select('id')
          .eq('listing_id', listingId);

      return response.length;
    } catch (e) {
      AppLogger.e('getFavoriteCount failed', e);
      return 0;
    }
  }

  static Future<bool> removeFavorite(String userId, String listingId) async {
    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('listing_id', listingId);

  AppLogger.d('removeFavorite listing=$listingId');
      return true;
    } catch (e) {
  AppLogger.e('removeFavorite failed', e);
      return false;
    }
  }

  static Future<void> addFavorite(String listingId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final favoriteData = {
        'user_id': user.id,
        'listing_id': listingId,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('favorites').insert(favoriteData);
  AppLogger.d('addFavorite listing=$listingId');
    } catch (e) {
  AppLogger.e('addFavorite failed', e);
    }
  }

  static Future<bool> clearAllFavorites(String userId) async {
    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId);

  AppLogger.d('clearAllFavorites user=$userId');
      return true;
    } catch (e) {
  AppLogger.e('clearAllFavorites failed', e);
      return false;
    }
  }

  static Future<List<Listing>> getUserFavorites(String userId) async {
    try {
  AppLogger.d('getUserFavorites user=$userId');

      // Get favorite listing IDs
      final favoriteResponse = await _supabase
          .from('favorites')
          .select('listing_id')
          .eq('user_id', userId);

      final listingIds = favoriteResponse
          .map((item) => item['listing_id'] as String)
          .toList();

      if (listingIds.isEmpty) {
        AppLogger.d('No favorites found for user=$userId');
        return [];
      }

      // Get listings for these IDs
      final listingResponse = await _supabase
          .from('listings')
          .select()
          .inFilter('id', listingIds);

      final listings = listingResponse
          .map((item) => Listing.fromMap(item))
          .toList();

  AppLogger.d('getUserFavorites found ${listings.length} listings');
      return listings;
    } catch (e) {
  AppLogger.e('getUserFavorites failed', e);
      return [];
    }
  }
}
