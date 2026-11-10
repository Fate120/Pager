class Category {
  final int id;
  final String name;
  final String emoji;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    this.emoji = '🍽️',
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
    name: json['name'] ?? '',
    emoji: json['emoji'] ?? '🍽️',
    sortOrder: json['sortOrder'] ?? json['sort_order'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'sortOrder': sortOrder,
  };
}

class Product {
  final int id;
  final int? categoryId;
  final String name;
  final int price;
  final bool isAvailable;
  final String emoji;

  Product({
    required this.id,
    this.categoryId,
    required this.name,
    required this.price,
    this.isAvailable = true,
    this.emoji = '☕',
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
    categoryId: json['categoryId'] ?? json['category_id'],
    name: json['name'] ?? '',
    price: json['price'] is int ? json['price'] : int.tryParse(json['price'].toString()) ?? 0,
    isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
    emoji: json['emoji'] ?? '☕',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'name': name,
    'price': price,
    'isAvailable': isAvailable,
    'emoji': emoji,
  };

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    int? price,
    bool? isAvailable,
    String? emoji,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      emoji: emoji ?? this.emoji,
    );
  }
}
