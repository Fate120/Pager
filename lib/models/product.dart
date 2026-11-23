export 'category.dart';

class ProductAddon {
  final String id;
  final String name;
  final int price;

  ProductAddon({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ProductAddon.fromJson(Map<String, dynamic> json) => ProductAddon(
    id: json['id']?.toString() ?? '',
    name: json['name'] ?? '',
    price: json['price'] is int ? json['price'] : int.tryParse(json['price'].toString()) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };

  ProductAddon copyWith({
    String? id,
    String? name,
    int? price,
  }) => ProductAddon(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
  );
}

class Product {
  final int id;
  final int? categoryId;
  final String name;
  final int price;
  final bool isAvailable;
  final String emoji;
  final String? imageUrl;
  final List<ProductAddon> addOns;

  Product({
    required this.id,
    this.categoryId,
    required this.name,
    required this.price,
    this.isAvailable = true,
    this.emoji = '',
    this.imageUrl,
    this.addOns = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
    categoryId: json['categoryId'] ?? json['category_id'],
    name: json['name'] ?? '',
    price: json['price'] is int ? json['price'] : int.tryParse(json['price'].toString()) ?? 0,
    isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
    emoji: json['emoji'] ?? '',
    imageUrl: json['imageUrl'] ?? json['image_url'] ?? json['image'],
    addOns: (json['addOns'] as List<dynamic>?)
            ?.map((a) => ProductAddon.fromJson(Map<String, dynamic>.from(a)))
            .toList() ??
        (json['addons'] as List<dynamic>?)
            ?.map((a) => ProductAddon.fromJson(Map<String, dynamic>.from(a)))
            .toList() ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'name': name,
    'price': price,
    'isAvailable': isAvailable,
    'emoji': emoji,
    'imageUrl': imageUrl,
    'addOns': addOns.map((a) => a.toJson()).toList(),
  };

  Product copyWith({
    int? id,
    int? categoryId,
    bool clearCategoryId = false,
    String? name,
    int? price,
    bool? isAvailable,
    String? emoji,
    String? imageUrl,
    List<ProductAddon>? addOns,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      name: name ?? this.name,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      emoji: emoji ?? this.emoji,
      imageUrl: imageUrl ?? this.imageUrl,
      addOns: addOns ?? this.addOns,
    );
  }
}
