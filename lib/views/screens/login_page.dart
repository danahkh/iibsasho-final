import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import 'page_switcher.dart';
import 'register_page.dart';
import 'database_test_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    
  // Removed debug log
    
    try {
      final response = await SupabaseHelper.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
  // Removed debug log
      
      // Ensure user profile exists in users table
      final user = response.user;
      if (user != null) {
  // Removed debug log
        await SupabaseHelper.upsertUserProfile({
          'email': user.email,
        });
  // Removed debug log
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => PageSwitcher()));
      }
    } catch (e) {
  // Suppressed debug print
      setState(() { 
        _error = _getErrorMessage(e.toString());
      });
    } finally {
      setState(() { _loading = false; });
    }
  }
  
  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please check your credentials.';
    } else if (error.contains('Email not confirmed')) {
      return 'Please check your email and click the confirmation link.';
    } else if (error.contains('Too many requests')) {
      return 'Too many login attempts. Please try again later.';
    } else if (error.contains('Network')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.contains('your-project-url')) {
      return 'App configuration error. Please contact support.';
    }
    return 'Login failed. Please try again.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        title: Text('Sign in', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => RegisterPage()));
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColor.secondary.withOpacity(0.1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dont have an account?',
                style: TextStyle(
                  color: AppColor.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' Sign up',
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
                        Icons.waving_hand,
                        color: AppColor.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Welcome Back!',
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
                  Icons.shopping_bag_outlined,
                  color: AppColor.primary.withOpacity(0.7),
                  size: 20,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Ready to continue your amazing shopping journey? Let\'s get you signed in!',
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
          // Section 2 - Form
          // Email
          TextField(
            controller: _emailController,
            autofocus: false,
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
              hintText: '**********',
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
          // Forgot Passowrd
          Container(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColor.primary.withOpacity(0.1),
              ),
              child: Text(
                'Forgot Password ?',
                style: TextStyle(fontSize: 12, color: AppColor.textDark.withOpacity(0.5), fontWeight: FontWeight.w700),
              ),
            ),
          ),
          // Error message
          if (_error != null) ...[
            SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => DatabaseTestPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text('Debug Database', style: TextStyle(color: Colors.white)),
            ),
          ],
          // Sign In button
          ElevatedButton(
            onPressed: _loading ? null : _login,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18), backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Text(
              _loading ? 'Signing in...' : 'Sign in',
              style: TextStyle(color: AppColor.textLight, fontWeight: FontWeight.w600, fontSize: 18, fontFamily: 'poppins'),
            ),
          ),
        ],
      ),
    );
  }
}
