import 'package:flutter/material.dart';
import '../../core/utils/supabase_helper.dart';
import '../../constant/app_color.dart';

class SupabaseTestPage extends StatefulWidget {
  const SupabaseTestPage({super.key});

  @override
  State<SupabaseTestPage> createState() => _SupabaseTestPageState();
}

class _SupabaseTestPageState extends State<SupabaseTestPage> {
  String _status = 'Ready to test Supabase connection';
  bool _loading = false;

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _status = 'Testing Supabase connection...';
    });

    try {
      // Test 1: Check if Supabase is initialized
      final client = SupabaseHelper.client;
      setState(() {
        _status += '\n✅ Supabase client initialized';
      });

      // Test 2: Try to fetch from a simple table (you can modify table name)
      try {
        final result = await client.from('users').select('id').limit(1);
        setState(() {
          _status += '\n✅ Database connection successful';
          _status += '\n✅ Users table accessible';
        });
      } catch (e) {
        setState(() {
          _status += '\n❌ Database connection failed: $e';
        });
      }

      // Test 3: Check auth state
      final currentUser = SupabaseHelper.currentUser;
      setState(() {
        if (currentUser != null) {
          _status += '\n✅ User is authenticated: ${currentUser.email}';
        } else {
          _status += '\n⚠️ No user currently authenticated';
        }
      });

      // Test 4: Test auth endpoint
      try {
        await client.auth.signInWithPassword(
          email: 'test@invalid.com',
          password: 'invalid',
        );
      } catch (e) {
        if (e.toString().contains('Invalid login credentials')) {
          setState(() {
            _status += '\n✅ Auth endpoint working (invalid credentials test)';
          });
        } else {
          setState(() {
            _status += '\n❌ Auth endpoint error: $e';
          });
        }
      }

    } catch (e) {
      setState(() {
        _status += '\n❌ Connection test failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Supabase Connection Test'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Use this page to test your Supabase configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.textDark,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Test Supabase Connection'),
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
            SizedBox(height: 16),
            Text(
              'Configuration Check:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColor.textDark,
              ),
            ),
            Text(
              '• Make sure you\'ve updated the Supabase URL and anon key in main.dart\n'
              '• Check that your Supabase project has the required tables\n'
              '• Verify that authentication is enabled in your Supabase dashboard',
              style: TextStyle(
                fontSize: 12,
                color: AppColor.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
