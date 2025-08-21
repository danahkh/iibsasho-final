import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class CategoryService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all categories
  static Stream<List<Map<String, dynamic>>> getCategories() {
    return _supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) {
      return data.map((item) {
        return {
          'id': item['id'],
          'name': item['name'] ?? '',
          'icon': item['icon'] ?? '',
          'subcategories': List<String>.from(item['subcategories'] ?? []),
        };
      }).toList();
    });
  }

  /// Get all categories as a Future (for initial loading)
  static Future<List<Map<String, dynamic>>> getCategoriesOnce() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name');
      
      return response.map((item) {
        return {
          'id': item['id'],
          'name': item['name'] ?? '',
          'icon': item['icon'] ?? '',
          'subcategories': List<String>.from(item['subcategories'] ?? []),
        };
      }).toList();
    } catch (e) {
      AppLogger.e('Error getting categories once', e);
      return [];
    }
  }

  /// Initialize default categories
  static Future<void> initializeDefaultCategories() async {
    try {
  AppLogger.i('CategoryService: Starting category initialization...');
      
      // First, check if the categories table exists
      try {
  await _supabase.from('categories').select('id').limit(1);
  AppLogger.d('CategoryService: Categories table exists');
      } catch (e) {
  AppLogger.e('CategoryService: Categories table does not exist!');
  AppLogger.w('CategoryService: ERROR: You need to create the categories table in your Supabase dashboard first.');
  AppLogger.w('CategoryService: Please go to your Supabase dashboard > SQL Editor and run this SQL:');
  AppLogger.w('''
          CREATE TABLE public.categories (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            icon TEXT,
            subcategories TEXT[] DEFAULT '{}',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            is_active BOOLEAN DEFAULT TRUE,
            sort_order INTEGER DEFAULT 0
          );
        ''');
  AppLogger.w('CategoryService: After creating the table, restart the app.');
        throw Exception('Categories table does not exist. Please create it manually in Supabase dashboard.');
      }
      
      // Check if categories already exist
      final response = await _supabase.from('categories').select('id').limit(1);
      if (response.isNotEmpty) {
        AppLogger.i('CategoryService: Categories already exist (${response.length} found)');
        return;
      }

      AppLogger.i('CategoryService: No categories found, creating default categories...');
      // Default categories with subcategories
      final List<Map<String, dynamic>> defaultCategories = [
        {
          'name': 'Cars',
          'icon': 'directions_car',
          'subcategories': [
            'Sedan',
            'SUV',
            'Truck',
            'Heavy Vehicle',
            'Bus',
            'Motorcycle',
            'Spare Parts',
            'Car Services',
            'Car Rental',
            'Car Sale'
          ]
        },
        {
          'name': 'Real Estate',
          'icon': 'home_work',
          'subcategories': [
            'Apartments for Rent',
            'Villas for Rent',
            'Shops for Rent',
            'Farms for Rent',
            'Houses for Sale',
            'Buildings for Sale',
            'Commercial Land',
            'Residential Land',
            'Rest Houses',
            'Warehouses'
          ]
        },
        {
          'name': 'Electronics',
          'icon': 'devices_other',
          'subcategories': [
            'Mobiles & Phones',
            'Computers & Laptops',
            'Audio & Headphones',
            'Gaming',
            'Cameras',
            'TV & Home Theater',
            'Smart Home',
            'Accessories',
            'Kitchen Appliances',
            'Washing Machines'
          ]
        },
        {
          'name': 'Livestock & Animals',
          'icon': 'pets',
          'subcategories': [
            'Sheep',
            'Camels',
            'Horses',
            'Cows',
            'Goats',
            'Rabbits',
            'Dogs',
            'Cats',
            'Birds (parrots, pigeons)',
            'Fish',
            'Ducks',
            'Poultry (chickens, turkeys)'
          ]
        },
        {
          'name': 'Furniture',
          'icon': 'chair',
          'subcategories': [
            'Home Furniture',
            'Office Furniture',
            'Beds & Mattresses',
            'Cabinets & Cupboards',
            'Outdoor Furniture',
            'Antiques & Decor',
            'Home Appliances',
            'Kitchen Furniture',
            'Bathroom Furniture',
            'Garden Furniture'
          ]
        },
        {
          'name': 'Personal Supplies',
          'icon': 'checkroom',
          'subcategories': [
            'Men\'s Clothing',
            'Women\'s Clothing',
            'Children\'s Wear',
            'Shoes & Footwear',
            'Bags & Accessories',
            'Jewelry & Watches',
            'Eyewear',
            'Sporting Goods',
            'Perfumes & Cosmetics',
            'Traditional Clothing'
          ]
        },
        {
          'name': 'Services',
          'icon': 'miscellaneous_services',
          'subcategories': [
            'Tutoring & Education',
            'Home Services',
            'Professional Services',
            'Event Services',
            'Beauty & Wellness',
            'Pet Services',
            'Transportation',
            'Construction',
            'Healthcare',
            'Legal Services'
          ]
        },
        {
          'name': 'Agriculture',
          'icon': 'agriculture',
          'subcategories': [
            'Farming Equipment',
            'Seeds & Plants',
            'Fertilizers',
            'Irrigation Systems',
            'Harvesting Tools',
            'Animal Feed',
            'Greenhouse Supplies',
            'Agricultural Services'
          ]
        },
        {
          'name': 'Construction',
          'icon': 'construction',
          'subcategories': [
            'Building Materials',
            'Tools & Equipment',
            'Heavy Machinery',
            'Safety Equipment',
            'Electrical Supplies',
            'Plumbing Supplies',
            'Construction Services',
            'Architectural Services'
          ]
        },
        {
          'name': 'Other',
          'icon': 'category',
          'subcategories': [
            'Free Items',
            'Wanted',
            'Lost & Found',
            'Miscellaneous',
            'Collectibles',
            'Books & Media',
            'Toys & Games',
            'Antiques'
          ]
        }
      ];

      // Add categories to Supabase
      int successCount = 0;
      for (final category in defaultCategories) {
        try {
          await _supabase.from('categories').insert({
            ...category,
            'created_at': DateTime.now().toIso8601String(),
          });
          successCount++;
      AppLogger.d('CategoryService: Added category: ${category['name']}');
        } catch (e) {
      AppLogger.e('CategoryService: Error adding category ${category['name']}', e);
        }
      }
      
    AppLogger.i('CategoryService: Default categories initialization completed. Successfully added $successCount out of ${defaultCategories.length} categories');
      
      // Verify the categories were added
      try {
        final verifyResponse = await _supabase.from('categories').select('id, name').limit(5);
        AppLogger.d('CategoryService: Verification - found ${verifyResponse.length} categories in database');
        for (final cat in verifyResponse) {
          AppLogger.d('CategoryService: - ${cat['name']} (ID: ${cat['id']})');
        }
      } catch (e) {
        AppLogger.e('CategoryService: Error verifying categories', e);
      }
      
    } catch (e) {
      AppLogger.e('CategoryService: Critical error initializing categories', e, StackTrace.current);
    }
  }

  /// Get subcategories for a specific category
  static Future<List<String>> getSubcategories(String categoryName) async {
    try {
      final response = await _supabase
          .from('categories')
          .select('subcategories')
          .eq('name', categoryName)
          .limit(1)
          .maybeSingle();
      
      if (response != null) {
        return List<String>.from(response['subcategories'] ?? []);
      }
      
      return [];
    } catch (e) {
      AppLogger.e('Error getting subcategories', e);
      return [];
    }
  }

  /// Add a new category
  static Future<bool> addCategory({
    required String name,
    required String icon,
    List<String> subcategories = const [],
  }) async {
    try {
      await _supabase.from('categories').insert({
        'name': name,
        'icon': icon,
        'subcategories': subcategories,
        'created_at': DateTime.now().toIso8601String(),
      });
      
  AppLogger.i('Category added successfully: $name');
      return true;
    } catch (e) {
  AppLogger.e('Error adding category', e);
      return false;
    }
  }

  /// Update category subcategories
  static Future<bool> updateCategorySubcategories(String categoryId, List<String> subcategories) async {
    try {
      await _supabase.from('categories').update({
        'subcategories': subcategories,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', categoryId);
      
  AppLogger.i('Category subcategories updated successfully');
      return true;
    } catch (e) {
  AppLogger.e('Error updating category subcategories', e);
      return false;
    }
  }

  /// Get category statistics (listing counts)
  static Future<Map<String, int>> getCategoryStats() async {
    try {
      final Map<String, int> stats = {};
      
      // Get all active listings
      final response = await _supabase
          .from('listings')
          .select('category')
          .eq('status', 'active');
      
      // Count listings by category
      for (final item in response) {
        final category = item['category'] as String? ?? 'Other';
        stats[category] = (stats[category] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      AppLogger.e('Error getting category stats', e);
      return {};
    }
  }
}
