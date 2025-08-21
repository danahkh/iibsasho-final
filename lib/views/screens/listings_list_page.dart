import 'package:flutter/material.dart';
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
        title: Text('Listings'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _goToCreateListing(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading listings...'),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _goToCreateListing(context),
              child: Text('Create New Listing'),
            ),
          ],
        ),
      ),
    );
  }
}
