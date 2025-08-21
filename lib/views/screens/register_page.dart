import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import '../../core/utils/app_logger.dart';
import 'package:iibsasho/views/screens/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+252'; // Default to Somalia
  bool _loading = false;
  String? _error;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _countryCodes = [
    // Somalia (Default)
    {'code': '+252', 'country': 'Somalia'},
    
    // GCC Countries
    {'code': '+971', 'country': 'UAE'},
    {'code': '+966', 'country': 'Saudi Arabia'},
    {'code': '+973', 'country': 'Bahrain'},
    {'code': '+965', 'country': 'Kuwait'},
    {'code': '+974', 'country': 'Qatar'},
    {'code': '+968', 'country': 'Oman'},
    
    // African Countries
    {'code': '+251', 'country': 'Ethiopia'},
    {'code': '+254', 'country': 'Kenya'},
    {'code': '+256', 'country': 'Uganda'},
    {'code': '+255', 'country': 'Tanzania'},
    {'code': '+250', 'country': 'Rwanda'},
    {'code': '+253', 'country': 'Djibouti'},
    {'code': '+249', 'country': 'Sudan'},
    {'code': '+20', 'country': 'Egypt'},
    {'code': '+212', 'country': 'Morocco'},
    {'code': '+213', 'country': 'Algeria'},
    {'code': '+216', 'country': 'Tunisia'},
    {'code': '+218', 'country': 'Libya'},
    {'code': '+27', 'country': 'South Africa'},
    {'code': '+234', 'country': 'Nigeria'},
    {'code': '+233', 'country': 'Ghana'},
    
    // European Union
    {'code': '+49', 'country': 'Germany'},
    {'code': '+33', 'country': 'France'},
    {'code': '+39', 'country': 'Italy'},
    {'code': '+34', 'country': 'Spain'},
    {'code': '+31', 'country': 'Netherlands'},
    {'code': '+32', 'country': 'Belgium'},
    {'code': '+43', 'country': 'Austria'},
    {'code': '+41', 'country': 'Switzerland'},
    {'code': '+46', 'country': 'Sweden'},
    {'code': '+47', 'country': 'Norway'},
    {'code': '+45', 'country': 'Denmark'},
    {'code': '+358', 'country': 'Finland'},
    {'code': '+48', 'country': 'Poland'},
    {'code': '+420', 'country': 'Czech Republic'},
    {'code': '+36', 'country': 'Hungary'},
    {'code': '+30', 'country': 'Greece'},
    {'code': '+351', 'country': 'Portugal'},
    {'code': '+353', 'country': 'Ireland'},
    
    // UK
    {'code': '+44', 'country': 'United Kingdom'},
    
    // Americas
    {'code': '+1', 'country': 'US/Canada'},
    {'code': '+52', 'country': 'Mexico'},
    {'code': '+55', 'country': 'Brazil'},
    {'code': '+54', 'country': 'Argentina'},
    {'code': '+56', 'country': 'Chile'},
    {'code': '+57', 'country': 'Colombia'},
    {'code': '+51', 'country': 'Peru'},
    {'code': '+58', 'country': 'Venezuela'},
    
    // Asia Pacific
    {'code': '+86', 'country': 'China'},
    {'code': '+81', 'country': 'Japan'},
    {'code': '+82', 'country': 'South Korea'},
    {'code': '+91', 'country': 'India'},
    {'code': '+92', 'country': 'Pakistan'},
    {'code': '+880', 'country': 'Bangladesh'},
    {'code': '+94', 'country': 'Sri Lanka'},
    {'code': '+60', 'country': 'Malaysia'},
    {'code': '+65', 'country': 'Singapore'},
    {'code': '+66', 'country': 'Thailand'},
    {'code': '+84', 'country': 'Vietnam'},
    {'code': '+62', 'country': 'Indonesia'},
    {'code': '+63', 'country': 'Philippines'},
    {'code': '+61', 'country': 'Australia'},
    {'code': '+64', 'country': 'New Zealand'},
    
    // Turkey and Iran
    {'code': '+90', 'country': 'Turkey'},
    {'code': '+98', 'country': 'Iran'},
  ];

  Future<void> _signup() async {
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      setState(() { _error = 'Please enter your full name'; });
      return;
    }
    
    if (_phoneController.text.trim().isEmpty) {
      setState(() { _error = 'Please enter your phone number'; });
      return;
    }
    
    if (_emailController.text.trim().isEmpty) {
      setState(() { _error = 'Please enter your email'; });
      return;
    }
    
    if (_passwordController.text.trim().isEmpty) {
      setState(() { _error = 'Please enter a password'; });
      return;
    }

    setState(() { _loading = true; _error = null; });
    
  AppLogger.d('Attempting registration with email: ${_emailController.text.trim()}');
    
    try {
      final response = await SupabaseHelper.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
  AppLogger.d('Registration response user: ${response.user?.email}');
      
      final user = response.user;
      String? photoUrl;
      if (_imageFile != null) {
        // TODO: Upload image to storage and get URL
        // photoUrl = await uploadImage(_imageFile!);
      }
      
      if (user != null) {
  AppLogger.d('Creating user profile after registration');
        await SupabaseHelper.upsertUserProfile({
          'email': user.email,
          'name': _nameController.text.trim(),
          'phone': '$_selectedCountryCode${_phoneController.text.trim()}',
          'role': 'user',
          'photo_url': photoUrl ?? '',
        });
  AppLogger.i('Profile created successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration successful! Please check your email to verify your account.'),
              backgroundColor: AppColor.success,
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
      }
    } catch (e) {
      AppLogger.e('Registration error', e);
      setState(() { 
        _error = _getErrorMessage(e.toString());
      });
    } finally {
      setState(() { _loading = false; });
    }
  }
  
  String _getErrorMessage(String error) {
    if (error.contains('already registered')) {
      return 'This email is already registered. Please use a different email or try logging in.';
    } else if (error.contains('Password should be')) {
      return 'Password should be at least 6 characters long.';
    } else if (error.contains('Invalid email')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('Network')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.contains('your-project-url')) {
      return 'App configuration error. Please contact support.';
    }
    return 'Registration failed. Please try again.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final picked = await _picker.pickImage(source: ImageSource.gallery);
          if (picked != null) {
            setState(() {
              _imageFile = File(picked.path);
            });
          }
        },
        child: CircleAvatar(
          radius: 40,
          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
          child: _imageFile == null ? Icon(Icons.person, size: 40) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: AppColor.primary,
        elevation: 2,
        shadowColor: AppColor.shadowColor,
        title: Text('Sign up', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'iibsasho',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        height: 48,
        alignment: Alignment.center,
        child: TextButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginPage()));
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColor.secondary.withOpacity(0.1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: TextStyle(
                  color: AppColor.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' Sign in',
                style: TextStyle(
                  color: AppColor.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 24),
        physics: BouncingScrollPhysics(),
        children: [
          // Section 1 - Header with Logo
          Container(
            margin: EdgeInsets.only(top: 20, bottom: 20),
            child: Column(
              children: [
                // Logo
                Container(
                  margin: EdgeInsets.only(bottom: 32),
                  child: Text(
                    'iibsasho',
                    style: TextStyle(
                      color: AppColor.primary,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                      letterSpacing: -1.0,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: AppColor.primary.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Welcome message with icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.celebration,
                        color: AppColor.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Join Our Community!',
                      style: TextStyle(
                        color: AppColor.textDark,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.storefront,
                  color: AppColor.primary.withOpacity(0.7),
                  size: 20,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Join thousands of happy users! Create your account and discover amazing deals from local sellers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColor.textDark.withOpacity(0.7), 
                      fontSize: 14, 
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Section 2  - Form
          // Profile Picture
          _buildImagePicker(),
          SizedBox(height: 16),
          // Full Name
          TextField(
            controller: _nameController,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Full Name',
              hintStyle: TextStyle(color: AppColor.placeholder),
              prefixIcon: Container(
                padding: EdgeInsets.all(12),
                child: SvgPicture.asset('assets/icons/Profile.svg', color: AppColor.primary),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.border, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.primary, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              fillColor: AppColor.primarySoft,
              filled: true,
            ),
            style: TextStyle(color: AppColor.textBlack),
          ),
          SizedBox(height: 16),
          // Phone Number with Country Code
          Row(
            children: [
              // Country Code Dropdown
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<String>(
                  value: _selectedCountryCode,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.border, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.primary, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: AppColor.primarySoft,
                    filled: true,
                  ),
                  items: _countryCodes.map((country) {
                    return DropdownMenuItem<String>(
                      value: country['code'],
                      child: Text(
                        '${country['code']} ${country['country']}',
                        style: TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountryCode = value!;
                    });
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return _countryCodes.map<Widget>((country) {
                      return Text(
                        country['code']!,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      );
                    }).toList();
                  },
                ),
              ),
              SizedBox(width: 12),
              // Phone Number Field
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  autofocus: false,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Phone Number *',
                    hintStyle: TextStyle(color: AppColor.placeholder),
                    prefixIcon: Container(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.phone, color: AppColor.primary),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.border, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColor.primary, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: AppColor.primarySoft,
                    filled: true,
                  ),
                  style: TextStyle(color: AppColor.textBlack),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Username
          TextField(
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Username',
              hintStyle: TextStyle(color: AppColor.placeholder),
              prefixIcon: Container(
                padding: EdgeInsets.all(12),
                child: Text('@', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColor.primary)),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.border, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.primary, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              fillColor: AppColor.primarySoft,
              filled: true,
            ),
            style: TextStyle(color: AppColor.textBlack),
          ),
          SizedBox(height: 16),
          // Email
          TextField(
            controller: _emailController,
            autofocus: false,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'youremail@email.com',
              hintStyle: TextStyle(color: AppColor.placeholder),
              prefixIcon: Container(
                padding: EdgeInsets.all(12),
                child: SvgPicture.asset('assets/icons/Message.svg', color: AppColor.primary),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.border, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.primary, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              fillColor: AppColor.primarySoft,
              filled: true,
            ),
            style: TextStyle(color: AppColor.textBlack),
          ),
          SizedBox(height: 16),
          // Password
          TextField(
            controller: _passwordController,
            autofocus: false,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: AppColor.placeholder),
              prefixIcon: Container(
                padding: EdgeInsets.all(12),
                child: SvgPicture.asset('assets/icons/Lock.svg', color: AppColor.primary),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.border, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.primary, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              fillColor: AppColor.primarySoft,
              filled: true,
              //
              suffixIcon: IconButton(
                onPressed: () {},
                icon: SvgPicture.asset('assets/icons/Hide.svg', color: AppColor.primary),
              ),
            ),
            style: TextStyle(color: AppColor.textBlack),
          ),
          SizedBox(height: 16),
          // Repeat Password
          TextField(
            autofocus: false,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Repeat Password',
              hintStyle: TextStyle(color: AppColor.placeholder),
              prefixIcon: Container(
                padding: EdgeInsets.all(12),
                child: SvgPicture.asset('assets/icons/Lock.svg', color: AppColor.primary),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.border, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.primary, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              fillColor: AppColor.primarySoft,
              filled: true,
              //
              suffixIcon: IconButton(
                onPressed: () {},
                icon: SvgPicture.asset('assets/icons/Hide.svg', color: AppColor.primary),
              ),
            ),
            style: TextStyle(color: AppColor.textBlack),
          ),
          SizedBox(height: 24),
          // Sign Up Button
          ElevatedButton(
            onPressed: _loading ? null : _signup,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18), backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Text(
              _loading ? 'Signing up...' : 'Sign up',
              style: TextStyle(color: AppColor.textLight, fontWeight: FontWeight.w600, fontSize: 18, fontFamily: 'poppins'),
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.red)),
          ],
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'or continue with',
              style: TextStyle(fontSize: 12, color: AppColor.textDark.withOpacity(0.7)),
            ),
          ),
          // SIgn in With Google
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColor.primary, padding: EdgeInsets.symmetric(horizontal: 36, vertical: 12), backgroundColor: AppColor.primarySoft,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/Google.svg',
                ),
                Container(
                  margin: EdgeInsets.only(left: 16),
                  child: Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
