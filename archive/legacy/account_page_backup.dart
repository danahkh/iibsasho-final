import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import 'home_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  File? _imageFile;
  Map<String, dynamic>? userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await SupabaseHelper.getCurrentUserProfile();
      setState(() {
        userData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      print('Error fetching user data: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
      // TODO: Upload to storage and update user photo_url
    }
  }

  Future<void> _changePassword() async {
    String? newPassword;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Change Password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(hintText: 'New Password'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                newPassword = controller.text;
                Navigator.of(context).pop();
              },
              child: Text('Change'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (newPassword != null && newPassword!.isNotEmpty) {
      try {
        await SupabaseHelper.client.auth.updateUser(
          UserAttributes(password: newPassword!),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating password: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          title: Text(
            'My Account',
            style: TextStyle(
              color: AppColor.textOnPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColor.primary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColor.iconLight),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(child: CircularProgressIndicator(color: AppColor.primary)),
      );
    }

    final user = SupabaseHelper.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          title: Text('My Account'),
          backgroundColor: AppColor.primary,
        ),
        body: Center(child: Text('Please log in to view your account')),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'My Account',
          style: TextStyle(
            color: AppColor.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColor.iconLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColor.primarySoft,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (userData?['photo_url'] != null && userData!['photo_url'] != ''
                                  ? NetworkImage(userData!['photo_url'])
                                  : null) as ImageProvider<Object>?,
                          child: _imageFile == null && (userData?['photo_url'] == null || userData!['photo_url'] == '')
                              ? Icon(Icons.person, size: 50, color: AppColor.iconLight)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColor.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppColor.iconLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    userData?['name'] ?? 'No Name',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textBlack,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    userData?['email'] ?? user.email ?? 'No Email',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColor.secondary,
                    ),
                  ),
                  if (userData?['phone_number'] != null && userData!['phone_number'].toString().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        userData!['phone_number'],
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColor.secondary,
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  Text(
                    'Tap photo to change',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColor.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Account Actions Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textBlack,
                      ),
                    ),
                  ),
                  _buildAccountOption(
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    subtitle: 'Update your profile information',
                    onTap: () => _showEditProfileDialog(),
                  ),
                  Divider(height: 1),
                  _buildAccountOption(
                    icon: Icons.lock,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: _changePassword,
                  ),
                  Divider(height: 1),
                  _buildAccountOption(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    onTap: _logout,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // App Info Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textBlack,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.store, color: AppColor.iconDark, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'iibsasho - Your marketplace app',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColor.secondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColor.iconDark, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColor.secondary,
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
    );
  }

  Widget _buildAccountOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.withOpacity(0.1) : AppColor.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : AppColor.iconDark,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : AppColor.textBlack,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColor.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColor.textMedium,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: userData?['name'] ?? '');
    final phoneController = TextEditingController(text: userData?['phone_number'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                hintText: '+252612345678',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await SupabaseHelper.upsertUserProfile({
                    'name': nameController.text,
                    'phone_number': phoneController.text,
                  });
                  
                  await _fetchUserData();
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile updated successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating profile: $e')),
                    );
                  }
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await SupabaseHelper.signOut();
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => HomePage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              }
            },
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
