class Category {
  String iconUrl;
  String name;
  bool featured;
  List<String> subcategories; // Added subcategories
  Category({
    required this.name,
    required this.iconUrl,
    required this.featured,
    required this.subcategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      featured: json['featured'],
      iconUrl: json['icon_url'],
      name: json['name'],
      subcategories: List<String>.from(json['subcategories'] ?? []),
    );
  }
}
