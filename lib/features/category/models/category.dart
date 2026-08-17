class Category {
  final String id;
  final String shopId;
  final String name;
  final String createdAt;
  final String updatedAt;

  Category({
    required this.id,
    required this.shopId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      shopId: json['shopId'] as String,
      name: json['name'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}