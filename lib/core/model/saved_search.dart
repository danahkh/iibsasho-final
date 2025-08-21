import 'package:meta/meta.dart';

@immutable
class SavedSearch {
	final String id;
	final String userId;
	final String query;
	final String? category;
	final String? subcategory;
	final double? minPrice;
	final double? maxPrice;
	final double? radiusKm;
	final String sortBy;
	final bool notificationsEnabled;
	final DateTime createdAt;

	const SavedSearch({
		required this.id,
		required this.userId,
		required this.query,
		required this.category,
		required this.subcategory,
		required this.minPrice,
		required this.maxPrice,
		required this.radiusKm,
		required this.sortBy,
		required this.notificationsEnabled,
		required this.createdAt,
	});

	factory SavedSearch.fromMap(Map<String, dynamic> map) => SavedSearch(
				id: map['id'] as String,
				userId: map['user_id'] as String,
				query: map['query'] as String? ?? '',
				category: map['category'] as String?,
				subcategory: map['subcategory'] as String?,
				minPrice: (map['min_price'] as num?)?.toDouble(),
				maxPrice: (map['max_price'] as num?)?.toDouble(),
				radiusKm: (map['radius_km'] as num?)?.toDouble(),
				sortBy: map['sort_by'] as String? ?? 'relevance',
				notificationsEnabled: map['notifications_enabled'] as bool? ?? false,
				createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
			);

	Map<String, dynamic> toMap() => {
				'id': id,
				'user_id': userId,
				'query': query,
				'category': category,
				'subcategory': subcategory,
				'min_price': minPrice,
				'max_price': maxPrice,
				'radius_km': radiusKm,
				'sort_by': sortBy,
				'notifications_enabled': notificationsEnabled,
				'created_at': createdAt.toIso8601String(),
			};
}
