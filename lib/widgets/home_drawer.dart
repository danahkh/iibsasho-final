import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import '../views/screens/my_listings_page.dart';
import '../views/screens/chats_page.dart';
import '../views/screens/notification_page.dart';
import '../views/screens/support_page.dart';
import '../views/screens/account_page.dart';
import '../views/screens/login_page.dart';
import '../views/screens/admin_dashboard_page.dart';
import '../views/screens/requests_page.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  bool _checkedAdmin = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final isAdmin = await SupabaseHelper.isCurrentUserAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _checkedAdmin = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseHelper.currentUser;
    
    if (currentUser == null) {
      // Non-authenticated users: Show blue/white sections with centered login box
      return Drawer(
        backgroundColor: AppColor.background,
        child: Column(
          children: [
            // Blue section (top half)
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                color: AppColor.primary,
                child: SafeArea(
                  bottom: false,
                  child: Container(),
                ),
              ),
            ),
            // Login box positioned in the middle
            Container(
              transform: Matrix4.translationValues(0, -60, 0),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.shadowColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColor.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.login,
                      color: AppColor.primary,
                      size: 32,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Please log in',
                      style: TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to login page
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // White section (bottom half)
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: Container(
                  margin: EdgeInsets.only(top: 60), // Account for the overlapping box
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Authenticated users: Show full drawer
    return Drawer(
      backgroundColor: AppColor.background,
      child: Column(
        children: [
          // Header container
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16, 
              bottom: 16, 
              left: 12, 
              right: 12
            ),
            decoration: BoxDecoration(
              color: AppColor.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColor.shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: SupabaseHelper.getCurrentUserProfile(),
                builder: (context, snapshot) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Profile image with fallback
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              backgroundImage: snapshot.data?['profile_image_url'] != null 
                                  ? NetworkImage(snapshot.data!['profile_image_url']) 
                                  : null,
                              child: snapshot.data?['profile_image_url'] == null 
                                  ? Icon(
                                      Icons.person,
                                      color: AppColor.textLight,
                                      size: 28,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    snapshot.data?['name'] ?? 
                                    snapshot.data?['display_name'] ??
                                    currentUser.email?.split('@')[0] ?? 
                                    'User',
                                    style: TextStyle(
                                      color: AppColor.textLight,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    currentUser.email ?? 'No email',
                                    style: TextStyle(
                                      color: AppColor.textLight.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // Add bio if available
                                  if (snapshot.data?['bio'] != null && 
                                      snapshot.data!['bio'].toString().isNotEmpty) ...[
                                    SizedBox(height: 2),
                                    Text(
                                      snapshot.data!['bio'],
                                      style: TextStyle(
                                        color: AppColor.textLight.withOpacity(0.7),
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ],
                                  // Add member since date if available
                                  if (snapshot.data?['created_at'] != null) ...[
                                    SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: AppColor.textLight.withOpacity(0.7),
                                          size: 12,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Member since ${DateTime.parse(snapshot.data!['created_at']).year}',
                                            style: TextStyle(
                                              color: AppColor.textLight.withOpacity(0.7),
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  // Add location if available
                                  if (snapshot.data?['location'] != null && 
                                      snapshot.data!['location'].toString().isNotEmpty) ...[
                                    SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: AppColor.textLight.withOpacity(0.7),
                                          size: 12,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            snapshot.data!['location'],
                                            style: TextStyle(
                                              color: AppColor.textLight.withOpacity(0.7),
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  // Add phone if available
                                  if (snapshot.data?['phone_number'] != null && 
                                      snapshot.data!['phone_number'].toString().isNotEmpty) ...[
                                    SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          color: AppColor.textLight.withOpacity(0.7),
                                          size: 12,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            snapshot.data!['phone_number'],
                                            style: TextStyle(
                                              color: AppColor.textLight.withOpacity(0.7),
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (_checkedAdmin && _isAdmin)
                  ListTile(
                    leading: Icon(Icons.dashboard_customize, color: AppColor.iconPrimary),
                    title: Text('Admin Dashboard', style: TextStyle(color: AppColor.textPrimary, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.list, color: AppColor.iconPrimary),
                  title: Text('My Listings', style: TextStyle(color: AppColor.textPrimary)),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyListingsPage()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.chat, color: AppColor.iconPrimary),
                  title: Text('Chats', style: TextStyle(color: AppColor.textPrimary)),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatsPage()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.notifications, color: AppColor.iconPrimary),
                  title: Text('Notification', style: TextStyle(color: AppColor.textPrimary)),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => NotificationPage()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.support_agent, color: AppColor.iconPrimary),
                  title: Text('Support', style: TextStyle(color: AppColor.textPrimary)),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => SupportPage()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.campaign, color: AppColor.iconPrimary),
                  title: Text('Promotion Requests', style: TextStyle(color: AppColor.textPrimary)),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RequestsPage()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.account_circle, color: AppColor.iconPrimary),
                  title: Text('Account', style: TextStyle(color: AppColor.textPrimary)),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => AccountPage()));
                  },
                ),
              ],
            ),
          ),
          // Logout at bottom
          ListTile(
            leading: Icon(Icons.logout, color: AppColor.error),
            title: Text('Logout', style: TextStyle(color: AppColor.error)),
            onTap: () async {
              await SupabaseHelper.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}
