import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import '../../core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  User? user;
  Map<String, dynamic>? userData;
  bool _loading = true;
  XFile? _imageFile; // Use XFile instead of File for web compatibility

  @override
  void initState() {
    super.initState();
    user = SupabaseHelper.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;
    final data = await SupabaseHelper.getCurrentUserProfile();
    setState(() {
      userData = data;
      _loading = false;
    });
  }

  Future<void> _changePassword() async {
    // You can use showDialog to prompt for new password
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
      await SupabaseHelper.client.auth.updateUser(
        UserAttributes(password: newPassword!),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password updated.')));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = picked; // Directly use XFile
      });
    }
  }

  // Helper function to get ImageProvider from XFile
  Future<ImageProvider?> _getImageProvider() async {
    if (_imageFile != null) {
      if (kIsWeb) {
        final bytes = await _imageFile!.readAsBytes();
        return MemoryImage(bytes);
      } else {
        return FileImage(File(_imageFile!.path));
      }
    }
    if (userData!['profile_image_url'] != null && userData!['profile_image_url'] != '') {
      return NetworkImage(userData!['profile_image_url']);
    }
    return null;
  }

  Future<String?> _uploadProfileImage(XFile imageFile) async {
    try {
      final user = SupabaseHelper.currentUser;
      if (user == null) return null;
      
      final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Get bytes from XFile for web compatibility
      final bytes = await imageFile.readAsBytes();
      
      // Try uploading to listings bucket (which is confirmed to work)
      String? imageUrl;
      try {
        await SupabaseHelper.client.storage
            .from('listings')
            .uploadBinary(fileName, bytes);
        imageUrl = SupabaseHelper.client.storage
            .from('listings')
            .getPublicUrl(fileName);
  AppLogger.i('Profile image uploaded to listings bucket');
        return imageUrl;
      } catch (e) {
        AppLogger.w('Failed to upload to listings bucket: $e');
        
        // Try creating avatars bucket if it doesn't exist
        try {
          await SupabaseHelper.client.storage
              .from('avatars')
              .uploadBinary(fileName, bytes);
          imageUrl = SupabaseHelper.client.storage
              .from('avatars')
              .getPublicUrl(fileName);
          AppLogger.i('Profile image uploaded to avatars bucket');
          return imageUrl;
        } catch (e2) {
          AppLogger.e('Failed to upload to avatars bucket', e2);
          throw Exception('Failed to upload profile image to any available bucket');
        }
      }
    } catch (e) {
      AppLogger.e('Profile image upload failed', e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          backgroundColor: AppColor.primary,
          elevation: 2,
          shadowColor: AppColor.shadowColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColor.textLight),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/iibsasho_white.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(AppColor.textLight, BlendMode.srcIn),
              ),
              SizedBox(width: 12),
              Text(
                'Account',
                style: TextStyle(
                  color: AppColor.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColor.primary),
              SizedBox(height: 16),
              Text(
                'Loading account information...',
                style: TextStyle(color: AppColor.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    
    if (userData == null) {
      return Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          backgroundColor: AppColor.primary,
          elevation: 2,
          shadowColor: AppColor.shadowColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColor.textLight),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/iibsasho_white.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(AppColor.textLight, BlendMode.srcIn),
              ),
              SizedBox(width: 12),
              Text(
                'Account',
                style: TextStyle(
                  color: AppColor.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: AppColor.error),
              SizedBox(height: 16),
              Text(
                'Unable to load account data',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColor.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _fetchUserData(),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        elevation: 2,
        shadowColor: AppColor.shadowColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColor.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/iibsasho_white.svg',
              height: 24,
              width: 24,
              colorFilter: ColorFilter.mode(AppColor.textLight, BlendMode.srcIn),
            ),
            SizedBox(width: 12),
            Text(
              'Account',
              style: TextStyle(
                color: AppColor.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: AppColor.textLight),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColor.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.shadowColor,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile picture
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        FutureBuilder<ImageProvider?>(
                          future: _getImageProvider(),
                          builder: (context, snapshot) {
                            return CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColor.primary.withOpacity(0.1),
                              backgroundImage: snapshot.data,
                              child: snapshot.data == null
                                  ? Icon(Icons.person, size: 50, color: AppColor.primary)
                                  : null,
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColor.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColor.background, width: 2),
                            ),
                            child: Icon(Icons.camera_alt, color: AppColor.textLight, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // User info
                  Text(
                    userData!['display_name'] ?? 'Unknown User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    userData!['email'] ?? user?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  // Location display removed as field doesn't exist in database
                  SizedBox(height: 8),
                  // Verification status
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: user?.emailConfirmedAt != null 
                          ? AppColor.success.withOpacity(0.1)
                          : AppColor.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: user?.emailConfirmedAt != null 
                            ? AppColor.success 
                            : AppColor.warning,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user?.emailConfirmedAt != null 
                              ? Icons.verified 
                              : Icons.pending,
                          size: 16,
                          color: user?.emailConfirmedAt != null 
                              ? AppColor.success 
                              : AppColor.warning,
                        ),
                        SizedBox(width: 4),
                        Text(
                          user?.emailConfirmedAt != null 
                              ? 'Verified' 
                              : 'Pending Verification',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: user?.emailConfirmedAt != null 
                                ? AppColor.success 
                                : AppColor.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Account settings
            _buildSettingsSection(),
            
            SizedBox(height: 24),
            
            // Account actions
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
        boxShadow: [
          BoxShadow(
            color: AppColor.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
          ),
          _buildSettingItem(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () => _showEditProfileDialog(),
          ),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () => _changePassword(),
          ),
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Notification Settings',
            subtitle: 'Manage your notification preferences',
            onTap: () => _showNotificationSettings(),
          ),
          _buildSettingItem(
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Control your privacy settings',
            onTap: () => _showPrivacySettings(),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
        boxShadow: [
          BoxShadow(
            color: AppColor.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Account Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
          ),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help or contact support',
            onTap: () => Navigator.pushNamed(context, '/support'),
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () => _showAboutDialog(),
          ),
          _buildSettingItem(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            textColor: AppColor.error,
            onTap: () => _showLogoutDialog(),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (textColor ?? AppColor.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: textColor ?? AppColor.primary,
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
                          color: textColor ?? AppColor.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColor.iconSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: AppColor.divider,
            indent: 60,
          ),
      ],
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: userData!['display_name'] ?? '');
    // Removed location controller as location field doesn't exist in database
    final emailController = TextEditingController(text: userData!['email'] ?? user?.email ?? '');
    final phoneController = TextEditingController(text: userData!['phone_number'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.cardBackground,
        title: Text('Edit Profile', style: TextStyle(color: AppColor.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Picture Section
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    FutureBuilder<ImageProvider?>(
                      future: _getImageProvider(),
                      builder: (context, snapshot) {
                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColor.primary.withOpacity(0.1),
                          backgroundImage: snapshot.data,
                          child: snapshot.data == null
                              ? Icon(Icons.person, size: 40, color: AppColor.primary)
                              : null,
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColor.background, width: 2),
                        ),
                        child: Icon(Icons.camera_alt, color: AppColor.textLight, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              // Name Field (Editable)
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Display Name *',
                  labelStyle: TextStyle(color: AppColor.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.primary),
                  ),
                ),
                style: TextStyle(color: AppColor.textPrimary),
              ),
              SizedBox(height: 16),
              
              // Location field removed as it doesn't exist in database
              
              // Email Field (Read-only)
              TextField(
                controller: emailController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email (Read-only)',
                  labelStyle: TextStyle(color: AppColor.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.border.withOpacity(0.5)),
                  ),
                  filled: true,
                  fillColor: AppColor.background.withOpacity(0.5),
                ),
                style: TextStyle(color: AppColor.textSecondary),
              ),
              SizedBox(height: 16),
              
              // Phone Number Field (Read-only)
              TextField(
                controller: phoneController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Read-only)',
                  labelStyle: TextStyle(color: AppColor.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.border.withOpacity(0.5)),
                  ),
                  filled: true,
                  fillColor: AppColor.background.withOpacity(0.5),
                ),
                style: TextStyle(color: AppColor.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate required fields
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Name is required'),
                    backgroundColor: AppColor.error,
                  ),
                );
                return;
              }
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(color: AppColor.primary),
                ),
              );
              
              // Prepare update data
              Map<String, dynamic> updateData = {
                'display_name': nameController.text.trim(),
                // Removed location field as it doesn't exist in database
              };
              
              // Handle profile picture upload if changed
              String? uploadError;
              bool imageUploadSucceeded = true;
              
              if (_imageFile != null) {
                AppLogger.d('Attempting profile image upload');
                final uploadedImageUrl = await _uploadProfileImage(_imageFile!);
                if (uploadedImageUrl != null) {
                  updateData['profile_image_url'] = uploadedImageUrl;
                  AppLogger.i('Profile image upload successful');
                } else {
                  uploadError = 'Image upload failed, but profile info was updated';
                  imageUploadSucceeded = false;
                  AppLogger.w('Profile image upload failed');
                }
              }
              
              // Always attempt to update profile data (even if image fails)
              AppLogger.d('Updating profile data: $updateData');
              final success = await SupabaseHelper.updateUserProfile(updateData);
              
              // Hide loading indicator
              Navigator.pop(context);
              
              if (success) {
                // Only clear image file if upload succeeded or no image was selected
                if (imageUploadSucceeded) {
                  setState(() {
                    _imageFile = null;
                  });
                }
                
                // Refresh user data
                await _fetchUserData();
                
                Navigator.pop(context);
                
                // Show success message with potential image warning
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(uploadError ?? 'Profile updated successfully'),
                    backgroundColor: uploadError != null ? Colors.orange : AppColor.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update profile. Please try again.'),
                    backgroundColor: AppColor.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.textLight,
            ),
            child: Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.cardBackground,
        title: Text('Notification Settings', style: TextStyle(color: AppColor.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Push Notifications', style: TextStyle(color: AppColor.textPrimary)),
              value: true,
              onChanged: (value) {},
              activeColor: AppColor.primary,
            ),
            SwitchListTile(
              title: Text('Email Notifications', style: TextStyle(color: AppColor.textPrimary)),
              value: false,
              onChanged: (value) {},
              activeColor: AppColor.primary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColor.primary)),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.cardBackground,
        title: Text('Privacy & Security', style: TextStyle(color: AppColor.textPrimary)),
        content: Text(
          'Privacy settings will be implemented here.',
          style: TextStyle(color: AppColor.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColor.primary)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.cardBackground,
        title: Text('About Iibsasho', style: TextStyle(color: AppColor.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/iibsasho_colored.svg',
              height: 60,
              width: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Iibsasho Marketplace',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: AppColor.textSecondary),
            ),
            SizedBox(height: 16),
            Text(
              'Your trusted marketplace for buying and selling items in your community.',
              style: TextStyle(color: AppColor.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColor.primary)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.cardBackground,
        title: Text('Sign Out', style: TextStyle(color: AppColor.textPrimary)),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColor.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseHelper.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: AppColor.textLight,
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
