import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iibsasho/core/model/listing.dart';
import 'package:iibsasho/core/services/listing_service.dart';
import 'package:iibsasho/views/screens/listing_form_page.dart';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';

class ListingsListPage extends StatelessWidget {
  const ListingsListPage({super.key});

  void _goToCreateListing(BuildContext context) async {
    if (!SupabaseHelper.requireAuth(context, feature: 'add listing')) {
      return;
    }
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
      body: FutureBuilder<List<Listing>>(
        future: ListingService.fetchListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading listings'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => ListingsListPage()),
                      );
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No listings found.'));
          }
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final listing = snapshot.data![index];
              return ListTile(
                title: Text(listing.title),
                subtitle: Text(listing.description),
                trailing: Text('\$${listing.price}'),
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
        child: Icon(Icons.add),
      ),
    );
  }
}
