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
          
          // Work on a local copy so we can sort by promotion priority
          final listings = List<Listing>.from(snapshot.data!);
          listings.sort((a, b) {
            int p = (b.isPromoted ? 1 : 0) - (a.isPromoted ? 1 : 0);
            if (p != 0) return p;
            int f = (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0);
            if (f != 0) return f;
            return b.createdAt.compareTo(a.createdAt);
          });

          Widget buildBadge(String text, Color bg, Color fg) => Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
              );

          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              final promoted = listing.isPromoted;
              final featured = listing.isFeatured && !promoted; // hide featured badge if also promoted
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: promoted
                    ? BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade400, width: 1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.shade100.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      )
                    : BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: promoted ? Colors.orange.shade800 : Colors.black87,
                          ),
                        ),
                      ),
                      if (promoted) buildBadge('PROMOTED', Colors.amber.shade400, Colors.black87),
                      if (featured) buildBadge('FEATURED', Colors.blue.shade600, Colors.white),
                    ],
                  ),
                  subtitle: Text(
                    listing.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text('\$${listing.price}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: promoted ? Colors.orange.shade800 : Colors.blue.shade700,
                      )),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ListingFormPage(listing: listing),
                      ),
                    );
                  },
                ),
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
