import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iibsasho/core/model/listing.dart';
import 'package:iibsasho/core/services/listing_service.dart';
import 'package:iibsasho/views/screens/listing_form_page.dart';
import '../../constant/app_color.dart';

class ListingsListPage extends StatelessWidget {
  const ListingsListPage({super.key});

  void _goToCreateListing(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ListingFormPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text('Listings', style: TextStyle(color: AppColor.textBlack)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SvgPicture.asset(
              'assets/icons/iibsashologo.svg',
              height: 32,
              width: 32,
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: AppColor.primary),
            onPressed: () => _goToCreateListing(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Listing>>(
        stream: ListingService().getListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No listings found.', style: TextStyle(color: AppColor.textDark)));
          }
          final listings = snapshot.data!;
          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return ListTile(
                title: Text(listing.title, style: TextStyle(color: AppColor.textBlack)),
                subtitle: Text(listing.description, style: TextStyle(color: AppColor.textDark.withOpacity(0.7))),
                trailing: Text('\$${listing.price}', style: TextStyle(color: AppColor.primary)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ListingFormPage(listing: listing),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToCreateListing(context),
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'Add Listing',
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
