import '../model/user_interaction.dart';

class RecommendationService {
  // Track user interactions (to be called on view, favorite, etc.)
  Future<void> trackInteraction(UserInteraction interaction) async {
    // Not yet implemented
  }

  // Get recommended listings for a user
  Future<List<String>> getRecommendedListingIds(String userId) async {
    // Not yet implemented
    return [];
  }
}
