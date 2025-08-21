import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class PromotionService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch promotion requests with optional filtering
  static Future<List<Map<String, dynamic>>> fetchPromotionRequests({
    String? status,
    String? promotionType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('promotion_requests')
          .select('''
            *,
            listings!promotion_requests_listing_id_fkey(
              id,
              title,
              description,
              price,
              currency,
              images,
              category,
              subcategory
            ),
            users!promotion_requests_user_id_fkey(
              id,
              display_name,
              email
            )
          ''');

      // Apply filters
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      if (promotionType != null && promotionType != 'all') {
        query = query.eq('promotion_type', promotionType);
      }

      // Apply pagination and ordering
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('Error fetching promotion requests', e);
      return [];
    }
  }

  /// Fetch active promotions
  static Future<List<Map<String, dynamic>>> fetchActivePromotions() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from('promotion_requests')
          .select('''
            *,
            listings!promotion_requests_listing_id_fkey(
              id,
              title,
              description,
              price,
              currency,
              images,
              category,
              subcategory
            ),
            users!promotion_requests_user_id_fkey(
              id,
              display_name,
              email
            )
          ''')
          .eq('status', 'approved')
          .lte('start_date', now)
          .gte('end_date', now)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.e('Error fetching active promotions', e);
      return [];
    }
  }

  /// Approve a promotion request
  static Future<bool> approvePromotionRequest(String requestId) async {
    try {
      // Get the promotion request details
      final requestResponse = await _supabase
          .from('promotion_requests')
          .select('*, listings!promotion_requests_listing_id_fkey(*)')
          .eq('id', requestId)
          .maybeSingle();

      if (requestResponse == null) {
        AppLogger.w('Promotion request not found');
        return false;
      }

      final request = requestResponse;
      final listing = request['listings'];
      
      if (listing == null) {
        AppLogger.w('Associated listing not found');
        return false;
      }

      final now = DateTime.now();
      final startDate = now.toIso8601String();
      final endDate = now.add(Duration(days: request['duration_days'] ?? 7)).toIso8601String();

      // Update promotion request status
      await _supabase
          .from('promotion_requests')
          .update({
            'status': 'approved',
            'start_date': startDate,
            'end_date': endDate,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', requestId);

      // Update listing to mark as promoted/featured
      final listingUpdate = <String, dynamic>{
        'updated_at': now.toIso8601String(),
      };

      if (request['promotion_type'] == 'featured') {
        listingUpdate['is_featured'] = true;
      } else if (request['promotion_type'] == 'promoted') {
        listingUpdate['is_promoted'] = true;
      }

      await _supabase
          .from('listings')
          .update(listingUpdate)
          .eq('id', request['listing_id']);

  AppLogger.i('Promotion request approved successfully');
      return true;
    } catch (e) {
  AppLogger.e('Error approving promotion request', e);
      return false;
    }
  }

  /// Reject a promotion request
  static Future<bool> rejectPromotionRequest(String requestId, String reason) async {
    try {
      await _supabase
          .from('promotion_requests')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

  AppLogger.i('Promotion request rejected successfully');
      return true;
    } catch (e) {
  AppLogger.e('Error rejecting promotion request', e);
      return false;
    }
  }

  /// Create a new promotion request
  static Future<String?> createPromotionRequest({
    required String userId,
    required String listingId,
    required String promotionType,
    required int durationDays,
    required double price,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from('promotion_requests')
          .insert({
            'user_id': userId,
            'listing_id': listingId,
            'promotion_type': promotionType,
            'duration_days': durationDays,
            'price': price,
            'status': 'pending',
            'payment_status': 'pending',
            'created_at': now,
            'updated_at': now,
          })
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      AppLogger.e('Error creating promotion request', e);
      return null;
    }
  }

  /// Get promotion analytics
  static Future<Map<String, dynamic>> getPromotionAnalytics() async {
    try {
      // Get counts by status
      final statusCounts = await _supabase
          .from('promotion_requests')
          .select('status')
          .then((response) {
            final Map<String, int> counts = {
              'pending': 0,
              'approved': 0,
              'rejected': 0,
              'active': 0,
              'expired': 0,
            };
            
            for (var item in response) {
              final status = item['status'] as String? ?? 'pending';
              counts[status] = (counts[status] ?? 0) + 1;
            }
            
            return counts;
          });

      // Get revenue from approved requests
      final revenueResponse = await _supabase
          .from('promotion_requests')
          .select('price')
          .eq('status', 'approved');

      double totalRevenue = 0;
      for (var item in revenueResponse) {
        totalRevenue += (item['price'] as num?)?.toDouble() ?? 0;
      }

      // Get active promotions count
      final now = DateTime.now().toIso8601String();
      final activePromotionsResponse = await _supabase
          .from('promotion_requests')
          .select('id')
          .eq('status', 'approved')
          .lte('start_date', now)
          .gte('end_date', now);

      return {
        'statusCounts': statusCounts,
        'totalRevenue': totalRevenue,
        'activePromotions': activePromotionsResponse.length,
        'totalRequests': statusCounts.values.fold(0, (sum, count) => sum + count),
      };
    } catch (e) {
      AppLogger.e('Error getting promotion analytics', e);
      return {
        'statusCounts': <String, int>{},
        'totalRevenue': 0.0,
        'activePromotions': 0,
        'totalRequests': 0,
      };
    }
  }

  /// Stream promotion requests (for real-time updates)
  static Stream<List<Map<String, dynamic>>> streamPromotionRequests({
    String? status,
    String? promotionType,
  }) {
    try {
      var query = _supabase
          .from('promotion_requests')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false);

      return query.map((data) {
        // Apply filters
        List<Map<String, dynamic>> filtered = data;
        
        if (status != null && status != 'all') {
          filtered = filtered.where((item) => item['status'] == status).toList();
        }
        
        if (promotionType != null && promotionType != 'all') {
          filtered = filtered.where((item) => item['promotion_type'] == promotionType).toList();
        }
        
        return filtered;
      });
    } catch (e) {
      AppLogger.e('Error streaming promotion requests', e);
      return Stream.value([]);
    }
  }

  /// Cancel an active promotion
  static Future<bool> cancelPromotion(String requestId) async {
    try {
      // Get the promotion request
      final requestResponse = await _supabase
          .from('promotion_requests')
          .select('listing_id, promotion_type')
          .eq('id', requestId)
          .maybeSingle();

      if (requestResponse == null) {
        AppLogger.w('Promotion request not found');
        return false;
      }

      final listingId = requestResponse['listing_id'];
      final promotionType = requestResponse['promotion_type'];

      // Update promotion request status
      await _supabase
          .from('promotion_requests')
          .update({
            'status': 'cancelled',
            'end_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      // Update listing to remove promotion
      final listingUpdate = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (promotionType == 'featured') {
        listingUpdate['is_featured'] = false;
      } else if (promotionType == 'promoted') {
        listingUpdate['is_promoted'] = false;
      }

      await _supabase
          .from('listings')
          .update(listingUpdate)
          .eq('id', listingId);

  AppLogger.i('Promotion cancelled successfully');
      return true;
    } catch (e) {
  AppLogger.e('Error cancelling promotion', e);
      return false;
    }
  }
}
