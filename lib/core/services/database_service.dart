// Canonical database service. Prefer importing this file only.
// Deprecated variants re-export this class to avoid mismatches.
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/support_request.dart';
import '../model/support_message.dart';
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
        // Provide both keys to satisfy differing schemas
        if (user.email != null && (user.email ?? '').isNotEmpty) {
          supportData.putIfAbsent('user_email', () => user.email);
          supportData.putIfAbsent('email', () => user.email);
        }
      }
      // Optional best-effort rate limit (if RPC exists)
      try {
        final key = (user?.id ?? supportData['user_id']?.toString() ?? 'anonymous').toString();
        final allowed = await _client.rpc('rate_limit_check', params: {
          'p_action': 'support_create',
          'p_key': key,
          'p_limit': 5,
          'p_period_seconds': 3600,
        }) as bool?;
        if (allowed == false) {
          throw Exception('Rate limit exceeded for support requests');
        }
      } catch (_) {}
      // Ensure required/non-null friendly fields exist even if backend expects them
      // Message fallback: prefer description, then reason
      final desc = (supportData['description'] as String?)?.trim();
      final rsn = (supportData['reason'] as String?)?.trim();
      final existingMessage = (supportData['message'] as String?)?.trim();
      if (existingMessage == null || existingMessage.isEmpty) {
        supportData['message'] = (desc != null && desc.isNotEmpty)
            ? desc
            : (rsn != null && rsn.isNotEmpty)
                ? rsn
                : 'Support request';
      }
      // Title fallback: prefer reason, else category, else default
      final existingTitle = (supportData['title'] as String?)?.trim();
      if (existingTitle == null || existingTitle.isEmpty) {
        final reason = rsn;
        final category = (supportData['category'] as String?)?.trim();
        supportData['title'] = (reason != null && reason.isNotEmpty)
            ? reason
            : (category != null && category.isNotEmpty)
                ? 'Support: $category'
                : 'Support Request';
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
        // If backend requires user_email (NOT NULL), add it and retry once
        if (msg.contains('user_email') || (msg.contains('23502') && msg.contains('user_email'))) {
          final u = currentUser;
          final emailFromData = (supportData['email'] ?? '') as String?;
          final fallbackEmail = u?.email ?? emailFromData ?? '';
          if (fallbackEmail.isNotEmpty) {
            supportData['user_email'] = fallbackEmail;
            try {
              final response0 = await _client
                  .from('support_requests')
                  .insert(supportData)
                  .select()
                  .single();
              return response0;
            } catch (_) {}
          }
        }
        // Handle NOT NULL title constraint by generating a fallback title and retrying once
        if (msg.contains('null value in column "title"') || (msg.contains('23502') && msg.contains('title'))) {
          final reason = rsn;
          final category = (supportData['category'] as String?)?.trim();
          supportData['title'] = (reason != null && reason.isNotEmpty)
              ? reason
              : (category != null && category.isNotEmpty)
                  ? 'Support: $category'
                  : 'Support Request';
          try {
            final responseT = await _client
                .from('support_requests')
                .insert(supportData)
                .select()
                .single();
            return responseT;
          } catch (_) {}
        }
        // Handle NOT NULL message constraint by generating a fallback and retrying once
        if (msg.contains('null value in column "message"') || (msg.contains('23502') && msg.contains('message'))) {
          final d = (supportData['description'] as String?)?.trim();
          final r = rsn;
          supportData['message'] = (d != null && d.isNotEmpty)
              ? d
              : (r != null && r.isNotEmpty)
                  ? r
                  : 'Support request';
          try {
            final responseM = await _client
                .from('support_requests')
                .insert(supportData)
                .select()
                .single();
            return responseM;
          } catch (_) {}
        }
        // Remove columns that might not exist (email, phone, description variants)
        bool didRetry = false;
        if (msg.contains("'email' column") || msg.contains('PGRST204')) {
          // Remove email keys and retry immediately
          supportData.remove('email');
          supportData.remove('user_email');
          try {
            final r0 = await _client.from('support_requests').insert(supportData).select().single();
            return r0;
          } catch (_) {}
          didRetry = true;
        }
        // Try remapping description->details if server doesn't know description
        if ((msg.contains('description') || msg.contains('details')) && supportData.containsKey('description')) {
          final value = supportData.remove('description');
          supportData['details'] = value;
          try {
            final r1 = await _client.from('support_requests').insert(supportData).select().single();
            return r1;
          } catch (_) {}
          // remove details and fall through to sanitize
          supportData.remove('details');
          didRetry = true;
        }
        // Final sanitize pass: keep only a safe whitelist of common columns and retry once
        final allowed = <String>{
          'id','user_id','user_email','category','reason','title','message','details','status','created_at','updated_at'
        };
        final sanitized = Map<String, dynamic>.from(supportData)
          ..removeWhere((k, v) => !allowed.contains(k));
        try {
          final r2 = await _client.from('support_requests').insert(sanitized).select().single();
          return r2;
        } catch (_) {}
        if (!didRetry) {
          // One more try with just the minimum required fields
          final minimal = <String, dynamic>{
            'user_id': currentUserId,
            'title': supportData['title'],
            'message': supportData['message'],
            'status': 'open',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
          try {
            final r3 = await _client.from('support_requests').insert(minimal).select().single();
            return r3;
          } catch (_) {}
        }
        rethrow;
      }
    } catch (e) {
      AppLogger.e('createSupportRequest failed', e);
      return null;
    }
  }

  /// Create support request (typed)
  static Future<SupportRequest?> createSupportRequestTyped(SupportRequest req) async {
  final map = await createSupportRequest(req.toJson());
  return map == null ? null : SupportRequest.fromJson(_normalizeSupportRequestRow(map));
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

  /// Get support requests (typed)
  static Future<List<SupportRequest>> getSupportRequestsTyped() async {
  final list = await getSupportRequests();
  return list.map((e) => SupportRequest.fromJson(_normalizeSupportRequestRow(e))).toList();
  }

  /// Update support request status
  static Future<bool> updateSupportRequestStatus(String requestId, String status) async {
    try {
      // Coerce status to match current DB constraint where necessary
      final allowed = {'open','resolved'};
      String effectiveStatus = status;
      if (!allowed.contains(status)) {
        if (status == 'closed' || status == 'done') {
          effectiveStatus = 'resolved';
        } else {
          effectiveStatus = 'open';
        }
      }
      final updates = <String, dynamic>{
        'status': effectiveStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };
      // Treat both 'resolved' and 'closed' as resolution states
      if (effectiveStatus == 'resolved') {
        updates['resolved_at'] = DateTime.now().toIso8601String();
        updates['resolved_by'] = currentUserId;
      }

    // Use select() to ensure PostgREST returns the updated row; avoids false negatives on empty response
    final res = await _client
      .from('support_requests')
      .update(updates)
      .eq('id', requestId)
      .select('id')
      .maybeSingle();
    // If RLS or constraint blocked update, result will be null
      final ok = res != null;
      if (!ok) {
        AppLogger.w('updateSupportRequestStatus returned null; likely RLS/constraint blocked for id=$requestId');
      }
      return ok;
    } catch (e) {
      AppLogger.e('updateSupportRequestStatus failed', e);
      return false;
    }
  }

  // ============================================================================
  // SUPPORT MESSAGES (threaded chat per support request)
  // ============================================================================

  static Stream<List<Map<String, dynamic>>> streamSupportMessages(String requestId) {
    return _client
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('support_request_id', requestId)
        .order('created_at', ascending: true);
  }

  /// Stream support messages (typed)
  static Stream<List<SupportMessage>> streamSupportMessagesTyped(String requestId) {
  return streamSupportMessages(requestId)
    .map((rows) => rows.map((e) => SupportMessage.fromJson(_normalizeSupportMessageRow(e))).toList());
  }

  static Future<Map<String, dynamic>?> addSupportMessage(String requestId, String text, {String? senderRole}) async {
    try {
      final user = currentUser;
      final payload = <String, dynamic>{
        'support_request_id': requestId,
        'message': text,
        'sender_id': user?.id,
        'sender_role': senderRole ?? (await isUserAdmin() ? 'admin' : 'user'),
        'created_at': DateTime.now().toIso8601String(),
      }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
      final res = await _client.from('support_messages').insert(payload).select().single();

      // If admin replied, create a user notification (best-effort)
      try {
        final role = (payload['sender_role'] as String?) ?? '';
        if (role == 'admin') {
          final sr = await _client
              .from('support_requests')
              .select('id,user_id')
              .eq('id', requestId)
              .maybeSingle();
          final targetUserId = (sr?['user_id'] as String?)?.trim();
          if (targetUserId != null && targetUserId.isNotEmpty) {
            await _client.from('notifications').insert({
              'user_id': targetUserId,
              'title': 'Support reply',
              'message': text,
              // Conform to CHECK(type IN ('comment','message','favorite'))
              'type': 'message',
              'related_type': 'support',
              'related_id': requestId,
              'metadata': {
                'support_request_id': requestId,
              },
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      } catch (_) {
        // ignore notification errors
      }
      return res;
    } catch (e) {
      AppLogger.e('addSupportMessage failed', e);
  AppLogger.w('addSupportMessage payload blocked for requestId=$requestId');
      return null;
    }
  }

  /// Add support message (typed)
  static Future<SupportMessage?> addSupportMessageTyped(String requestId, String text, {String? senderRole}) async {
    final map = await addSupportMessage(requestId, text, senderRole: senderRole);
    return map == null ? null : SupportMessage.fromJson(_normalizeSupportMessageRow(map));
  }

  // ============================================================================
  // INTERNAL HELPERS
  // ============================================================================

  /// Normalize DB row types for SupportRequest model expectations
  static Map<String, dynamic> _normalizeSupportRequestRow(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    // Coerce numeric IDs to strings expected by model
    final id = m['id'];
    if (id is int) m['id'] = id.toString();
    final userId = m['user_id'];
    if (userId is int) m['user_id'] = userId.toString();
    final resolvedBy = m['resolved_by'];
    if (resolvedBy is int) m['resolved_by'] = resolvedBy.toString();
    return m;
  }

  /// Normalize DB row types for SupportMessage model expectations
  static Map<String, dynamic> _normalizeSupportMessageRow(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    final id = m['id'];
    if (id is int) m['id'] = id.toString();
    final rid = m['support_request_id'];
    if (rid is int) m['support_request_id'] = rid.toString();
    final senderId = m['sender_id'];
    if (senderId is int) m['sender_id'] = senderId.toString();
    return m;
  }

  /// Get a single support request
  static Future<Map<String, dynamic>?> getSupportRequestById(String requestId) async {
    try {
      final r = await _client
          .from('support_requests')
          .select()
          .eq('id', requestId)
          .maybeSingle();
      return r;
    } catch (e) {
      AppLogger.e('getSupportRequestById failed', e);
      return null;
    }
  }

  /// Get support open/resolved counts via RPC `support_counts`.
  /// Expects a response like: { "open": 12, "resolved": 34 }
  static Future<Map<String, int>?> getSupportCounts() async {
    try {
      final r = await _client.rpc('support_counts');
      if (r is Map<String, dynamic>) {
        final open = (r['open'] as num?)?.toInt() ?? 0;
        final resolved = (r['resolved'] as num?)?.toInt() ?? 0;
        return {'open': open, 'resolved': resolved};
      }
      // If RPC exists but returns unexpected, fall back to client-side counts
      return await _fallbackSupportCounts();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('PGRST202') && msg.contains('support_counts')) {
        // RPC missing in DB: use fallback quietly
        // (migration adds function database/migrations/20250827_support_counts.sql)
      } else {
        AppLogger.e('getSupportCounts failed', e);
      }
      // Fallback path if RPC is missing or fails
      try {
        return await _fallbackSupportCounts();
      } catch (_) {
        return null;
      }
    }
  }

  /// Fallback counts when RPC is unavailable: uses lightweight count queries.
  static Future<Map<String, int>> _fallbackSupportCounts() async {
    Future<int> countByStatus(String status) async {
      try {
        final rows = await _client
            .from('support_requests')
            .select('id')
            .eq('status', status);
        return (rows as List).length;
      } catch (_) {
        return 0;
      }
    }

    final open = await countByStatus('open');
    final resolved = await countByStatus('resolved');
    return {'open': open, 'resolved': resolved};
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
