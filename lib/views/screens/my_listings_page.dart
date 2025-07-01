import 'package:flutter/material.dart';
import '../../core/model/listing.dart';
import '../../core/services/listing_service.dart';
import '../../constant/app_color.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              height: 32,
              width: 32,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.asset('assets/icons/iibsashologo.svg', package: null),
              ),
            ),
            Text('My Listings'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: AppColor.background,
      body: currentUser == null
          ? Center(child: Text('Not logged in'))
          : StreamBuilder<List<Listing>>(
              stream: ListingService().getListings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No listings found.'));
                }
                final myListings = snapshot.data!
                    .where((l) => l.userId == currentUser.uid)
                    .toList();
                if (myListings.isEmpty) {
                  return Center(child: Text('You have no listings.'));
                }
                return ListView.builder(
                  itemCount: myListings.length,
                  itemBuilder: (context, index) {
                    final listing = myListings[index];
                    return ListTile(
                      title: Text(listing.title),
                      subtitle: Text(listing.description),
                      trailing: Text('\u20a6${listing.price}'),
                    );
                  },
                );
              },
            ),
    );
  }
}
