import 'package:flutter/material.dart';
import '../../core/model/listing.dart';
import 'create_listing_page.dart';

class ListingFormPage extends StatelessWidget {
  final Listing? listing;
  const ListingFormPage({super.key, this.listing});

  @override
  Widget build(BuildContext context) {
    return CreateListingPage(listing: listing);
  }
}
