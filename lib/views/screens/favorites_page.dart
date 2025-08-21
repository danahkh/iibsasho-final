import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/model/listing.dart';
import '../../core/utils/app_logger.dart';
import '../../core/services/favorite_service.dart';
import '../../core/utils/supabase_helper.dart';
import '../widgets/listing_card.dart';
import 'login_page.dart';
import 'product_detail.dart';
// Removed StandardScaffold to prevent double bottom nav inside PageSwitcher

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Listing> _favoriteListings = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh auth state and favorites when returning to this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAuthAndLoadFavorites();
      }
    });
  }

  Future<void> _checkAuthAndLoadFavorites() async {
    setState(() {
      _isAuthenticated = SupabaseHelper.isAuthenticated;
    });
    
    if (_isAuthenticated) {
      await _loadFavorites();
    } else {
      setState(() {
        _isLoading = false;
        _favoriteListings = [];
      });
    }
  }

  Future<void> _loadFavorites() async {
    if (!SupabaseHelper.isAuthenticated) {
      setState(() {
        _favoriteListings = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
  AppLogger.d('Loading favorites for user: ${SupabaseHelper.currentUserId}');
      final favorites = await FavoriteService.getUserFavoriteListings();
  AppLogger.d('Loaded ${favorites.length} favorite listings');
      
      setState(() {
        _favoriteListings = favorites;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error loading favorites', e);
      setState(() {
        _favoriteListings = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load favorites: ${e.toString()}'),
            backgroundColor: AppColor.error,
          ),
        );
      }
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign In Required'),
        content: Text('You need to sign in to view your favorites.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.textOnPrimary,
            ),
            child: Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build own content (PageSwitcher already supplies Scaffold & bottom nav)
    return Column(
      children: [
        // Custom top bar
        Container(
          height: kToolbarHeight + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(color: AppColor.primary, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
          child: Row(
            children: [
              SizedBox(width: 16),
              Text('Favorites', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              Spacer(),
              if (_isAuthenticated)
                IconButton(
                  onPressed: _loadFavorites,
                  icon: Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh',
                ),
            ],
          ),
        ),
        Expanded(
          child: !_isAuthenticated
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: AppColor.placeholder,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sign in to view your favorites',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textDark,
                    ),
                  ),
                  SizedBox(height: 8),                    Text(
                      'Save listings you like to easily find them later',
                      style: TextStyle(
                        color: AppColor.placeholder,
                      ),
                    ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _showLoginPrompt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.textOnPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text('Sign In'),
                  ),
                ],
              ),
            )
          : _isLoading
              ? Center(child: CircularProgressIndicator())
              : _favoriteListings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 80,
                            color: AppColor.placeholder,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No favorites yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start browsing and save listings you like',
                            style: TextStyle(
                              color: AppColor.placeholder,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _favoriteListings.length,
                        itemBuilder: (context, index) {
                          final listing = _favoriteListings[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: ListingCard(
                              listing: listing,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ListingDetailPage(listing: listing),
                                  ),
                                ).then((_) => _loadFavorites());
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
