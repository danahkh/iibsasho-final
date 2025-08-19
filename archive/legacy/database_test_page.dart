import 'package:flutter/material.dart';
import '../../core/utils/supabase_helper.dart';
import '../../constant/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseTestPage extends StatefulWidget {
  const DatabaseTestPage({super.key});

  @override
  _DatabaseTestPageState createState() => _DatabaseTestPageState();
}

class _DatabaseTestPageState extends State<DatabaseTestPage> {
  String _testResults = '';
  bool _testing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Test'),
        backgroundColor: AppColor.primary,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _testing ? null : _runTests,
              child: Text(_testing ? 'Testing...' : 'Run Database Tests'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults,
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

  Future<void> _runTests() async {
    setState(() {
      _testing = true;
      _testResults = 'Starting database tests...\n\n';
    });

    await _addResult('=== SUPABASE CONNECTION TEST ===');
    
    try {
      // Test 1: Check if Supabase is initialized
      final client = Supabase.instance.client;
      await _addResult('✓ Supabase client initialized');
      
      // Test 2: Check current user
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        await _addResult('✓ Current user: ${currentUser.email}');
        await _addResult('  User ID: ${currentUser.id}');
      } else {
        await _addResult('✗ No current user authenticated');
      }
      
      // Test 3: Test basic database connection
      await _addResult('\n=== DATABASE CONNECTION TEST ===');
      try {
        final response = await client.from('users').select('count').count();
        await _addResult('✓ Database connection successful');
        await _addResult('  Users table count: $response');
      } catch (e) {
        await _addResult('✗ Database connection failed: $e');
      }
      
      // Test 4: Check users table structure
      await _addResult('\n=== USERS TABLE STRUCTURE TEST ===');
      try {
        final response = await client.from('users').select().limit(1);
        if (response.isEmpty) {
          await _addResult('✓ Users table exists but is empty');
        } else {
          await _addResult('✓ Users table structure:');
          final firstUser = response.first;
          for (String key in firstUser.keys) {
            await _addResult('  - $key: ${firstUser[key].runtimeType}');
          }
        }
      } catch (e) {
        await _addResult('✗ Error checking users table: $e');
      }
      
      // Test 5: If user is logged in, test profile operations
      if (currentUser != null) {
        await _addResult('\n=== USER PROFILE TEST ===');
        try {
          // Try to get current user profile
          final profile = await SupabaseHelper.getCurrentUserProfile();
          if (profile != null) {
            await _addResult('✓ User profile found:');
            for (String key in profile.keys) {
              await _addResult('  - $key: ${profile[key]}');
            }
          } else {
            await _addResult('✗ User profile not found');
            
            // Try to create user profile
            await _addResult('Attempting to create user profile...');
            try {
              await SupabaseHelper.upsertUserProfile({
                'email': currentUser.email,
                'name': currentUser.email?.split('@')[0] ?? 'User',
                'role': 'user',
              });
              await _addResult('✓ User profile created successfully');
              
              // Try to get it again
              final newProfile = await SupabaseHelper.getCurrentUserProfile();
              if (newProfile != null) {
                await _addResult('✓ Profile verification successful');
              } else {
                await _addResult('✗ Profile creation verification failed');
              }
            } catch (e) {
              await _addResult('✗ Failed to create user profile: $e');
            }
          }
        } catch (e) {
          await _addResult('✗ Error in profile test: $e');
        }
      }
      
      await _addResult('\n=== TESTS COMPLETED ===');
      
    } catch (e) {
      await _addResult('✗ Critical error: $e');
    }
    
    setState(() {
      _testing = false;
    });
  }

  Future<void> _addResult(String message) async {
    setState(() {
      _testResults += '$message\n';
    });
    // Small delay to make the output visible
    await Future.delayed(Duration(milliseconds: 100));
  }
}
