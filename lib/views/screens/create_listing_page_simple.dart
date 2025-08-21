import 'package:flutter/material.dart';
import '../../core/model/listing.dart';

class CreateListingPageSimple extends StatefulWidget {
  final Listing? listing;
  
  const CreateListingPageSimple({super.key, this.listing});

  @override
  State<CreateListingPageSimple> createState() => _CreateListingPageSimpleState();
}

class _CreateListingPageSimpleState extends State<CreateListingPageSimple> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing'),
      ),
      body: const Center(
        child: Text('Create Listing Page - Simple Version'),
      ),
    );
  }
}
