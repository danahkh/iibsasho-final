import 'dart:async';
import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/model/listing.dart';
import '../../core/services/listing_service.dart';
import '../../core/services/promotion_fair_service.dart';
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
    _scrollController.addListener(_onScroll);
    _debugDatabaseContent();
  }

  Future<void> _loadAllListings() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
  // Removed debug log
      final listings = await ListingService.fetchListings();
      // Fair promotional ordering (replaces previous heuristic)
      List<Listing> ordered;
      try {
        ordered = await PromotionFairService.orderFairly(listings);
      } catch (_) {
        ordered = _applyPromotionOrdering(listings); // fallback
      }
      setState(() {
        _allListings = ordered;
        _currentPage = 0;
        int endIndex = (_pageSize < ordered.length) ? _pageSize : ordered.length;
        _displayedListings = ordered.take(endIndex).toList();
        _listingsFuture = Future.value(_displayedListings);
        _isLoading = false;
      });
      _recordInitialImpressions();
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _filterListings() async {
    if (_isLoading) return;
    List<Listing> filtered = List.from(_allListings);

    // Category filter
    if (selectedCategory != null) {
      filtered = filtered.where((l) => l.category == selectedCategory!.id).toList();
    }
    // Subcategory filter with flexible rent/sale handling
    if (selectedSubcategory != null) {
      final selectedSub = selectedSubcategory!.id.toLowerCase();
      filtered = filtered.where((l) {
        final listingSub = l.subcategory.toLowerCase();
        if (listingSub == selectedSub) return true;
        bool matches = false;
        // Rent grouping
        if (selectedSub.contains('rent') && listingSub.contains('rent')) {
          String baseSel = selectedSub.replaceAll('_rent', '').replaceAll('rent', '').trim();
            String baseLst = listingSub.replaceAll('_rent', '').replaceAll('rent', '').trim();
            if (baseSel.isNotEmpty && (baseLst.contains(baseSel) || baseSel.contains(baseLst))) matches = true;
        }
        // Sale grouping
        if (!matches && selectedSub.contains('sale') && listingSub.contains('sale')) {
          String baseSel = selectedSub.replaceAll('_sale', '').replaceAll('sale', '').trim();
          String baseLst = listingSub.replaceAll('_sale', '').replaceAll('sale', '').trim();
          if (baseSel.isNotEmpty && (baseLst.contains(baseSel) || baseSel.contains(baseLst))) matches = true;
        }
        // Flexible underscore removal comparison
        if (!matches) {
          final noUnderscoreSel = selectedSub.replaceAll('_', '');
          final noUnderscoreLst = listingSub.replaceAll('_', '');
          if (noUnderscoreLst.contains(noUnderscoreSel) || noUnderscoreSel.contains(noUnderscoreLst)) matches = true;
        }
        return matches;
      }).toList();
    }

    // Price range
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
      filtered = filtered.where((listing) => listing.location.toLowerCase().contains(_selectedLocation!.toLowerCase())).toList();
    }

    // Sorting
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

    // Re-apply promotional ordering within filtered subset
    List<Listing> ordered;
    try {
      ordered = await PromotionFairService.orderFairly(filtered);
    } catch (_) {
      ordered = _applyPromotionOrdering(filtered);
    }
    if (!mounted) return;
    setState(() {
      _currentPage = 0;
      int endIndex = (_pageSize < ordered.length) ? _pageSize : ordered.length;
      _displayedListings = ordered.take(endIndex).toList();
      _listingsFuture = Future.value(_displayedListings);
    });
    _recordInitialImpressions();
  }

  // Promotional ordering logic
  List<Listing> _applyPromotionOrdering(List<Listing> input) {
    if (input.isEmpty) return input;

    // Separate buckets
    final featured = <Listing>[];
    final promotedOnly = <Listing>[];
    final regular = <Listing>[];
    for (final l in input) {
      if (l.isFeatured) {
        featured.add(l);
      } else if (l.isPromoted) {
        promotedOnly.add(l);
      } else {
        regular.add(l);
      }
    }

    // Sort buckets (newest & lightly weighted by viewCount)
    int compare(Listing a, Listing b) {
      final scoreA = a.createdAt.millisecondsSinceEpoch + (a.viewCount * 1000);
      final scoreB = b.createdAt.millisecondsSinceEpoch + (b.viewCount * 1000);
      return scoreB.compareTo(scoreA); // desc
    }
    featured.sort(compare);
    promotedOnly.sort(compare);

    final result = <Listing>[];
    const int maxTop = 2;
    // Fill top spots: prefer featured first then promoted
    final promoQueue = <Listing>[]..addAll(featured)..addAll(promotedOnly);
    final usedIds = <String>{};
    for (var i = 0; i < maxTop && promoQueue.isNotEmpty; i++) {
      final pick = promoQueue.removeAt(0);
      result.add(pick);
      usedIds.add(pick.id);
      featured.removeWhere((e) => e.id == pick.id);
      promotedOnly.removeWhere((e) => e.id == pick.id);
    }

    // Prepare remaining promo items (featured > promoted) for later insertion
    final remainingPromos = <Listing>[]..addAll(featured)..addAll(promotedOnly);

    if (remainingPromos.isEmpty) {
      // Just append regular then return
      for (final r in regular) { if (!usedIds.contains(r.id)) result.add(r); }
      // Append any leftovers (shouldn't exist now)
      for (final p in remainingPromos) { if (!usedIds.contains(p.id)) result.add(p); }
      return result;
    }

    // Deterministic pseudo-random spacing between 5-9
    final seed = DateTime.now().day + DateTime.now().month * 31;
    int intervalForIndex(int idx) => 5 + ((seed + idx) % 5); // yields 5..9

    int sinceLastInsert = 0;
    int promoIdx = 0;
    int currentInterval = intervalForIndex(0);

    for (final r in regular) {
      result.add(r);
      sinceLastInsert++;
      if (promoIdx < remainingPromos.length && sinceLastInsert >= currentInterval) {
        result.add(remainingPromos[promoIdx]);
        usedIds.add(remainingPromos[promoIdx].id);
        promoIdx++;
        sinceLastInsert = 0;
        currentInterval = intervalForIndex(promoIdx);
      }
    }
    // Append any leftover promos if not yet inserted
    while (promoIdx < remainingPromos.length) {
      result.add(remainingPromos[promoIdx]);
      promoIdx++;
    }

    return result;
  }

  void _recordInitialImpressions() {
    // Record impressions for first screenful (e.g., first 15 items)
    final slice = _displayedListings.take(15).where((l) => l.isPromoted || l.isFeatured).map((l) => l.id).toList();
    if (slice.isEmpty) return;
    PromotionFairService.recordImpressions(slice);
  }

  Future<void> _debugDatabaseContent() async {
    try {
  // Debug helper removed
    } catch (e) {
  // Suppressed debug print
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
  // Removed debug log
      await _loadAllListings();
    } else {
  // Removed debug log
      _filterListings();
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
          PopupMenuButton<String>(
            icon: Icon(Icons.language, color: AppColor.textLight),
            onSelected: (String language) {
              // Removed debug log
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
  physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.8, // Made smaller
          crossAxisSpacing: 6, // Reduced spacing
          mainAxisSpacing: 6, // Reduced spacing
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
    final bool featured = listing.isFeatured == true;
    final bool promoted = listing.isPromoted == true && !featured;
    final Color accent = featured
        ? const Color(0xFFE3F2FD)
        : promoted
            ? const Color(0xFFFFF8E1)
            : AppColor.cardBackground;
    final Color borderColor = featured
        ? const Color(0xFF42A5F5)
        : promoted
            ? const Color(0xFFFFC107)
            : AppColor.borderLight;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      // Removed maxHeight to prevent RenderFlex overflow; allow natural growth
      constraints: BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (featured || promoted)
            BoxShadow(
              color: borderColor.withOpacity(0.25),
              offset: Offset(0, 4),
              blurRadius: 14,
            )
          else
            BoxShadow(
              color: AppColor.shadowColor.withOpacity(0.08),
              offset: Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
        ],
        border: Border.all(
          color: borderColor,
          width: (featured || promoted) ? 2 : 1,
        ),
        gradient: (featured || promoted)
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (featured ? const Color(0xFFBBDEFB) : const Color(0xFFFFE082)).withOpacity(0.55),
                  accent
                ],
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
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
              ClipRRect(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                child: Container(
                  width: 100,
                  constraints: BoxConstraints(minHeight: 120, maxHeight: 140),
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
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (featured || promoted)
                        Align(
                          alignment: Alignment.topLeft,
                          child: _buildPromoTag(featured: featured),
                        ),
                      if (featured || promoted) SizedBox(height: 4),
                      Text(
                        listing.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        listing.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
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
                                    color: AppColor.primary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
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
    final bool featured = listing.isFeatured == true;
    final bool promoted = listing.isPromoted == true && !featured;
    final Color accent = featured
        ? const Color(0xFFE3F2FD)
        : promoted
            ? const Color(0xFFFFF8E1)
            : AppColor.cardBackground;
    final Color borderColor = featured
        ? const Color(0xFF42A5F5)
        : promoted
            ? const Color(0xFFFFC107)
            : AppColor.borderLight;
    return Container(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          if (featured || promoted)
            BoxShadow(
              color: borderColor.withOpacity(0.25),
              offset: Offset(0, 4),
              blurRadius: 10,
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
          color: borderColor,
          width: (featured || promoted) ? 2 : 1,
        ),
        gradient: (featured || promoted)
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (featured
                          ? const Color(0xFFBBDEFB)
                          : const Color(0xFFFFE082))
                      .withOpacity(0.6),
                  accent
                ],
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
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
                child: ClipRRect(
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
                              return Container(
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
              ),
              // Content section - Made smaller
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (featured || promoted)
                        Align(
                          alignment: Alignment.topLeft,
                          child: _buildPromoTag(featured: featured, compact: true),
                        ),
                      if (featured || promoted) SizedBox(height: 4),
                      // Title
                      Text(
                        listing.title,
                        style: TextStyle(
                          fontSize: 12, // Readable title
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary,
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
                          color: AppColor.textSecondary,
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

  Widget _buildPromoTag({required bool featured, bool compact = false}) {
    final color = featured ? const Color(0xFF0277BD) : const Color(0xFFFF8F00);
    final bg = featured ? const Color(0xFFB3E5FC) : const Color(0xFFFFECB3);
    final label = featured ? 'FEATURED' : 'PROMOTED';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(featured ? Icons.star : Icons.trending_up, size: compact ? 12 : 14, color: color),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: compact ? 9 : 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
        ],
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
}
