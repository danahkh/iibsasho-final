// Firestore implementation removed. TODO: Implement Supabase RPC or table queries.
import '../model/listing.dart';

class ListingService {
  static Future<void> createListing(Listing listing) async {
    // await SupabaseHelper.client.from('listings').insert(listing.toMap());
  }
  static Future<void> updateListing(String id, Map<String, dynamic> data) async {
    // await SupabaseHelper.client.from('listings').update(data).eq('id', id);
  }
  static Future<void> deleteListing(String id) async {
    // await SupabaseHelper.client.from('listings').delete().eq('id', id);
  }
  static Stream<List<Listing>> getListings() {
    // Placeholder empty stream until implemented.
    return const Stream.empty();
  }
  static Future<Listing?> getListingById(String id) async {
    return null; // TODO
  }
  static Future<List<Listing>> fetchListings() async {
    return []; // TODO
  }
  static Future<List<Listing>> getUserListings(String userId) async { return []; }
  static Future<bool> deleteListingForce(String id) async { return false; }
  static Future<void> debugCategoriesInDatabase() async {}
}
