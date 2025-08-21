import 'package:flutter/material.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/model/user.dart';

class UserFixPage extends StatefulWidget {
  const UserFixPage({super.key});

  @override
  _UserFixPageState createState() => _UserFixPageState();
}

class _UserFixPageState extends State<UserFixPage> {
  String _status = 'Ready to fix user profile';
  bool _loading = false;

  Future<void> _fixCurrentUser() async {
    setState(() {
      _loading = true;
      _status = 'Checking current user...';
    });

    try {
      final currentUser = SupabaseAuthService.currentUser;
      if (currentUser == null) {
        setState(() {
          _status = '❌ No user is currently logged in';
        });
        return;
      }

      setState(() {
        _status = 'Current user ID: ${currentUser.id}\n';
        _status += 'Email: ${currentUser.email}\n';
        _status += 'Checking if profile exists...\n';
      });

      // Check if profile exists
      final profile = await DatabaseService.getUserById(currentUser.id);
      if (profile == null) {
        setState(() {
          _status += '❌ Profile not found in database\n';
          _status += 'Creating profile...\n';
        });

        // Create profile manually
        final success = await SupabaseAuthService.createUserProfile(
          email: currentUser.email ?? '',
          displayName: currentUser.userMetadata?['display_name'] ?? 
                      currentUser.email?.split('@')[0] ?? 'User',
        );

        setState(() {
          _status += '✅ Profile created successfully!\n';
        });

        // Test AppUser.fetchById
        final appUser = await AppUser.fetchById(currentUser.id);
        if (appUser != null) {
          setState(() {
            _status += '✅ AppUser.fetchById working!\n';
            _status += 'User name: ${appUser.name}\n';
            _status += 'User email: ${appUser.email}\n';
          });
        } else {
          setState(() {
            _status += '❌ AppUser.fetchById still not working\n';
          });
        }
      } else {
        setState(() {
          _status += '✅ Profile exists in database\n';
          _status += 'Name: ${profile['display_name']}\n';
          _status += 'Email: ${profile['email']}\n';
          _status += 'Created: ${profile['created_at']}\n';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
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
        title: Text('User Profile Fix'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _fixCurrentUser,
              child: _loading
                  ? CircularProgressIndicator()
                  : Text('Fix Current User Profile'),
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
}
