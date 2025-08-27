import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  static final _client = Supabase.instance.client;

  // Placeholder for future richer analytics endpoints (RPCs, materialized views, etc.)
  static Future<List<Map<String, dynamic>>> getListingViewsSeries({required DateTime from, String? category}) async {
    try {
      var q = _client
          .from('listing_views')
          .select('date,count,category')
          .gte('date', from.toIso8601String().substring(0, 10))
          .order('date');
      if (category != null && category.isNotEmpty) {
        // use filter to avoid analyzer complaining about eq on transform builder
        // ignore: deprecated_member_use
        q = q.filter('category', 'eq', category);
      }
      final rows = await q;
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return const [];
    }
  }
}
