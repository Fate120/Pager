class MenuCategory {
  final int id;
  final String name;
  final String emoji;
  final int sortOrder;

  MenuCategory({
    required this.id,
    required this.name,
    this.emoji = '🍽️',
    this.sortOrder = 0,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
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

typedef Category = MenuCategory;
