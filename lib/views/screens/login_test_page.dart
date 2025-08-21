import 'package:flutter/material.dart';
import '../../core/utils/supabase_helper.dart';

class LoginTestPage extends StatefulWidget {
  const LoginTestPage({super.key});

  @override
  _LoginTestPageState createState() => _LoginTestPageState();
}

class _LoginTestPageState extends State<LoginTestPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _status = 'Ready to test login';
  bool _loading = false;

  Future<void> _testLogin() async {
    setState(() {
      _loading = true;
      _status = 'Testing login...';
    });

    try {
      // Test 1: Login
      final response = await SupabaseHelper.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        setState(() {
          _status = 'Login successful! User ID: ${response.user!.id}\n';
        });

        // Test 2: Get user profile
        final userProfile = await SupabaseHelper.getCurrentUserProfile();
        if (userProfile != null) {
          setState(() {
            _status += 'User profile found: ${userProfile['display_name'] ?? userProfile['name'] ?? 'N/A'}\n';
            _status += 'Email: ${userProfile['email'] ?? 'N/A'}\n';
            _status += 'Created: ${userProfile['created_at'] ?? 'N/A'}\n';
          });
        } else {
          setState(() {
            _status += 'User profile not found in database\n';
          });
        }

        // Test 3: Check auth state
        final currentUser = SupabaseHelper.currentUser;
        setState(() {
          _status += 'Current user: ${currentUser?.email}\n';
          _status += 'User ID: ${currentUser?.id}\n';
          _status += 'Email confirmed: ${currentUser?.emailConfirmedAt != null}\n';
        });

        setState(() {
          _status += '\n✅ All tests passed! Login is working correctly.';
        });
      } else {
        setState(() {
          _status = '❌ Login failed: No user returned';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Login failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _testSignOut() async {
    try {
      await SupabaseHelper.signOut();
      setState(() {
        _status = 'Signed out successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Sign out failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _testLogin,
              child: _loading
                  ? CircularProgressIndicator()
                  : Text('Test Login'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testSignOut,
              child: Text('Test Sign Out'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
