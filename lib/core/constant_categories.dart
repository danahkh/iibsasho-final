/// Central static categories and icons for the app.
library;
import 'package:flutter/material.dart';

class AppCategories {
  static const List<CategoryItem> categories = [
    // 1. Cars
    CategoryItem(
      id: 'cars',
      name: 'Cars',
      icon: Icons.directions_car,
      subcategories: [
        SubcategoryItem(id: 'sedan', name: 'Sedan'),
        SubcategoryItem(id: 'truck', name: 'Truck'),
        SubcategoryItem(id: 'heavy_machines', name: 'Heavy Machines'),
        SubcategoryItem(id: 'sedan_rent', name: 'Sedan for Rent'),
        SubcategoryItem(id: 'truck_rent', name: 'Truck for Rent'),
        SubcategoryItem(id: 'heavy_machines_rent', name: 'Heavy Machines for Rent'),
      ],
    ),

    // 2. Real Estate
    CategoryItem(
      id: 'real_estate',
      name: 'Real Estate',
      icon: Icons.home_work,
      subcategories: [
        SubcategoryItem(id: 'apartments_rent', name: 'Apartments for Rent'),
        SubcategoryItem(id: 'villas_rent', name: 'Villas for Rent'),
        SubcategoryItem(id: 'shops_rent', name: 'Shops for Rent'),
        SubcategoryItem(id: 'farms_rent', name: 'Farms for Rent'),
        SubcategoryItem(id: 'houses_sale', name: 'Houses for Sale'),
        SubcategoryItem(id: 'buildings_sale', name: 'Buildings for Sale'),
        SubcategoryItem(id: 'commercial_land', name: 'Commercial Land'),
        SubcategoryItem(id: 'rest_houses', name: 'Rest Houses'),
      ],
    ),

    // 3. Electronics & Appliances
    CategoryItem(
      id: 'electronics',
      name: 'Electronics & Appliances',
      icon: Icons.devices_other,
      subcategories: [
        SubcategoryItem(id: 'mobiles', name: 'Mobiles'),
        SubcategoryItem(id: 'computers_tablets', name: 'Computers & Tablets'),
        SubcategoryItem(id: 'headphones', name: 'Headphones'),
        SubcategoryItem(id: 'refrigerators', name: 'Refrigerators'),
        SubcategoryItem(id: 'air_conditioners', name: 'Air Conditioners'),
        SubcategoryItem(id: 'electronic_games', name: 'Electronic Games'),
        SubcategoryItem(id: 'electronics_other', name: 'Other Electronics'),
      ],
    ),

    // 4. Livestock, Animals & Birds
    CategoryItem(
      id: 'Animals', // Changed to match database
      name: 'Livestock, Animals & Birds',
      icon: Icons.pets,
      subcategories: [
        SubcategoryItem(id: 'sheep', name: 'Sheep'),
        SubcategoryItem(id: 'camels', name: 'Camels'),
        SubcategoryItem(id: 'horses', name: 'Horses'),
        SubcategoryItem(id: 'cows', name: 'Cows'),
        SubcategoryItem(id: 'rabbits', name: 'Rabbits'),
        SubcategoryItem(id: 'dogs', name: 'Dogs'),
        SubcategoryItem(id: 'Cats', name: 'Cats'), // Changed to match database
        SubcategoryItem(id: 'birds', name: 'Birds (parrots, pigeons)'),
        SubcategoryItem(id: 'fish', name: 'Fish'),
        SubcategoryItem(id: 'ducks', name: 'Ducks'),
        SubcategoryItem(id: 'goats', name: 'Goats'),
      ],
    ),

    // 5. Furniture
    CategoryItem(
      id: 'furniture',
      name: 'Furniture',
      icon: Icons.chair,
      subcategories: [
        SubcategoryItem(id: 'home_furniture', name: 'Home Furniture'),
        SubcategoryItem(id: 'office_furniture', name: 'Office Furniture'),
        SubcategoryItem(id: 'beds_mattresses', name: 'Beds & Mattresses'),
        SubcategoryItem(id: 'cabinets_cupboards', name: 'Cabinets & Cupboards'),
        SubcategoryItem(id: 'outdoor_furniture', name: 'Outdoor Furniture'),
        SubcategoryItem(id: 'antiques_decor', name: 'Antiques & Decor'),
        SubcategoryItem(id: 'home_appliances', name: 'Home Appliances'),
      ],
    ),

    // 6. Personal Supplies
    CategoryItem(
      id: 'personal_supplies',
      name: 'Personal Supplies',
      icon: Icons.checkroom,
      subcategories: [
        SubcategoryItem(id: 'childrens_wear', name: 'Children\'s Wear'),
        SubcategoryItem(id: 'womens_wear', name: 'Women\'s Wear'),
        SubcategoryItem(id: 'mens_clothing', name: 'Men\'s Clothing'),
        SubcategoryItem(id: 'eyewear', name: 'Eyewear'),
        SubcategoryItem(id: 'sporting_goods', name: 'Sporting Goods'),
        SubcategoryItem(id: 'perfumes', name: 'Perfumes'),
        SubcategoryItem(id: 'watches', name: 'Watches'),
      ],
    ),

    // 7. Miscellaneous
    CategoryItem(
      id: 'miscellaneous',
      name: 'Miscellaneous',
      icon: Icons.category,
      subcategories: [
        SubcategoryItem(id: 'other_items', name: 'Other Items & Services'),
        SubcategoryItem(id: 'general_marketplace', name: 'General Marketplace Listings'),
        SubcategoryItem(id: 'services', name: 'Services'),
        SubcategoryItem(id: 'collectibles', name: 'Collectibles'),
        SubcategoryItem(id: 'tools', name: 'Tools & Equipment'),
        SubcategoryItem(id: 'books_media', name: 'Books & Media'),
      ],
    ),
  ];

  // Helper methods
  static CategoryItem? getCategoryById(String id) {
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  static SubcategoryItem? getSubcategoryById(String categoryId, String subcategoryId) {
    final category = getCategoryById(categoryId);
    if (category == null) return null;

    try {
      return category.subcategories.firstWhere((sub) => sub.id == subcategoryId);
    } catch (e) {
      return null;
    }
  }

  static List<String> getAllCategoryIds() {
    return categories.map((cat) => cat.id).toList();
  }

  static List<String> getAllSubcategoryIds(String categoryId) {
    final category = getCategoryById(categoryId);
    return category?.subcategories.map((sub) => sub.id).toList() ?? [];
  }
}

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final List<SubcategoryItem> subcategories;
  
  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.subcategories,
  });
}

class SubcategoryItem {
  final String id;
  final String name;
  
  const SubcategoryItem({
    required this.id,
    required this.name,
  });
}
