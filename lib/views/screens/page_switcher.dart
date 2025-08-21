import 'package:flutter/material.dart';
// Removed unused AppColor import; styling handled inside custom nav
import 'package:iibsasho/views/screens/home_page.dart';
import 'package:iibsasho/views/screens/favorites_page.dart';
import 'create_listing_page.dart';
import 'package:iibsasho/views/screens/chats_page.dart';
import 'package:iibsasho/views/screens/notification_page.dart';
import '../../core/utils/supabase_helper.dart';
import '../../widgets/custom_bottom_nav.dart';

class PageSwitcher extends StatefulWidget {
  const PageSwitcher({super.key});
  @override
  _PageSwitcherState createState() => _PageSwitcherState();
}

class _PageSwitcherState extends State<PageSwitcher> {
  int _selectedIndex = 4; // Start with Home page (index 4 after removing search tab)

  final List<Widget> _pages = [
    const ChatsPage(),                        // 0
    const NotificationPage(),                 // 1
    const CreateListingPage(listing: null),   // 2
    const FavoritesPage(),                    // 3
    HomePage(key: HomePage.globalKey),        // 4 home
  ];

  void _onItemTapped(int index) {
    // Handle authentication requirements for protected pages
  if (index == 0) { // Chat
      if (!SupabaseHelper.requireAuth(context, feature: 'chat')) {
        return;
      }
    } else if (index == 1) { // Notifications
      if (!SupabaseHelper.requireAuth(context, feature: 'notifications')) {
        return;
      }
    } else if (index == 2) { // Add listing
      if (!SupabaseHelper.requireAuth(context, feature: 'add listing')) {
        return;
      }
    } else if (index == 3) { // Favorites
      if (!SupabaseHelper.requireAuth(context, feature: 'view favorites')) {
        return;
      }
    }
  // Index 4 (Home) doesn't require authentication

  if (_selectedIndex == 4 && index == 4) {
      // Already on Home and tapped Home again (rare because nav item pushes parent handler)
      HomePage.globalKey.currentState?.refreshFromNav();
    }

  // If leaving Home, ensure drawer is closed
  if (_selectedIndex == 4 && index != 4) {
      // Leaving Home: aggressively close drawer
      HomePage.globalKey.currentState?.forceCloseDrawer();
    }

    setState(() {
      _selectedIndex = index;
    });
  if (index == 4) {
      // Whenever switching to Home (from another tab) refresh feed
      // Delay a frame to ensure state mounted after IndexedStack switch
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await HomePage.globalKey.currentState?.forceCloseDrawer();
        HomePage.globalKey.currentState?.refreshFromNav();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If not on Home tab, switch to Home instead of popping the route
    if (_selectedIndex != 4) {
          setState(() {
      _selectedIndex = 4;
          });
          return false; // consume back press
        }
        return true; // allow default back behavior (exit or pop)
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
