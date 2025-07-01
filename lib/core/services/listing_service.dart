import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/listing.dart';

class ListingService {
  final CollectionReference listings = FirebaseFirestore.instance.collection('listings');

  Future<void> createListing(Listing listing) async {
    await listings.add(listing.toMap());
  }

  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await listings.doc(id).update(data);
  }

  Future<void> deleteListing(String id) async {
    await listings.doc(id).delete();
  }

  Stream<List<Listing>> getListings() {
    return listings.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Listing.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList()
    );
  }

  Future<Listing?> getListingById(String id) async {
    final doc = await listings.doc(id).get();
    if (doc.exists) {
      return Listing.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<Listing>> fetchListings() async {
    final snapshot = await listings.get();
    return snapshot.docs.map((doc) => Listing.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }
}
