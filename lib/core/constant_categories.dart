/// Central static categories and icons for the app.
import 'package:flutter/material.dart';

class AppCategories {
  static const List<CategoryItem> categories = [
    CategoryItem(
      name: 'Cars',
      icon: Icons.directions_car,
      subcategories: ['Sedan', 'SUV', 'Truck', 'Motorcycle', 'Other'],
    ),
    CategoryItem(
      name: 'Real Estate',
      icon: Icons.home_work,
      subcategories: ['House', 'Apartment', 'Land', 'Commercial', 'Other'],
    ),
    CategoryItem(
      name: 'Electronics',
      icon: Icons.devices_other,
      subcategories: ['Phones', 'Computers', 'TVs', 'Audio', 'Other'],
    ),
    CategoryItem(
      name: 'Furniture',
      icon: Icons.chair,
      subcategories: ['Living Room', 'Bedroom', 'Office', 'Outdoor', 'Other'],
    ),
  ];
}

class CategoryItem {
  final String name;
  final IconData icon;
  final List<String> subcategories;
  const CategoryItem({required this.name, required this.icon, required this.subcategories});
}
