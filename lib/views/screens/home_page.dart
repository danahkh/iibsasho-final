import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constant/app_color.dart';
import '../../core/model/listing.dart';
import '../../core/services/listing_service.dart';
import 'search_page.dart';
import 'listings_list_page.dart';
import 'admin_panel_page.dart';
import '../../core/model/user.dart';
import '../../core/constant_categories.dart';
import '../widgets/dummy_search_widget_1.dart';
import '../widgets/search_bar_widget.dart';
import 'product_detail.dart';
import 'my_listings_page.dart';
import 'chats_page.dart';
import 'notification_page.dart';
import 'support_page.dart';
import 'account_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? flashsaleCountdownTimer;
  Duration flashsaleCountdownDuration = Duration(
    hours: 24 - DateTime.now().hour,
    minutes: 60 - DateTime.now().minute,
    seconds: 60 - DateTime.now().second,
  );

  final List<CategoryItem> staticCategories = AppCategories.categories;
  CategoryItem? selectedCategory;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Future<List<Listing>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    startTimer();
    selectedCategory = staticCategories.first;
    _listingsFuture = ListingService().fetchListings();
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
    setState(() {
      _listingsFuture = ListingService().fetchListings();
    });
  }

  Widget _buildListingsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Listings',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ListingsListPage(),
                    ),
                  );
                },
                child: Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 260,
          child: RefreshIndicator(
            onRefresh: _refreshListings,
            child: FutureBuilder<List<Listing>>(
              future: _listingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No listings found.'));
                }
                final listings = selectedCategory == null
                    ? snapshot.data!
                    : snapshot.data!.where((l) => l.category == selectedCategory!.name).toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: listings.length > 3 ? 3 : listings.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final listing = listings[index];
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

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings, color: AppColor.primary),
            onPressed: () async {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Not logged in')),
                );
                return;
              }
              final user = await AppUser.fetchById(currentUser.uid);
              if (user != null && user.role == 'admin') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AdminPanelPage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Admin access only')),
                );
              }
            },
            tooltip: 'Admin Panel',
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // Top section (optional user info or logo)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: SvgPicture.asset(
                  'assets/icons/iibsashologo.svg',
                  height: 32,
                  width: 32,
                ),
              ),
              ListTile(
                leading: Icon(Icons.list),
                title: Text('My Listings'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyListingsPage()));
                },
              ),
              ListTile(
                leading: Icon(Icons.chat),
                title: Text('Chats'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatsPage()));
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Notification'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => NotificationPage()));
                },
              ),
              ListTile(
                leading: Icon(Icons.support_agent),
                title: Text('Support'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => SupportPage()));
                },
              ),
              ListTile(
                leading: Icon(Icons.account_circle),
                title: Text('Account'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => AccountPage()));
                },
              ),
              Spacer(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        children: [
          // Section 1
          Container(
            height: 70, // Reduce height for a more compact look
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColor.primary, // Use a solid color for clarity
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/iibsashologo.svg',
                  height: 28,
                  width: 28,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _SearchBarWidget(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.notifications, color: Colors.white, size: 22),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => NotificationPage()));
                  },
                ),
              ],
            ),
          ),
          // Section 2 - category
          Container(
            width: MediaQuery.of(context).size.width,
            color: AppColor.secondary,
            padding: EdgeInsets.only(top: 12, bottom: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Static category bar with icons
                Container(
                  margin: EdgeInsets.only(top: 8),
                  height: 48,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    itemCount: staticCategories.length,
                    physics: BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    separatorBuilder: (context, index) => SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = staticCategories[index];
                      final isSelected = selectedCategory?.name == cat.name;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedCategory = null; // Remove filter if same category is clicked
                            } else {
                              selectedCategory = cat;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColor.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? AppColor.primary : AppColor.border),
                          ),
                          child: Row(
                            children: [
                              Icon(cat.icon, size: 18, color: isSelected ? Colors.white : AppColor.primary),
                              const SizedBox(width: 4),
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
              ],
            ),
          ),

          // Section 3 - banner
          // Container(
          //   height: 106,
          //   padding: EdgeInsets.symmetric(vertical: 16),
          //   child: ListView.separated(
          //     padding: EdgeInsets.symmetric(horizontal: 16),
          //     scrollDirection: Axis.horizontal,
          //     itemCount: 3,
          //     separatorBuilder: (context, index) {
          //       return SizedBox(width: 16);
          //     },
          //     itemBuilder: (context, index) {
          //       return Container(
          //         width: 230,
          //         height: 106,
          //         decoration: BoxDecoration(color: AppColor.primarySoft, borderRadius: BorderRadius.circular(15)),
          //       );
          //     },
          //   ),
          // ),
          // Add Listings section
          _buildListingsPreview(),
        ],
      ),
    );
  }
}

class _SearchBarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        // controller: searchController,
        // onChanged: onSearchTextChanged,
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          suffixIcon: IconButton(
            icon: Icon(Icons.search, color: AppColor.primary),
            onPressed: () {
              // Perform search action
            },
          ),
        ),
      ),
    );
  }
}
