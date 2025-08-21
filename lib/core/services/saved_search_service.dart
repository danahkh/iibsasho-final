import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/saved_search.dart';

class SavedSearchService {
	static final _client = Supabase.instance.client;
	static const _table = 'saved_searches';

	static Future<SavedSearch?> create({
		required String query,
		String? category,
		String? subcategory,
		double? minPrice,
		double? maxPrice,
		double? radiusKm,
		required String sortBy,
		required bool notificationsEnabled,
	}) async {
		final user = _client.auth.currentUser;
		if (user == null) return null;

		final payload = {
			'user_id': user.id,
			'query': query,
			'category': category,
			'subcategory': subcategory,
			'min_price': minPrice,
			'max_price': maxPrice,
			'radius_km': radiusKm,
			'sort_by': sortBy,
			'notifications_enabled': notificationsEnabled,
		}..removeWhere((k, v) => v == null);

		final inserted = await _client.from(_table).insert(payload).select().maybeSingle();
		if (inserted == null) return null;
		return SavedSearch.fromMap(inserted);
	}
}
