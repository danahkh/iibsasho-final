import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import 'package:iibsasho/views/widgets/main_app_bar_widget.dart';
import 'package:iibsasho/core/model/listing.dart';
import 'package:iibsasho/core/services/listing_service.dart';
import 'package:iibsasho/views/screens/product_detail.dart';
import 'listing_form_page.dart';
import '../../core/constant_categories.dart';
import '../../core/utils/supabase_helper.dart';

class FeedsPage extends StatefulWidget {
  const FeedsPage({super.key});
  @override
  _FeedsPageState createState() => _FeedsPageState();
}

class _FeedsPageState extends State<FeedsPage> with TickerProviderStateMixin {
  List<Listing> _listings = [];
  bool _loading = false;
  CategoryItem? selectedCategory;
  String searchQuery = '';

  // Static categories for the feed page
  final List<CategoryItem> staticCategories = AppCategories.categories;

  void _sortListings(List<Listing> list) {
    list.sort((a, b) {
      int p = (b.isPromoted ? 1 : 0) - (a.isPromoted ? 1 : 0);
      if (p != 0) return p;
      int f = (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0);
      if (f != 0) return f;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> _refreshListings() async {
    setState(() => _loading = true);
    try {
      final listings = await ListingService.fetchListings();
      setState(() {
        _listings = listings;
        _sortListings(_listings);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load listings: $e'),
            backgroundColor: AppColor.error,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    selectedCategory = staticCategories.first;
    _refreshListings(); // Load listings when page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: MainAppBar(
        chatValue: 2,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search listings...',
                prefixIcon: Icon(Icons.search, color: AppColor.primary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColor.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColor.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColor.primary),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: staticCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final cat = staticCategories[index];
                final isSelected = selectedCategory?.name == cat.name;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = cat;
                      _refreshListings(); // Refresh feed when category is clicked
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColor.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColor.primary : AppColor.border),
                    ),
                    child: Row(
                      children: [
                        Icon(cat.icon, color: isSelected ? Colors.white : AppColor.primary),
                        const SizedBox(width: 8),
                        Text(
                          cat.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColor.primary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshListings,
              child: _loading
                  ? Center(child: CircularProgressIndicator())
                  : _listings
                      .where((listing) =>
                        (selectedCategory == null || listing.category == selectedCategory!.name) &&
                        (searchQuery.isEmpty || listing.title.toLowerCase().contains(searchQuery.toLowerCase()) || listing.description.toLowerCase().contains(searchQuery.toLowerCase()))
                      )
                      .isEmpty
                      ? Center(child: Text('No listings found.', style: TextStyle(color: AppColor.textDark)))
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _listings
                              .where((listing) =>
                                (selectedCategory == null || listing.category == selectedCategory!.name) &&
                                (searchQuery.isEmpty || listing.title.toLowerCase().contains(searchQuery.toLowerCase()) || listing.description.toLowerCase().contains(searchQuery.toLowerCase()))
                              )
                              .length,
                          separatorBuilder: (context, index) => Divider(),
                          itemBuilder: (context, index) {
                            final filteredListings = _listings
                                .where((listing) =>
                                  (selectedCategory == null || listing.category == selectedCategory!.name) &&
                                  (searchQuery.isEmpty || listing.title.toLowerCase().contains(searchQuery.toLowerCase()) || listing.description.toLowerCase().contains(searchQuery.toLowerCase()))
                                )
                                .toList();
                            // Already globally sorted; keep order when filtered by maintaining original order
                            // but we may re-apply stable sort on the filtered subset
                            _sortListings(filteredListings);
                            final listing = filteredListings[index];

                            Widget badge(String text, Color bg, Color fg) => Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
                                );

                            final promoted = listing.isPromoted;
                            final featured = listing.isFeatured && !promoted;

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
                                          color: promoted ? Colors.orange.shade800 : AppColor.textBlack,
                                        ),
                                      ),
                                    ),
                                    if (promoted) badge('PROMOTED', Colors.amber.shade400, Colors.black87),
                                    if (featured) badge('FEATURED', Colors.blue.shade600, Colors.white),
                                  ],
                                ),
                                subtitle: Text(listing.description, style: TextStyle(color: AppColor.textDark.withOpacity(0.7))),
                                trailing: Text('\u20a6${listing.price}', style: TextStyle(color: promoted ? Colors.orange.shade800 : AppColor.primary, fontWeight: FontWeight.bold)),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ListingDetailPage(listing: listing),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!SupabaseHelper.requireAuth(context, feature: 'add listing')) {
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ListingFormPage()),
          );
        },
        backgroundColor: AppColor.primary,
        tooltip: 'Add Listing',
        child: Icon(Icons.add, color: AppColor.textLight),
      ),
    );
  }
}
