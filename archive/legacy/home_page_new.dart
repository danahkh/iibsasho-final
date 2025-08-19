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
import '../../widgets/app_logo_widget.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    selectedCategory = null;
    
    // Initialize _listingsFuture immediately to prevent LateInitializationError
    _listingsFuture = Future.value(<Listing>[]);
    
    _loadAllListings();
    _debugDatabaseContent();
  }

  // Load all listings once and cache them
  Future<void> _loadAllListings() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
  // Removed debug log
      final listings = await ListingService.fetchListings();
      setState(() {
        _allListings = listings;
        _listingsFuture = Future.value(listings);
        _isLoading = false;
      });
  // Removed debug log
    } catch (e) {
  // Suppressed debug print
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter cached listings with debounce to prevent rapid rebuilds
  void _filterListings() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 100), () {
      _performFiltering();
    });
  }
  
  void _performFiltering() {
    if (_isLoading) {
  // Removed debug log
      return;
    }
    
  // Removed debug log
    
    List<Listing> filtered = _allListings;

    if (selectedCategory != null) {
      filtered = filtered.where((listing) {
        return listing.category == selectedCategory!.id;
      }).toList();
    }

    if (selectedSubcategory != null) {
      filtered = filtered.where((listing) {
        return listing.subcategory == selectedSubcategory!.id;
      }).toList();
    }

  // Removed debug log

    if (mounted && !_isLoading) {
      setState(() {
        _listingsFuture = Future.value(filtered);
      });
    }
  }

  // Removed unused _refreshListings method

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
        flashsaleCountdownDuration = Duration(
          hours: 24 - DateTime.now().hour,
          minutes: 60 - DateTime.now().minute,
          seconds: 60 - DateTime.now().second,
        );
      });
    }
  }

  @override
  void dispose() {
    flashsaleCountdownTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColor.background,
      appBar: _buildAppBar(),
      drawer: HomeDrawer(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColor.primary,
      elevation: 2,
      shadowColor: AppColor.shadowColor,
      leading: IconButton(
        icon: Icon(Icons.menu, color: AppColor.textLight),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          AppLogoWidget(
            height: 24,
            width: 24,
            isWhiteVersion: true,
          ),
          SizedBox(width: 16),
          Expanded(
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Notifications coming soon!')),
            );
          },
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildCategorySection(),
            _buildListingsPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      width: double.infinity,
      color: AppColor.cardBackground,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 12),
          _buildCategoryList(),
          if (showSubcategories && selectedCategory != null) ...[
            SizedBox(height: 12),
            _buildSubcategoryList(),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: staticCategories.length,
        separatorBuilder: (context, index) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = staticCategories[index];
          final isSelected = selectedCategory?.id == cat.id;
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _onCategoryTap(cat, isSelected),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColor.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColor.primary : AppColor.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 18,
                      color: isSelected ? Colors.white : AppColor.primary,
                    ),
                    SizedBox(width: 4),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubcategoryList() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: selectedCategory!.subcategories.length,
        separatorBuilder: (context, index) => SizedBox(width: 6),
        itemBuilder: (context, index) {
          final subcat = selectedCategory!.subcategories[index];
          final isSelected = selectedSubcategory?.id == subcat.id;
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _onSubcategoryTap(subcat, isSelected),
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
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColor.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onCategoryTap(CategoryItem cat, bool isSelected) {
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
  }

  void _onSubcategoryTap(SubcategoryItem subcat, bool isSelected) {
    if (_isLoading) return;
    
    setState(() {
      if (isSelected) {
        selectedSubcategory = null;
      } else {
        selectedSubcategory = subcat;
      }
    });
    _filterListings();
  }

  Widget _buildListingsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Listings',
            style: TextStyle(
              color: AppColor.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 300,
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
                return Center(
                  child: Text(
                    'Error loading listings',
                    style: TextStyle(color: AppColor.error),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No listings found',
                    style: TextStyle(color: AppColor.textSecondary),
                  ),
                );
              }
              
              final listings = snapshot.data!;
              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: listings.length > 5 ? 5 : listings.length,
                itemBuilder: (context, index) {
                  final listing = listings[index];
                  return _buildListingCard(listing);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListingCard(Listing listing) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ListingDetailPage(listing: listing),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
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
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image,
                              size: 24,
                              color: AppColor.textSecondary,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.image,
                        size: 24,
                        color: AppColor.textSecondary,
                      ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      SizedBox(height: 4),
                      Text(
                        '\$${listing.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        listing.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary,
                        ),
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
}
