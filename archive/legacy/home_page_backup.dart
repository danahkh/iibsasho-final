import 'dart:async';
import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/model/listing.dart';
import '../../core/services/listing_service.dart';
import '../../core/utils/supabase_helper.dart';
import '../../core/constant_categories.dart';
import 'product_detail.dart';
import '../../core/services/notification_service.dart';
import '../../core/model/notification_item.dart';
import '../../widgets/home_drawer.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? flashsaleCountdownTimer;
  Timer? _debounceTimer; // Add debounce timer
  Duration flashsaleCountdownDuration = Duration(
    hours: 24 - DateTime.now().hour,
    minutes: 60 - DateTime.now().minute,
    seconds: 60 - DateTime.now().second,
  );

  final List<CategoryItem> staticCategories = AppCategories.categories;
  CategoryItem? selectedCategory;
  SubcategoryItem? selectedSubcategory;
  bool showSubcategories = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Future<List<Listing>> _listingsFuture;
  List<Listing> _allListings = []; // Cache all listings
  List<Listing> _displayedListings = []; // Currently displayed listings
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final int _pageSize = 20;
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();
  
  // Filter states
  String? _selectedPriceRange;
  String? _selectedSortBy;
  String? _selectedLocation;
  bool _isGridView = false; // Toggle between grid and list view
  final bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    selectedCategory = null; // Don't select a category by default
    
    // Initialize _listingsFuture immediately to prevent LateInitializationError
    _listingsFuture = Future.value(<Listing>[]);
    
    _loadAllListings(); // Load all listings once
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Debug: Check what's actually in the database
    _debugDatabaseContent();
  }

  // Load all listings once and cache them
  Future<void> _loadAllListings() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading all listings from database...');
      final listings = await ListingService.fetchListings();
      setState(() {
        _allListings = listings;
        _currentPage = 0;
        // Load first page of listings
        int endIndex = (_pageSize < listings.length) ? _pageSize : listings.length;
        _displayedListings = listings.take(endIndex).toList();
        _listingsFuture = Future.value(_displayedListings);
        _isLoading = false;
      });
      print('Loaded ${listings.length} listings into cache, displaying first ${_displayedListings.length}');
    } catch (e) {
      print('Error loading listings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter cached listings with debounce to prevent rapid rebuilds
  void _filterListings() {
    // Cancel any pending filter operations
    _debounceTimer?.cancel();
    
    // Skip if already loading to prevent conflicts
    if (_isLoading) {
      print('Filtering skipped - loading in progress');
      return;
    }
    
    // Add a small delay to prevent rapid successive calls
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      _performFiltering();
    });
  }
  
  void _performFiltering() {
    if (_isLoading || !mounted) return;
    
    print('Filtering cached listings with category: ${selectedCategory?.id}, subcategory: ${selectedSubcategory?.id}');
    
    List<Listing> filtered = List.from(_allListings);

    // Apply category filter
    if (selectedCategory != null) {
      filtered = filtered.where((listing) {
        return listing.category.toLowerCase() == selectedCategory!.id.toLowerCase();
      }).toList();
    }

    // Apply subcategory filter
    if (selectedSubcategory != null) {
      filtered = filtered.where((listing) {
        return listing.subcategory.toLowerCase() == selectedSubcategory!.id.toLowerCase();
      }).toList();
    }

    // Apply advanced filters
    // Price range filter
    if (_selectedPriceRange != null && _selectedPriceRange != 'Any') {
      filtered = filtered.where((listing) {
        switch (_selectedPriceRange) {
          case '\$0-\$100':
            return listing.price >= 0 && listing.price <= 100;
          case '\$100-\$500':
            return listing.price > 100 && listing.price <= 500;
          case '\$500-\$1000':
            return listing.price > 500 && listing.price <= 1000;
          case '\$1000+':
            return listing.price > 1000;
          default:
            return true;
        }
      }).toList();
    }

    // Location filter
    if (_selectedLocation != null && _selectedLocation != 'Any Location') {
      filtered = filtered.where((listing) {
        return listing.location.toLowerCase().contains(_selectedLocation!.toLowerCase());
      }).toList();
    }

    // Apply sorting
    if (_selectedSortBy != null) {
      switch (_selectedSortBy) {
        case 'Price: Low to High':
          filtered.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'Price: High to Low':
          filtered.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'Newest':
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'Most Popular':
          // For now, sort by title (can be updated with actual popularity metric)
          filtered.sort((a, b) => a.title.compareTo(b.title));
          break;
      }
    }

    print('Filter result: ${filtered.length} listings found');

    // Only update if we're still mounted and not loading
    if (mounted && !_isLoading) {
      setState(() {
        _currentPage = 0;
        // Load first page of filtered results
        int endIndex = (_pageSize < filtered.length) ? _pageSize : filtered.length;
        _displayedListings = filtered.take(endIndex).toList();
        _listingsFuture = Future.value(_displayedListings);
      });
    }
  }

  Future<void> _debugDatabaseContent() async {
    try {
      await ListingService.debugCategoriesInDatabase();
    } catch (e) {
      print('Error debugging database: $e');
    }
  }

  void startTimer() {
    flashsaleCountdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setCountdown();
    });
  }

  void setCountdown() {
    if (mounted) {
      setState(() {
        final seconds = flashsaleCountdownDuration.inSeconds - 1;

        if (seconds < 1) {
          flashsaleCountdownTimer?.cancel();
        } else {
          flashsaleCountdownDuration = Duration(seconds: seconds);
        }
      });
    }
  }

  Future<void> _refreshListings() async {
    // Only reload from database on explicit refresh (pull-to-refresh)
    // For category filtering, use cached data
    if (selectedCategory == null && selectedSubcategory == null) {
      // No filters, reload from database
      print('Refreshing all listings from database...');
      await _loadAllListings();
    } else {
      // Apply filters to cached data without triggering setState again
      print('Applying filters to cached data...');
      List<Listing> filtered = _allListings;

      // Apply category filter
      if (selectedCategory != null) {
        filtered = filtered.where((listing) {
          return listing.category == selectedCategory!.id;
        }).toList();
      }

      // Apply subcategory filter
      if (selectedSubcategory != null) {
        filtered = filtered.where((listing) {
          return listing.subcategory == selectedSubcategory!.id;
        }).toList();
      }

      print('Filter result: ${filtered.length} listings found');

      // Update the future directly without calling setState
      _listingsFuture = Future.value(filtered);
    }
  }

  Widget _buildListingsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Listings',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 260, // Fixed height constraint
          child: RefreshIndicator(
            onRefresh: _refreshListings,
            child: FutureBuilder<List<Listing>>(
              future: _listingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  print('Error in FutureBuilder: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: AppColor.error),
                        SizedBox(height: 16),
                        Text(
                          'Error loading listings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textDark,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please try again later',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadAllListings(),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: AppColor.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'No listings found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textDark,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Be the first to add a listing!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadAllListings(),
                          child: Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                }
                var listings = snapshot.data!;
                
                // If no listings match the filter, show empty state
                if (listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list_off, size: 48, color: AppColor.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'No listings found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textDark,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          selectedCategory != null 
                            ? 'No ${selectedCategory!.name.toLowerCase()} listings available'
                            : 'Try a different filter',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCategory = null;
                              selectedSubcategory = null;
                              showSubcategories = false;
                            });
                            _loadAllListings(); // Load fresh data instead of filtering
                          },
                          child: Text('Clear Filters'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Prevent scroll conflicts
                  itemCount: listings.length > 3 ? 3 : listings.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    
                    return Container(
                      key: ValueKey('listing_${listing.id}_$index'), // Add unique key
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColor.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.shadowColor.withOpacity(0.1),
                            offset: Offset(0, 4),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: AppColor.shadowColor.withOpacity(0.05),
                            offset: Offset(0, 2),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ],
                        border: Border.all(
                          color: AppColor.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            print('Tapping on listing: ${listing.title}'); // Debug tap
                            try {
                              // Add a small delay to ensure layout is complete
                              await Future.delayed(Duration(milliseconds: 50));
                              
                              // Check if widget is still mounted before navigation
                              if (mounted) {
                                // Allow all users to view listings
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ListingDetailPage(listing: listing),
                                  ),
                                );
                              }
                            } catch (e) {
                              print('Navigation error: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error opening listing: $e')),
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image Box on the left
                                Container(
                                  width: 100,
                                  height: 100,
                                  constraints: BoxConstraints(
                                    minWidth: 100,
                                    minHeight: 100,
                                    maxWidth: 100,
                                    maxHeight: 100,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColor.inputBackground,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColor.border),
                                  ),
                                  child: listing.images.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          listing.images.first,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Image load error: $error');
                                            return SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: Center(
                                                child: Icon(
                                                  Icons.image,
                                                  size: 32,
                                                  color: AppColor.textSecondary,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : SizedBox(
                                        width: 100,
                                        height: 100,
                                        child: Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 32,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                      ),
                                ),
                                SizedBox(width: 16),
                                // Content on the right
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Text(
                                        listing.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 8),
                                      // Description
                                      Text(
                                        listing.description,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColor.textSecondary,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 12),
                                      // Location and Category Row
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: AppColor.textSecondary,
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              listing.location.isNotEmpty ? listing.location : 'Location not specified',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColor.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColor.accent.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              listing.category.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: AppColor.accent,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Price on the far right
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColor.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '\$${listing.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    flashsaleCountdownTimer?.cancel();
    _debounceTimer?.cancel(); // Clean up debounce timer
    _scrollController.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreListings();
    }
  }

  void _loadMoreListings() {
    if (_isLoadingMore || _displayedListings.length >= _allListings.length) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    // Simulate loading delay (remove in production)
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _currentPage++;
        int startIndex = _currentPage * _pageSize;
        int endIndex = (startIndex + _pageSize < _allListings.length) 
            ? startIndex + _pageSize 
            : _allListings.length;
        
        if (startIndex < _allListings.length) {
          _displayedListings.addAll(_allListings.sublist(startIndex, endIndex));
        }
        
        _isLoadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        elevation: 2,
        shadowColor: AppColor.shadowColor,
        leading: IconButton(
          icon: Icon(Icons.menu, color: AppColor.textLight),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            // iibsasho Logo
            Text(
              'iibsasho',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                letterSpacing: -0.8,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            // Shortened Search bar
            Expanded(
              flex: 3, // Reduce search bar width
              child: SizedBox(
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: AppColor.placeholder, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColor.iconSecondary, size: 20),
                    filled: true,
                    fillColor: AppColor.inputBackground,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColor.inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColor.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColor.inputFocusBorder, width: 2),
                    ),
                  ),
                  style: TextStyle(fontSize: 14, color: AppColor.textPrimary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Language Picker
          PopupMenuButton<String>(
            icon: Icon(Icons.language, color: AppColor.textLight),
            onSelected: (String language) {
              // Handle language change
              print('Selected language: $language');
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'ar', child: Text('العربية')),
              PopupMenuItem(value: 'so', child: Text('Soomaali')),
            ],
          ),
          // Notifications
          IconButton(
            icon: _buildNotificationIcon(),
            onPressed: () {
              if (!SupabaseHelper.requireAuth(context, feature: 'notifications')) {
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPage(),
                ),
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      drawer: HomeDrawer(),
      body: Column(
        children: [
          // Fixed header with categories and filters
          Container(
            color: AppColor.cardBackground,
            child: Column(
              children: [
                // Category title and advanced filter button
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category',
                        style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          // Grid/List view toggle
                          Container(
                            decoration: BoxDecoration(
                              color: AppColor.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColor.border),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isGridView = false;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: !_isGridView ? AppColor.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.list,
                                      size: 20,
                                      color: !_isGridView ? Colors.white : AppColor.textSecondary,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isGridView = true;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _isGridView ? AppColor.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.grid_view,
                                      size: 20,
                                      color: _isGridView ? Colors.white : AppColor.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          // Advanced filter button
                          IconButton(
                            icon: Icon(Icons.tune, color: AppColor.primary),
                            onPressed: _showAdvancedFilterDialog,
                            tooltip: 'Advanced Filters',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Category horizontal scroll
                Container(
                  height: 48,
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: staticCategories.length,
                    physics: BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (context, index) => SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = staticCategories[index];
                      final isSelected = selectedCategory?.id == cat.id;
                      return GestureDetector(
                        onTap: () {
                          if (_isLoading) return;
                          
                          setState(() {
                            if (isSelected) {
                              selectedCategory = null;
                              selectedSubcategory = null;
                              showSubcategories = false;
                            } else {
                              selectedCategory = cat;
                              selectedSubcategory = null;
                              showSubcategories = true;
                            }
                          });
                          _filterListings();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColor.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? AppColor.primary : AppColor.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat.icon, size: 18, color: isSelected ? Colors.white : AppColor.primary),
                              SizedBox(width: 6),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 13,
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
                // Subcategories
                if (showSubcategories && selectedCategory != null)
                  Container(
                    height: 40,
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: selectedCategory!.subcategories.length,
                      physics: BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (context, index) => SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final subcat = selectedCategory!.subcategories[index];
                        final isSelected = selectedSubcategory?.id == subcat.id;
                        return GestureDetector(
                          onTap: () {
                            if (_isLoading) return;
                            
                            setState(() {
                              selectedSubcategory = isSelected ? null : subcat;
                            });
                            _filterListings();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColor.accent : AppColor.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColor.accent : AppColor.border,
                              ),
                            ),
                            child: Text(
                              subcat.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? AppColor.textLight : AppColor.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Scrollable content area
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshListings,
              child: FutureBuilder<List<Listing>>(
                future: _listingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _displayedListings.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }
                  
                  if (_displayedListings.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  return _buildListingsGrid();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Filters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 20),
            // Price Range Filter
            Text('Price Range', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Any', '\$0-\$100', '\$100-\$500', '\$500-\$1000', '\$1000+'].map((range) =>
                ChoiceChip(
                  label: Text(range),
                  selected: _selectedPriceRange == range,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPriceRange = selected ? range : null;
                    });
                  },
                ),
              ).toList(),
            ),
            SizedBox(height: 20),
            // Sort By Filter
            Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Newest', 'Price: Low to High', 'Price: High to Low', 'Most Popular'].map((sort) =>
                ChoiceChip(
                  label: Text(sort),
                  selected: _selectedSortBy == sort,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSortBy = selected ? sort : null;
                    });
                  },
                ),
              ).toList(),
            ),
            SizedBox(height: 20),
            // Location Filter
            Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Any Location', 'Hargeisa', 'Berbera', 'Burco', 'Borama'].map((location) =>
                ChoiceChip(
                  label: Text(location),
                  selected: _selectedLocation == location,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLocation = selected ? location : null;
                    });
                  },
                ),
              ).toList(),
            ),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedPriceRange = null;
                        _selectedSortBy = null;
                        _selectedLocation = null;
                      });
                      Navigator.pop(context);
                      _filterListings(); // Apply the cleared filters
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.textSecondary,
                    ),
                    child: Text('Clear All', style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _filterListings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                    ),
                    child: Text('Apply Filters', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColor.error),
          SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              fontSize: 14,
              color: AppColor.textSecondary,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAllListings,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColor.textSecondary),
          SizedBox(height: 16),
          Text(
            'No listings found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            selectedCategory != null 
              ? 'No ${selectedCategory!.name.toLowerCase()} listings available'
              : 'Be the first to add a listing!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColor.textSecondary,
            ),
          ),
          SizedBox(height: 24),
          if (selectedCategory != null)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedCategory = null;
                  selectedSubcategory = null;
                  showSubcategories = false;
                });
                _loadAllListings();
              },
              child: Text('Clear Filters'),
            )
          else
            ElevatedButton(
              onPressed: _loadAllListings,
              child: Text('Refresh'),
            ),
        ],
      ),
    );
  }

  Widget _buildListingsGrid() {
    if (_isGridView) {
      return GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _displayedListings.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _displayedListings.length) {
            // Loading indicator at bottom for grid
            return Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
              ),
            );
          }

          final listing = _displayedListings[index];
          return _buildGridItem(listing);
        },
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: _displayedListings.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _displayedListings.length) {
            // Loading indicator at bottom
            return Container(
              padding: EdgeInsets.all(16),
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
              ),
            );
          }

          final listing = _displayedListings[index];
          return _buildListItem(listing);
        },
      );
    }
  }

  Widget _buildGridItem(listing) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColor.shadowColor.withOpacity(0.1),
            offset: Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          print('Tapping on listing: ${listing.title}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingDetailPage(listing: listing),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  color: AppColor.placeholder.withOpacity(0.3),
                  child: listing.images.isNotEmpty
                      ? Image.network(
                          listing.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColor.placeholder.withOpacity(0.3),
                            child: Icon(Icons.image_not_supported, size: 32, color: AppColor.textSecondary),
                          ),
                        )
                      : Icon(Icons.image, size: 32, color: AppColor.textSecondary),
                ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        // Subcategory tag with color
                        if (listing.subcategory.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getSubcategoryColor(listing.subcategory),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              listing.subcategory,
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                        ],
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${listing.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                        if (listing.location.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 10, color: AppColor.textSecondary),
                              SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  listing.location,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: AppColor.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(listing) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      height: 120,
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.shadowColor.withOpacity(0.1),
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          print('Tapping on listing: ${listing.title}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingDetailPage(listing: listing),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image on the left
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
              child: Container(
                width: 100,
                height: 120,
                color: AppColor.placeholder.withOpacity(0.3),
                child: listing.images.isNotEmpty
                    ? Image.network(
                        listing.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColor.placeholder.withOpacity(0.3),
                          child: Icon(Icons.image_not_supported, size: 32, color: AppColor.textSecondary),
                        ),
                      )
                    : Icon(Icons.image, size: 32, color: AppColor.textSecondary),
              ),
            ),
            // Content on the right
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    // Description (if available)
                    if (listing.description.isNotEmpty) ...[
                      Text(
                        listing.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                    ] else ...[
                      SizedBox(height: 12),
                    ],
                    // Bottom row with price and location
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price on the left
                          Text(
                            '\$${listing.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColor.primary,
                            ),
                          ),
                          // Location on the right
                          if (listing.location.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 12, color: AppColor.textSecondary),
                                SizedBox(width: 2),
                                Text(
                                  listing.location,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Subcategory tag at bottom
                    if (listing.subcategory.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getSubcategoryColor(listing.subcategory),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            listing.subcategory,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    final currentUser = SupabaseHelper.currentUser;
    
    if (currentUser == null) {
      // Show icon without badge for non-authenticated users
      return Icon(Icons.notifications, color: AppColor.textLight);
    }

    return StreamBuilder<List<NotificationItem>>(
      stream: NotificationService.getUserNotifications(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;
        
        return Stack(
          children: [
            Icon(Icons.notifications, color: AppColor.textLight),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColor.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: AppColor.textLight,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _getSubcategoryColor(String subcategory) {
    // Generate consistent colors for subcategories
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];
    
    // Use hash code to get consistent color for same subcategory
    final colorIndex = subcategory.hashCode.abs() % colors.length;
    return colors[colorIndex];
  }
}
