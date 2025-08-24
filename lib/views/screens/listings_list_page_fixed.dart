import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iibsasho/core/model/listing.dart';
import 'package:iibsasho/core/services/listing_service.dart';
import 'package:iibsasho/views/screens/listing_form_page.dart';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';

class ListingsListPage extends StatefulWidget {
  const ListingsListPage({super.key});

  @override
  State<ListingsListPage> createState() => _ListingsListPageState();
}

class _ListingsListPageState extends State<ListingsListPage> {
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
              'assets/icons/iibsasho Logo.svg',
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
      body: SafeArea(
        child: StreamBuilder<List<Listing>>(
          stream: ListingService.getListings(),
          builder: (context, snapshot) {
            // Handle connection states properly
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColor.primary),
                    SizedBox(height: 16),
                    Text('Loading listings...', style: TextStyle(color: AppColor.textDark)),
                  ],
                ),
              );
            }

            // Handle errors
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColor.border),
                    SizedBox(height: 16),
                    Text(
                      'Unable to load listings',
                      style: TextStyle(color: AppColor.textDark, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again',
                      style: TextStyle(color: AppColor.placeholder),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Force rebuild to retry
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
                      child: Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            // Handle empty or null data
            if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: AppColor.border),
                    SizedBox(height: 16),
                    Text(
                      'No listings found',
                      style: TextStyle(color: AppColor.textDark, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Be the first to create a listing!',
                      style: TextStyle(color: AppColor.placeholder),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _goToCreateListing(context),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
                      child: Text('Create Listing', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            final listings = snapshot.data!;
            
            // Ensure we have valid data before building ListView
            return LayoutBuilder(
              builder: (context, constraints) {
                // Ensure the container has proper constraints
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: ListView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      // Ensure index is valid
                      if (index >= listings.length) return SizedBox.shrink();
                      
                      final listing = listings[index];

                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // Ensure context is still mounted before navigation
                              if (mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ListingFormPage(listing: listing),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Image container with fixed size
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: AppColor.primarySoft,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: listing.images.isNotEmpty
                                          ? Image.network(
                                              listing.images.first,
                                              fit: BoxFit.cover,
                                              width: 60,
                                              height: 60,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: AppColor.primarySoft,
                                                  child: Icon(Icons.image, color: AppColor.border, size: 24),
                                                );
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: AppColor.primarySoft,
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      color: AppColor.primary,
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Icon(Icons.image, color: AppColor.border, size: 24),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  // Content with proper constraints
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          listing.title,
                                          style: TextStyle(
                                            color: AppColor.textBlack,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          listing.description,
                                          style: TextStyle(
                                            color: AppColor.textDark.withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '\$${listing.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: AppColor.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColor.primarySoft,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                listing.category,
                                                style: TextStyle(
                                                  color: AppColor.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
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
