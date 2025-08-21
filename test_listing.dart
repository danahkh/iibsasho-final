// Quick test script to check database categories
// Run this with: dart test_listing.dart

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final supabase = Supabase.instance.client;

  try {
    // Check what categories exist in the database
    print('=== CHECKING DATABASE CATEGORIES ===');
    final response = await supabase.from('listings').select('category, subcategory, title');
    
    print('Total listings found: ${response.length}');
    
    // Group by category
    Map<String, List<String>> categoryMap = {};
    
    for (var item in response) {
      String category = item['category'] ?? 'null';
      String subcategory = item['subcategory'] ?? 'null';
      String title = item['title'] ?? 'untitled';
      
      if (!categoryMap.containsKey(category)) {
        categoryMap[category] = [];
      }
      if (!categoryMap[category]!.contains(subcategory)) {
        categoryMap[category]!.add(subcategory);
      }
      
      print('Title: $title, Category: $category, Subcategory: $subcategory');
    }
    
    print('\n=== CATEGORY SUMMARY ===');
    categoryMap.forEach((category, subcategories) {
      print('Category: $category');
      print('  Subcategories: ${subcategories.join(', ')}');
    });
    
    // Check if we need to insert a test listing
    if (response.isEmpty) {
      print('\n=== INSERTING TEST LISTING ===');
      await supabase.from('listings').insert({
        'title': 'Test Cat for Sale',
        'description': 'A beautiful Persian cat looking for a new home',
        'price': 200.0,
        'category': 'livestock',
        'subcategory': 'cats',
        'location': 'Test City',
        'user_id': 'test-user-id',
        'seller_name': 'Test Seller',
        'seller_email': 'test@example.com',
        'images': ['https://example.com/cat.jpg'],
        'currency': 'USD',
        'is_active': true,
      });
      print('Test listing inserted!');
    }
    
  } catch (e) {
    print('Error: $e');
  }
}
