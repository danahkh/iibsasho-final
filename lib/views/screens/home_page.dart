import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';
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
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

// Made public so other files (PageSwitcher, bottom nav) can reference its State via the global key
class HomePageState extends State<HomePage> {
  Timer? flashsaleCountdownTimer;
  Timer? _debounceTimer;
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
  List<Listing> _allListings = [];
  List<Listing> _displayedListings = [];
  List<Listing> _recommended = [];
  bool _loadingRecommended = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final int _pageSize = 20;
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();
  
  String? _selectedPriceRange;
  String? _selectedSortBy;
  String? _selectedLocation;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    selectedCategory = null;
    _listingsFuture = Future.value(<Listing>[]);
    _loadAllListings();
  _loadRecommendations();
    _scrollController.addListener(_onScroll);
    _debugDatabaseContent();
  }

  Future<void> _loadAllListings() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
  AppLogger.d('Loading all listings from database...');
  final listings = await ListingService.fetchListings();
  _sortListings(listings);
      setState(() {
        _allListings = listings;
        _currentPage = 0;
        int endIndex = (_pageSize < listings.length) ? _pageSize : listings.length;
        _displayedListings = listings.take(endIndex).toList();
        _listingsFuture = Future.value(_displayedListings);
        _isLoading = false;
      });
  AppLogger.d('Loaded \\${listings.length} listings (showing first \\${_displayedListings.length})');
    } catch (e) {
  AppLogger.e('Error loading listings', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    if (_loadingRecommended) return;
    final user = SupabaseHelper.currentUser;
    if (user == null) return;
    setState(() { _loadingRecommended = true; });
    try {
      final recs = await ListingService.recommendListings(user.id, limit: 20);
      setState(() { _recommended = recs; });
    } catch (e) {
      AppLogger.e('Recommendation load error', e);
    } finally {
      if (mounted) setState(() { _loadingRecommended = false; });
    }
  }

  void _filterListings() {
    _debounceTimer?.cancel();
    
  if (_isLoading) return; // skip while loading
    
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      _performFiltering();
    });
  }
  
  void _performFiltering() {
    if (_isLoading || !mounted) return;
    
  // Removed verbose filtering debug logs for production
    
    List<Listing> filtered = List.from(_allListings);

    // Enhanced category filtering
    if (selectedCategory != null) {
  // category filter applied
      
      filtered = filtered.where((listing) {
        final listingCategory = listing.category.toLowerCase().trim();
        final selectedCategoryId = selectedCategory!.id.toLowerCase().trim();
        
        bool matches = false;
        
        // Direct match
        if (listingCategory == selectedCategoryId) {
          matches = true;
        }
        
        // Handle underscore/space variations
        if (listingCategory.replaceAll('_', ' ') == selectedCategoryId.replaceAll('_', ' ')) {
          matches = true;
        }
        
        if (listingCategory.replaceAll(' ', '_') == selectedCategoryId.replaceAll(' ', '_')) {
          matches = true;
        }
        
        // Special handling for real estate
        if (selectedCategoryId == 'real_estate' || selectedCategoryId == 'real estate') {
          if (listingCategory.contains('real') || 
              listingCategory == 'realestate' || 
              listingCategory == 'real_estate' || 
              listingCategory == 'real estate') {
            matches = true;
          }
        }
        
        // Additional flexible matching
        if (listingCategory.contains(selectedCategoryId.replaceAll('_', '')) ||
            selectedCategoryId.contains(listingCategory.replaceAll('_', ''))) {
          matches = true;
        }
        
  // category match debug removed
        
        return matches;
      }).toList();
      
  // category filter count: filtered.length
    }

    // Enhanced subcategory filtering
    if (selectedSubcategory != null) {
  // subcategory filter applied
      
      filtered = filtered.where((listing) {
        final listingSubcategory = listing.subcategory.toLowerCase().trim();
        final selectedSubcategoryId = selectedSubcategory!.id.toLowerCase().trim();
        
        bool matches = false;
        
        // Direct match
        if (listingSubcategory == selectedSubcategoryId) {
          matches = true;
        }
        
        // Handle underscore/space variations
        if (listingSubcategory.replaceAll('_', ' ') == selectedSubcategoryId.replaceAll('_', ' ')) {
          matches = true;
        }
        
        if (listingSubcategory.replaceAll(' ', '_') == selectedSubcategoryId.replaceAll(' ', '_')) {
          matches = true;
        }
        
        // Special handling for rent/sale subcategories
        if (selectedSubcategoryId.contains('rent')) {
          if (listingSubcategory.contains('rent')) {
            String selectedBase = selectedSubcategoryId.replaceAll('_rent', '').replaceAll('rent', '').trim();
            String listingBase = listingSubcategory.replaceAll('_rent', '').replaceAll('rent', '').trim();
            if (selectedBase.isNotEmpty && (listingBase.contains(selectedBase) || selectedBase.contains(listingBase))) {
              matches = true;
            }
          }
        }
        
        if (selectedSubcategoryId.contains('sale')) {
          if (listingSubcategory.contains('sale')) {
            String selectedBase = selectedSubcategoryId.replaceAll('_sale', '').replaceAll('sale', '').trim();
            String listingBase = listingSubcategory.replaceAll('_sale', '').replaceAll('sale', '').trim();
            if (selectedBase.isNotEmpty && (listingBase.contains(selectedBase) || selectedBase.contains(listingBase))) {
              matches = true;
            }
          }
        }
        
        // Additional flexible matching
        if (listingSubcategory.contains(selectedSubcategoryId.replaceAll('_', '')) ||
            selectedSubcategoryId.contains(listingSubcategory.replaceAll('_', ''))) {
          matches = true;
        }
        
  // subcategory match debug removed
        
        return matches;
      }).toList();
      
  // subcategory filter count: filtered.length
    }

    // Apply other filters
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

    if (_selectedLocation != null && _selectedLocation != 'Any Location') {
      filtered = filtered.where((listing) {
        return listing.location.toLowerCase().contains(_selectedLocation!.toLowerCase());
      }).toList();
    }

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
          filtered.sort((a, b) => a.title.compareTo(b.title));
          break;
      }
    }

  // Always apply promoted/featured priority before exposing filtered results
  _sortListings(filtered);
  // filtering complete

    if (mounted && !_isLoading) {
      setState(() {
        _currentPage = 0;
        int endIndex = (_pageSize < filtered.length) ? _pageSize : filtered.length;
        _displayedListings = filtered.take(endIndex).toList();
        _listingsFuture = Future.value(_displayedListings);
      });
    }
  }

  Widget _buildRecommendedCarousel() {
    if (_recommended.isEmpty && !_loadingRecommended) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
        child: Text('No personalized recommendations yet', style: TextStyle(color: AppColor.textSecondary, fontSize: 12)),
      );
    }
    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _recommended.length.clamp(0, 20),
        separatorBuilder: (_, __) => SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final l = _recommended[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ListingDetailPage(listing: l))),
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                color: AppColor.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColor.border.withOpacity(0.5)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0,2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: AspectRatio(
                      aspectRatio: 4/3,
                      child: l.images.isNotEmpty
                          ? Image.network(
                              _resolveImageUrl(l.images.first),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: Icon(Icons.image_not_supported)),
                            )
                          : Container(color: Colors.grey.shade100, child: Icon(Icons.photo, color: Colors.grey)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColor.textDark)),
                        SizedBox(height: 2),
                        Text(l.formattedPrice, style: TextStyle(fontSize: 12, color: AppColor.primary, fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text(l.category, style: TextStyle(fontSize: 10, color: AppColor.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _resolveImageUrl(String raw) {
    final url = raw.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    try {
      final path = url.startsWith('/') ? url.substring(1) : url;
      if (path.startsWith('storage/v1/object/public/')) {
        final rest = path.replaceFirst('storage/v1/object/public/', '');
        final firstSlash = rest.indexOf('/');
        if (firstSlash > 0) {
          final bucket = rest.substring(0, firstSlash);
          final objectPath = rest.substring(firstSlash + 1);
          return SupabaseHelper.client.storage.from(bucket).getPublicUrl(objectPath);
        }
      }
      return SupabaseHelper.client.storage.from('listings').getPublicUrl(path);
    } catch (_) {
      return raw;
    }
  }

  // Ensure promoted listings appear first, then featured, then newest
  void _sortListings(List<Listing> list) {
    list.sort((a, b) {
      final promo = (b.isPromoted ? 1 : 0) - (a.isPromoted ? 1 : 0);
      if (promo != 0) return promo;
      final feat = (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0);
      if (feat != 0) return feat;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> _debugDatabaseContent() async {
    try {
      await ListingService.debugCategoriesInDatabase();
    } catch (e) {
  AppLogger.e('Error debugging database', e);
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
    if (selectedCategory == null && selectedSubcategory == null) {
  AppLogger.d('Refreshing all listings from database...');
      await _loadAllListings();
    } else {
  AppLogger.d('Applying filters to cached data...');
      _filterListings();
    }
  }

  /// Public method invoked from navigation (e.g., tapping Home icon) to force a feed refresh
  Future<void> refreshFromNav() async {
    // Ensure drawer is closed when returning
    closeDrawerIfOpen();
    // Scroll to top first for better UX
    if (mounted) {
      try {
        await _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      } catch (_) {}
    }
    await _refreshListings();
  }

  /// Close drawer if it's currently open to avoid persisting overlay when navigating back.
  void closeDrawerIfOpen() {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  /// Stronger variant used by the tab switcher to guarantee the drawer closes.
  Future<void> forceCloseDrawer() async {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null) return;
    int safety = 2; // attempt twice in case of timing
    while (scaffoldState.isDrawerOpen && safety-- > 0) {
      Navigator.of(scaffoldState.context).pop();
      // brief delay to let framework process the pop
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  @override
  void dispose() {
    flashsaleCountdownTimer?.cancel();
    _debounceTimer?.cancel();
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
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    // Open full search experience page
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColor.inputBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColor.inputBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColor.iconSecondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Search products, categories...',
                            style: TextStyle(
                              color: AppColor.placeholder,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.language, color: AppColor.textLight),
            onSelected: (String language) {
              AppLogger.d('Selected language: $language');
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'ar', child: Text('العربية')),
              PopupMenuItem(value: 'so', child: Text('Soomaali')),
            ],
          ),
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
          Container(
            color: AppColor.cardBackground,
            child: Column(
              children: [
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_recommended.isNotEmpty || _loadingRecommended) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Row(
                    children: [
                      Text('Recommended for you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.textDark)),
                      if (_loadingRecommended) ...[
                        SizedBox(width: 8), SizedBox(width:16,height:16,child: CircularProgressIndicator(strokeWidth:2))
                      ],
                      Spacer(),
                      if (_recommended.isNotEmpty)
                        IconButton(
                          tooltip: 'Refresh',
                          icon: Icon(Icons.refresh, size: 20),
                          onPressed: _loadingRecommended ? null : _loadRecommendations,
                        ),
                    ],
                  ),
                ),
                _buildRecommendedCarousel(),
                SizedBox(height: 12),
              ],
              Text(
                'Advanced Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              SizedBox(height: 20),
              Text('Price Range', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Any', '\$0-\$100', '\$100-\$500', '\$500-\$1000', '\$1000+'].map((range) =>
                  ChoiceChip(
                    label: Text(range),
                    selected: _selectedPriceRange == range,
                    selectedColor: AppColor.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _selectedPriceRange == range ? AppColor.primary : AppColor.textSecondary,
                      fontWeight: _selectedPriceRange == range ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedPriceRange = selected ? range : null;
                      });
                    },
                  ),
                ).toList(),
              ),
              SizedBox(height: 20),
              Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Newest', 'Price: Low to High', 'Price: High to Low', 'Most Popular'].map((sort) =>
                  ChoiceChip(
                    label: Text(sort),
                    selected: _selectedSortBy == sort,
                    selectedColor: AppColor.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _selectedSortBy == sort ? AppColor.primary : AppColor.textSecondary,
                      fontWeight: _selectedSortBy == sort ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedSortBy = selected ? sort : null;
                      });
                    },
                  ),
                ).toList(),
              ),
              SizedBox(height: 20),
              Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Any Location', 'Hargeisa', 'Berbera', 'Burco', 'Borama'].map((location) =>
                  ChoiceChip(
                    label: Text(location),
                    selected: _selectedLocation == location,
                    selectedColor: AppColor.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _selectedLocation == location ? AppColor.primary : AppColor.textSecondary,
                      fontWeight: _selectedLocation == location ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setModalState(() {
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
                        setModalState(() {
                          _selectedPriceRange = null;
                          _selectedSortBy = null;
                          _selectedLocation = null;
                        });
                        setState(() {
                          _selectedPriceRange = null;
                          _selectedSortBy = null;
                          _selectedLocation = null;
                        });
                        Navigator.pop(context);
                        _filterListings();
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
                        setState(() {
                          // Update main state with modal state
                        });
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
      ),
    );
  }

  Widget _buildErrorState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
          ),
        ),
      ],
    );
  }

  Widget _buildListingsGrid() {
    if (_isGridView) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Choose a max tile width that scales with screen size
          double maxExtent;
          if (width < 480) {
            maxExtent = 200; // phones
          } else if (width < 760) {
            maxExtent = 240; // small tablets / narrow windows
          } else if (width < 1100) {
            maxExtent = 280; // tablets / typical laptop half screen
          } else {
            maxExtent = 320; // wide screens
          }
          // Slightly taller than wide to accommodate text; avoids overflow bands
          final aspect = 3 / 4; // width : height = 3 : 4

          return GridView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxExtent,
              childAspectRatio: aspect,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _displayedListings.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _displayedListings.length) {
                return Container(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                  ),
                );
              }

              final listing = _displayedListings[index];
              return _buildImprovedGridItem(listing);
            },
          );
        },
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
  physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        itemCount: _displayedListings.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _displayedListings.length) {
            return Container(
              padding: EdgeInsets.all(16),
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
              ),
            );
          }

          final listing = _displayedListings[index];
          return _buildImprovedListItem(listing);
        },
      );
    }
  }

  Widget _buildImprovedListItem(listing) {
    final bool isPromoted = listing.isPromoted == true;
    final bool isFeatured = listing.isFeatured == true && !isPromoted;
    return Container(
      margin: EdgeInsets.only(bottom: 16),
  // Allow height to grow (fix overflow when badges + longer text)
  constraints: BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        // Only promoted gets special background; others revert to original card background
        color: isPromoted ? Colors.amber.shade100 : AppColor.cardBackground,
        gradient: isPromoted
            ? LinearGradient(
                colors: [
                  Colors.amber.shade200,
                  Colors.amber.shade100,
                  Colors.amber.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isPromoted)
            BoxShadow(
              color: Colors.amber.withOpacity(0.35),
              offset: Offset(0, 6),
              blurRadius: 18,
              spreadRadius: 0,
            )
          else if (isFeatured)
            BoxShadow(
              color: AppColor.primary.withOpacity(0.2),
              offset: Offset(0, 4),
              blurRadius: 14,
              spreadRadius: 0,
            )
          else ...[
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
        ],
        border: Border.all(
          color: isPromoted
              ? Colors.amber.shade600
              : isFeatured
                  ? AppColor.primary
                  : AppColor.borderLight,
          width: isPromoted || isFeatured ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            AppLogger.d('Tapping listing: ${listing.title}');
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
                    // Let image adapt to parent height (no fixed max to avoid overflow)
                    constraints: BoxConstraints(minHeight: 120),
                  color: AppColor.inputBackground,
                  child: listing.images.isNotEmpty
                      ? Image.network(
                          listing.images.first,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 100,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badges Row
                      if (isPromoted || isFeatured)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              if (isPromoted) _buildBadge('PROMOTED', Colors.amber.shade400, Colors.black87),
                              if (isFeatured) _buildBadge('FEATURED', AppColor.accent, Colors.white),
                            ],
                          ),
                        ),
                      // Title
                      Text(
                        listing.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isPromoted ? Colors.brown.shade800 : AppColor.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      // Description
                      Text(
                        listing.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isPromoted ? Colors.brown.shade700.withOpacity(.85) : AppColor.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      // Bottom section with organized rows
                      Flexible(
                        fit: FlexFit.loose,
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First row: Location and Category tag
                          Row(
                            children: [
                              // Location
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 12,
                                      color: AppColor.textSecondary,
                                    ),
                                    SizedBox(width: 3),
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
                                  ],
                                ),
                              ),
                              SizedBox(width: 6),
                              // Category tag
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColor.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  listing.category.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: isPromoted ? Colors.brown.shade800 : AppColor.primary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          // Second row: Price and Subcategory tag
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Price
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '\$${listing.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isPromoted ? Colors.green.shade800 : Colors.green[700],
                                  ),
                                ),
                              ),
                              // Subcategory tag (if available)
                              if (listing.subcategory.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getSubcategoryColor(listing.subcategory),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    listing.subcategory.replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImprovedGridItem(listing) {
    final bool isPromoted = listing.isPromoted == true;
    final bool isFeatured = listing.isFeatured == true && !isPromoted;
    return Container(
      decoration: BoxDecoration(
        color: isPromoted ? Colors.amber.shade100 : AppColor.cardBackground,
        gradient: isPromoted
            ? LinearGradient(
                colors: [
                  Colors.amber.shade200,
                  Colors.amber.shade100,
                  Colors.amber.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (isPromoted)
            BoxShadow(
              color: Colors.amber.withOpacity(0.35),
              offset: Offset(0, 4),
              blurRadius: 14,
              spreadRadius: 0,
            )
          else if (isFeatured)
            BoxShadow(
              color: AppColor.primary.withOpacity(0.18),
              offset: Offset(0, 3),
              blurRadius: 12,
              spreadRadius: 0,
            )
          else
            BoxShadow(
              color: AppColor.shadowColor.withOpacity(0.1),
              offset: Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
        ],
        border: Border.all(
          color: isPromoted
              ? Colors.amber.shade600
              : isFeatured
                  ? AppColor.primary
                  : AppColor.borderLight,
          width: isPromoted || isFeatured ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            AppLogger.d('Tapping listing: ${listing.title}');
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
              // Image section
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: Container(
                        width: double.infinity,
                        color: AppColor.inputBackground,
                        child: listing.images.isNotEmpty
                            ? Image.network(
                                listing.images.first,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppColor.placeholder.withOpacity(0.3),
                                  child: Icon(Icons.image_not_supported, size: 32, color: AppColor.textSecondary),
                                ),
                              )
                            : Icon(Icons.image, size: 32, color: AppColor.textSecondary),
                      ),
                    ),
                    if (isPromoted || isFeatured)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Row(
                          children: [
                            if (isPromoted) _buildBadge('PROMOTED', Colors.amber.shade400, Colors.black87, dense: true),
                            if (isFeatured) _buildBadge('FEATURED', AppColor.accent, Colors.white, dense: true),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Content section - Made smaller
              Expanded(
                flex: 1, // Compact content section
                child: Padding(
                  padding: EdgeInsets.all(4), // Ultra minimal padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges in list layout (if any) appear over image; here we only show title
                      // Title
                      Text(
                        listing.title,
                        style: TextStyle(
                          fontSize: 12, // Readable title
                          fontWeight: FontWeight.w600,
                          color: isPromoted ? Colors.brown.shade800 : AppColor.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      // Description
                      Text(
                        listing.description,
                        style: TextStyle(
                          fontSize: 10, // Readable description
                          color: isPromoted ? Colors.brown.shade700.withOpacity(.85) : AppColor.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 1, // Reduced from 2
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacer(),
                      // Bottom section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location and Category row
                          Row(
                            children: [
                              // Location
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 10, // Readable icon
                                      color: AppColor.textSecondary,
                                    ),
                                    SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        listing.location.isNotEmpty ? listing.location : 'Location not specified',
                                        style: TextStyle(
                                          fontSize: 9, // Readable location
                                          color: AppColor.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 3), // Readable spacing from 4
                              // Category tag
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Readable padding
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4), // Reduced from 6
                                  border: Border.all(
                                    color: AppColor.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  listing.category.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8, // Readable category
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.primary,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3), // Readable spacing
                          // Price and Subcategory row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Price
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Readable padding
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6), // Reduced from 8
                                ),
                                child: Text(
                                  '\$${listing.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 11, // Readable price
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                              // Subcategory tag (if available)
                              if (listing.subcategory.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Readable padding
                                  decoration: BoxDecoration(
                                    color: _getSubcategoryColor(listing.subcategory),
                                    borderRadius: BorderRadius.circular(4), // Reduced from 6
                                  ),
                                  child: Text(
                                    listing.subcategory.replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontSize: 9, // Readable subcategory
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    final currentUser = SupabaseHelper.currentUser;
    
    if (currentUser == null) {
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
    
    final colorIndex = subcategory.hashCode.abs() % colors.length;
    return colors[colorIndex];
  }

  Widget _buildBadge(String text, Color bg, Color fg, {bool dense = false}) {
    return Container(
      margin: EdgeInsets.only(right: 6),
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.4),
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: dense ? 8.5 : 10,
          fontWeight: FontWeight.bold,
          letterSpacing: .5,
        ),
      ),
    );
  }
}
