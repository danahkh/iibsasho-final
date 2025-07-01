import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/Category.dart';

class CategoryService {
  final CollectionReference _categoryCollection =
      FirebaseFirestore.instance.collection('categories');

  Stream<List<Category>> getCategories() {
    return _categoryCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Category.fromJson(doc.data() as Map<String, dynamic>)).toList());
  }

  // For initial population or fallback
  static List<Category> defaultCategories = [
    Category(
      name: 'Cars',
      iconUrl: 'assets/icons/Category.svg',
      featured: true,
      subcategories: ['Sedan', 'SUV', 'Truck', 'Motorcycle', 'Other'],
    ),
    Category(
      name: 'Real Estate',
      iconUrl: 'assets/icons/Category.svg',
      featured: true,
      subcategories: ['House', 'Apartment', 'Land', 'Commercial', 'Other'],
    ),
    Category(
      name: 'Electronics',
      iconUrl: 'assets/icons/Category.svg',
      featured: true,
      subcategories: ['Phones', 'Computers', 'TVs', 'Audio', 'Other'],
    ),
    Category(
      name: 'Furniture',
      iconUrl: 'assets/icons/Category.svg',
      featured: true,
      subcategories: ['Living Room', 'Bedroom', 'Office', 'Outdoor', 'Other'],
    ),
  ];
}
