import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import '../../core/services/listing_service.dart';
import '../../core/model/listing.dart';
import '../../core/constant_categories.dart';

class DatabaseDebugPage extends StatefulWidget {
  const DatabaseDebugPage({super.key});

  @override
  State<DatabaseDebugPage> createState() => _DatabaseDebugPageState();
}

class _DatabaseDebugPageState extends State<DatabaseDebugPage> {
  String _log = '';
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _log += '[${DateTime.now().toString().substring(11, 19)}] $message\n';
    });
    print(message);
  }

  Future<void> _runDatabaseTests() async {
    setState(() {
      _isLoading = true;
      _log = '';
    });

    try {
      _addLog('=== STARTING DATABASE TESTS ===');
      
      // Test 1: Connection
      _addLog('1. Testing Supabase connection...');
      final client = SupabaseHelper.client;
      _addLog('✅ Supabase client initialized');

      // Test 2: Authentication
      _addLog('2. Testing authentication...');
      final user = client.auth.currentUser;
      if (user != null) {
        _addLog('✅ User authenticated: ${user.email}');
      } else {
        _addLog('❌ No authenticated user');
        return;
      }

      // Test 3: Check tables exist
      _addLog('3. Testing table access...');
      
      // Test users table
      try {
        final userResult = await client.from('users').select('id').limit(1);
        _addLog('✅ Users table accessible (${userResult.length} records sample)');
      } catch (e) {
        _addLog('❌ Users table error: $e');
      }

      // Test listings table
      try {
        final listingsResult = await client.from('listings').select('id, title').limit(5);
        _addLog('✅ Listings table accessible (${listingsResult.length} records found)');
        if (listingsResult.isNotEmpty) {
          for (var listing in listingsResult) {
            _addLog('   - ${listing['title'] ?? 'Untitled'} (ID: ${listing['id']})');
          }
        } else {
          _addLog('   No listings found in database');
        }
      } catch (e) {
        _addLog('❌ Listings table error: $e');
      }

      // Test 4: ListingService
      _addLog('4. Testing ListingService...');
      try {
        final listings = await ListingService.fetchListings(limit: 3);
        _addLog('✅ ListingService.fetchListings() returned ${listings.length} listings');
        for (var listing in listings) {
          _addLog('   - ${listing.title} (\$${listing.price})');
        }
      } catch (e) {
        _addLog('❌ ListingService error: $e');
      }

      // Test 5: Categories
      _addLog('5. Testing categories...');
      _addLog('✅ ${AppCategories.categories.length} categories available:');
      for (var category in AppCategories.categories.take(3)) {
        _addLog('   - ${category.name} (${category.subcategories.length} subcategories)');
      }

      _addLog('=== TESTS COMPLETED ===');

    } catch (e) {
      _addLog('❌ Test failed with error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createSampleListing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('Creating sample listing...');
      
      final sampleListing = Listing(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Sample iPhone 15 Pro',
        description: 'Brand new iPhone 15 Pro in excellent condition. Comes with original box and accessories.',
        price: 999.99,
        category: 'electronics',
        subcategory: 'smartphones',
        location: 'New York, NY',
        latitude: 40.7128,
        longitude: -74.0060,
        images: ['https://via.placeholder.com/400x300/4A90E2/FFFFFF?text=iPhone+15+Pro'],
        videos: [],
        condition: 'new',
        userId: SupabaseHelper.currentUser!.id,
        userName: SupabaseHelper.currentUser!.email ?? 'Unknown User',
        userEmail: SupabaseHelper.currentUser!.email ?? '',
        userPhotoUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        viewCount: 0,
        isFeatured: false,
      );

      final listingId = await ListingService.createListing(sampleListing);
      
      if (listingId != null) {
        _addLog('✅ Sample listing created with ID: $listingId');
      } else {
        _addLog('❌ Failed to create sample listing');
      }

    } catch (e) {
      _addLog('❌ Error creating sample listing: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text('Database Debug'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runDatabaseTests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Testing...'),
                            ],
                          )
                        : const Text('Run Database Tests'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createSampleListing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.secondary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create Sample Listing'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Debug Log:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColor.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.isEmpty ? 'Click "Run Database Tests" to start debugging...' : _log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.green,
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
