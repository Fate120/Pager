class MenuCategory {
  final int id;
  final String name;
  final int sortOrder;

  MenuCategory({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
    id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
    name: json['name'] ?? '',
    sortOrder: json['sortOrder'] ?? json['sort_order'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sortOrder': sortOrder,
  };

  MenuCategory copyWith({
    int? id,
    String? name,
    int? sortOrder,
  }) => MenuCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
  );
}

typedef Category = MenuCategory;
