import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/listing.dart';
import '../utils/app_logger.dart';

class ListingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  // Simple in-memory rate limiting: userId -> list of timestamps (seconds)
  static final Map<String, List<DateTime>> _createListingEvents = {};
  static const int _rateLimitWindowSeconds = 60; // 1 minute window
  static const int _rateLimitMaxCreates = 1; // max 1 listing per window (adjusted)

  // Basic profanity list (extend as needed). Lowercase comparisons.
  static const List<String> _bannedWords = [
    'badword1', 'badword2', 'offensiveword', // placeholders
  ];

  static bool _containsProfanity(String text) {
    final lower = text.toLowerCase();
    for (final w in _bannedWords) {
      if (w.isNotEmpty && lower.contains(w)) return true;
    }
    return false;
  }

  static bool _checkAndRecordRateLimit(String userId) {
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(seconds: _rateLimitWindowSeconds));
    final list = _createListingEvents.putIfAbsent(userId, () => []);
    // retain only events inside window
    list.removeWhere((t) => t.isBefore(windowStart));
    if (list.length >= _rateLimitMaxCreates) {
      return false; // rate limited
    }
    list.add(now);
    return true;
  }

  /// Fetch all listings with optional filtering
  static Future<List<Listing>> fetchListings({
    String? category,
    String? subcategory,
    String? searchQuery,
    String? location,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
    int offset = 0,
  bool includeDrafts = false,
  }) async {
    try {
  AppLogger.d('fetchListings params category=$category subcategory=$subcategory searchQuery=$searchQuery');
      
      // First, let's try without the join to see if we can get basic listings
      var query = _supabase
          .from('listings')
          .select('*'); // Simplified select without join for now

      // Exclude drafts unless explicitly included (if column exists)
      bool attemptedDraftFilter = false;
      if (!includeDrafts) {
        try {
          query = query.eq('is_draft', false);
          attemptedDraftFilter = true;
        } catch (e) {
          // Some clients may throw synchronously if filter invalid
          AppLogger.w('Draft filter application error (likely column missing): $e');
        }
      }
      // Apply filters
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (subcategory != null && subcategory.isNotEmpty) {
        query = query.eq('subcategory', subcategory);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      if (location != null && location.isNotEmpty) {
        query = query.ilike('location', '%$location%');
      }

      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }

      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      List<dynamic> response;
      try {
        // Always order by created_at descending and apply pagination
        response = await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
      } catch (e) {
        final msg = e.toString();
        if (attemptedDraftFilter && msg.contains('is_draft')) {
          AppLogger.w('Retrying fetchListings without is_draft filter (column missing)');
          final retryQuery = _supabase
              .from('listings')
              .select('*')
              .order('created_at', ascending: false)
              .range(offset, offset + limit - 1);
          response = await retryQuery;
        } else {
          rethrow;
        }
      }

  AppLogger.d('fetchListings supabase returned ${response.length} rows');

      // Debug: Let's see what categories and subcategories exist in the database
      if (response.isEmpty && category != null) {
  AppLogger.i('No listings found for category=$category subcategory=$subcategory; invoking debugCategoriesInDatabase');
        await debugCategoriesInDatabase();
      }

      final listings = response.map((json) {
        try {
          return Listing.fromMap(json);
        } catch (e) {
          AppLogger.w('Listing parse error: $e json=$json');
          // Return a basic listing to avoid breaking the list
          return Listing.fromMap({
            'id': json['id'] ?? 'unknown',
            'title': json['title'] ?? 'Untitled',
            'description': json['description'] ?? '',
            'price': (json['price'] ?? 0).toDouble(),
            'category': json['category'] ?? 'other',
            'subcategory': json['subcategory'] ?? 'miscellaneous',
            'location': json['location'] ?? '',
            'latitude': (json['latitude'] ?? 0).toDouble(),
            'longitude': (json['longitude'] ?? 0).toDouble(),
            'images': json['images'] ?? [],
            'user_id': json['user_id'] ?? '',
            'created_at': json['created_at'] ?? DateTime.now().toIso8601String(),
            'updated_at': json['updated_at'] ?? DateTime.now().toIso8601String(),
            'is_active': json['is_active'] ?? true,
            'view_count': json['view_count'] ?? 0,
            'is_featured': json['is_featured'] ?? false,
            'is_promoted': json['is_promoted'] ?? false,
          });
        }
      }).toList();

  AppLogger.d('Successfully parsed ${listings.length} listings');
      return listings;

    } catch (e) {
  AppLogger.e('Error fetching listings', e);
      return [];
    }
  }

  /// Debug method to see what categories exist in the database
  static Future<void> debugCategoriesInDatabase() async {
    try {
      final response = await _supabase.from('listings').select('category, subcategory, title');
      if (response.isEmpty) return; // nothing to log
      // Only log in debug mode
      // ignore: dead_code
      if (true) {
        AppLogger.d('DATABASE CATEGORIES DEBUG (${response.length} rows)');
      }
      
      // Collect unique categories and subcategories
      Set<String> uniqueCategories = {};
      Set<String> uniqueSubcategories = {};
      
      for (var item in response) {
        String category = item['category'] ?? 'null';
        String subcategory = item['subcategory'] ?? 'null';
        String title = item['title'] ?? 'untitled';
        
        uniqueCategories.add(category);
        uniqueSubcategories.add(subcategory);
        
  AppLogger.d('Title: $title | Category: $category | Subcategory: $subcategory');
      }
      
  AppLogger.d('UNIQUE CATEGORIES: ${uniqueCategories.join(', ')}');
  AppLogger.d('UNIQUE SUBCATEGORIES: ${uniqueSubcategories.join(', ')}');
    } catch (e) {
  AppLogger.e('Error debugging categories', e);
    }
  }

  /// Alternative method to fetch listings with user info using separate queries
  static Future<List<Listing>> fetchListingsWithUserInfo({
    String? category,
    String? subcategory,
    String? searchQuery,
    String? location,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // First get listings
      final listings = await fetchListings(
        category: category,
        subcategory: subcategory,
        searchQuery: searchQuery,
        location: location,
        minPrice: minPrice,
        maxPrice: maxPrice,
        limit: limit,
        offset: offset,
      );

      // Then get user info for each listing if needed
      // This would require separate queries but avoids the foreign key issue
      return listings;
    } catch (e) {
  AppLogger.e('Error fetchListingsWithUserInfo', e);
      return [];
    }
  }

  /// Test method to check if we can fetch any listings at all
  static Future<void> testConnection() async {
    try {
  AppLogger.d('Testing database connection');
      final response = await _supabase
          .from('listings')
          .select('id, title, created_at')
          .limit(1);
      
  AppLogger.d('Test query successful; found ${response.length} listings');
      if (response.isNotEmpty) {
  AppLogger.d('Sample listing: ${response.first}');
      }
    } catch (e) {
  AppLogger.e('Test connection failed', e);
    }
  }

  /// Create a new listing
  static Future<String?> createListing(Listing listing) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Rate limit check
      if (!_checkAndRecordRateLimit(user.id)) {
        throw Exception('Rate limit exceeded. Please wait a moment before creating more listings.');
      }

      // Profanity check (title + description)
      if (_containsProfanity('${listing.title} ${listing.description}')) {
        throw Exception('Listing rejected due to prohibited language.');
      }

      final listingData = listing.toMap();
      listingData['user_id'] = user.id;
      listingData['created_at'] = DateTime.now().toIso8601String();
      listingData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('listings')
          .insert(listingData)
          .select()
          .single();

  AppLogger.i('Listing created id=${response['id']}');
      return response['id'] as String;

    } catch (e) {
  AppLogger.e('Error creating listing', e);
      return null;
    }
  }

  /// Get listings for a specific user
  static Future<List<Listing>> getUserListings(String userId) async {
    try {
      try {
        final response = await _supabase
            .from('listings')
            .select('''
              *,
              users!listings_user_id_fkey(
                id,
                name,
                email,
                photo_url
              )
            ''')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        return response.map((json) => Listing.fromMap(json)).toList();
      } catch (e) {
        // Fallback without join
        final response = await _supabase
            .from('listings')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        return response.map((json) => Listing.fromMap(json)).toList();
      }

    } catch (e) {
  AppLogger.e('Error fetching user listings', e);
      return [];
    }
  }

  /// Get a single listing by ID
  static Future<Listing?> getListingById(String id) async {
    try {
      // Try with join first (may fail if FK alias differs in this DB)
      try {
        final response = await _supabase
            .from('listings')
            .select('''
              *,
              users!listings_user_id_fkey(
                id,
                name,
                email,
                photo_url
              )
            ''')
            .eq('id', id)
            .single();
        return Listing.fromMap(response);
      } catch (_) {
        // Fallback: fetch without join
        final response = await _supabase
            .from('listings')
            .select('*')
            .eq('id', id)
            .single();
        return Listing.fromMap(response);
      }

    } catch (e) {
  AppLogger.e('Error fetching listing', e);
      return null;
    }
  }

  /// Update a listing
  static Future<bool> updateListing(String listingId, Listing listing) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final listingData = listing.toMap();
      listingData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('listings')
          .update(listingData)
          .eq('id', listingId)
          .eq('user_id', user.id); // Ensure user can only update their own listings

      return true;

    } catch (e) {
  AppLogger.e('Error updating listing', e);
      return false;
    }
  }

  /// Delete a listing
  static Future<bool> deleteListing(String id) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('listings')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id); // Ensure user can only delete their own listings

      return true;

    } catch (e) {
  AppLogger.e('Error deleting listing', e);
      return false;
    }
  }

  /// Search listings with advanced filtering
  static Future<List<Listing>> searchListings({
    required String query,
    String? category,
    String? subcategory,
    String? location,
    double? minPrice,
    double? maxPrice,
    double? userLat,
    double? userLng,
    double? maxDistanceKm,
    String sortBy = 'relevance',
    bool ascending = false,
  }) async {
    try {
      // Use advancedSearch (DB function) first
      final advanced = await advancedSearch(
        query: query,
        category: category,
        subcategory: subcategory,
        minPrice: minPrice,
        maxPrice: maxPrice,
        userLat: userLat,
        userLng: userLng,
        maxDistanceKm: maxDistanceKm,
        sortBy: sortBy,
        limit: 40,
        offset: 0,
      );
      // Extra client-side relevance guard: ensure each listing contains the term in title/description/category
      final term = query.trim().toLowerCase();
      if (term.isNotEmpty) {
        return advanced.where((l) {
          final t = l.title.toLowerCase();
            final d = l.description.toLowerCase();
            final c = l.category.toLowerCase();
            final sc = l.subcategory.toLowerCase();
            return t.contains(term) || d.contains(term) || c.contains(term) || sc.contains(term);
        }).toList();
      }
      return advanced;
    } catch (e) {
  AppLogger.w('advancedSearch primary RPC failed; fallback basic. Error=$e');
      final basic = await fetchListings(
        searchQuery: query,
        category: category,
        subcategory: subcategory,
        location: location,
        minPrice: minPrice,
        maxPrice: maxPrice,
        includeDrafts: false,
      );
      final term = query.trim().toLowerCase();
      if (term.isEmpty) return basic;
      return basic.where((l) {
        final t = l.title.toLowerCase();
        final d = l.description.toLowerCase();
        final c = l.category.toLowerCase();
        final sc = l.subcategory.toLowerCase();
        return t.contains(term) || d.contains(term) || c.contains(term) || sc.contains(term);
      }).toList();
    }
  }

  static Future<List<Listing>> advancedSearch({
    required String query,
    String? category,
    String? subcategory,
    double? minPrice,
    double? maxPrice,
    double? userLat,
    double? userLng,
    double? maxDistanceKm,
    String sortBy = 'relevance',
    int limit = 20,
    int offset = 0,
  }) async {
    final params = {
      'p_query': query.isEmpty ? null : query,
      'p_category': category,
      'p_subcategory': subcategory,
      'p_min_price': minPrice,
      'p_max_price': maxPrice,
      'p_user_lat': userLat,
      'p_user_lng': userLng,
      'p_max_distance_km': maxDistanceKm,
      'p_sort': sortBy,
      'p_limit': limit,
      'p_offset': offset,
    }..removeWhere((key, value) => value == null);
    final resp = await _supabase.rpc('search_listings', params: params);
  // Potential: server returns distance_km field (not mapped in model). If needed, enrich Listing temporarily.
    return (resp as List<dynamic>).map((e) => Listing.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// Recommendation engine call (server-side scoring)
  static Future<List<Listing>> recommendListings(String userId, {int limit = 30}) async {
    try {
      final resp = await _supabase.rpc('recommend_listings', params: {
        'p_user': userId,
        'p_limit': limit,
      });
      if (resp is List) {
        return resp.map((e) => Listing.fromMap(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
  AppLogger.e('recommendListings error', e);
      return [];
    }
  }

  /// Get real-time stream of listings
  static Stream<List<Listing>> getListings() {
    return _supabase
        .from('listings')
        .stream(primaryKey: ['id'])
        .eq('is_draft', false)
        .map((data) => data.map((json) {
              try {
                return Listing.fromMap(json);
              } catch (e) {
                AppLogger.w('Stream listing parse error: $e');
                return null;
              }
            }).whereType<Listing>().toList());
  }

  /// Get listings for current user including drafts (real-time)
  static Stream<List<Listing>> getMyListingsIncludingDrafts(String userId) {
    return _supabase
        .from('listings')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((json) {
              try {
                return Listing.fromMap(json);
              } catch (e) {
                AppLogger.w('User stream listing parse error: $e');
                return null;
              }
            }).whereType<Listing>().toList());
  }

  /// Fetch lightweight suggestions (titles + categories) for autocomplete
  static Future<Map<String, List<String>>> fetchSuggestions(String term, {int limit = 8}) async {
    if (term.trim().isEmpty) return {'titles': [], 'categories': []};
    try {
      final pattern = '%${term.replaceAll('%', '')}%';
      final titleResp = await _supabase
          .from('listings')
          .select('title')
          .ilike('title', pattern)
          .order('view_count', ascending: false)
          .limit(limit);
      final categoryResp = await _supabase
          .from('listings')
          .select('category')
          .ilike('category', pattern)
          .limit(limit);
      final titles = <String>{};
      for (final row in titleResp) {
        final t = row['title']?.toString().trim();
        if (t != null && t.isNotEmpty) titles.add(t);
      }
      final categories = <String>{};
      for (final row in categoryResp) {
        final c = row['category']?.toString().trim();
        if (c != null && c.isNotEmpty) categories.add(c);
      }
      return {
        'titles': titles.take(limit).toList(),
        'categories': categories.take(limit).toList(),
      };
    } catch (e) {
  AppLogger.e('fetchSuggestions error', e);
      return {'titles': [], 'categories': []};
    }
  }
}
