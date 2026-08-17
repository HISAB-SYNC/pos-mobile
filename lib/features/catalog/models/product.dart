class Product {
  final String id;
  final String shopId;
  final String sku;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String unit;
  final int lowStockThreshold;
  final String? categoryId;
  final String? supplierId;

  Product({
    required this.id,
    required this.shopId,
    required this.sku,
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    required this.unit,
    required this.lowStockThreshold,
    this.categoryId,
    this.supplierId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      shopId: json['shopId'] ?? '',
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0,
      stockQuantity: json['stockQuantity'] ?? 0,
      unit: json['unit'] ?? '',
      lowStockThreshold: json['lowStockThreshold'] ?? 0,
      categoryId: json['categoryId'],
      supplierId: json['supplierId'],
    );
  }
}