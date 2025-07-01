import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import 'package:iibsasho/views/widgets/main_app_bar_widget.dart';
import 'package:iibsasho/core/model/listing.dart';
import 'package:iibsasho/core/services/listing_service.dart';
import 'package:iibsasho/views/screens/product_detail.dart';
import 'package:iibsasho/views/screens/listing_form_page.dart';
import '../../core/constant_categories.dart';

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

  Future<void> _refreshListings() async {
    setState(() => _loading = true);
    _listings = await ListingService().fetchListings();
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    selectedCategory = staticCategories.first;
    // _refreshListings(); // Only refresh on pull-to-refresh
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
                            final listing = filteredListings[index];
                            return ListTile(
                              title: Text(listing.title, style: TextStyle(color: AppColor.textBlack)),
                              subtitle: Text(listing.description, style: TextStyle(color: AppColor.textDark.withOpacity(0.7))),
                              trailing: Text('\u20a6${listing.price}', style: TextStyle(color: AppColor.primary)),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ListingDetailPage(listing: listing),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
