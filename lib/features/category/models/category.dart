class Category {
  final String id;
  final String shopId;
  final String name;
  final String createdAt;
  final String updatedAt;

  Category({
    required this.id,
    this.shopId = '',
    required this.name,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
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