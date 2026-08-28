class Product {
  final String id;
  final String shopId;
  final String sku;
  final String name;
  final String? description;
  final String categoryName;
  final String? categoryId;
  final double buyingPrice;
  final double price; // Selling price
  final int stockQuantity;
  final int openingStock;
  final int onTheWay;
  final int lowStockThreshold;
  final String unit;
  final String location;
  final String? expiryDate;
  final String? supplierName;
  final String? supplierContact;
  final String? supplierId;
  final String? imageUrl;
  final String status;
  final Map<String, int> locations;

  Product({
    required this.id,
    this.shopId = '',
    required this.sku,
    required this.name,
    this.description,
    this.categoryName = 'General',
    this.categoryId,
    this.buyingPrice = 0.0,
    required this.price,
    required this.stockQuantity,
    this.openingStock = 0,
    this.onTheWay = 0,
    this.lowStockThreshold = 10,
    this.unit = 'Units',
    this.location = 'Store Shelf',
    this.expiryDate,
    this.supplierName,
    this.supplierContact,
    this.supplierId,
    this.imageUrl,
    this.status = 'Available',
    this.locations = const {},
  });

  bool get isLowStock => stockQuantity <= lowStockThreshold && stockQuantity > 0;
  bool get isOutOfStock => stockQuantity <= 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    final qty = json['stockQuantity'] is int
        ? json['stockQuantity'] as int
        : int.tryParse(json['stockQuantity']?.toString() ?? '0') ?? 0;
    final threshold = json['lowStockThreshold'] is int
        ? json['lowStockThreshold'] as int
        : int.tryParse(json['lowStockThreshold']?.toString() ?? '10') ?? 10;

    String catName = 'General';
    String? catId = json['categoryId']?.toString();

    if (json['category'] is Map) {
      final catMap = json['category'] as Map;
      catName = catMap['name']?.toString() ?? 'General';
      catId ??= catMap['id']?.toString();
    } else if (json['categoryName'] != null && json['categoryName'].toString().isNotEmpty) {
      catName = json['categoryName'].toString();
    } else if (json['category'] is String) {
      final str = json['category'] as String;
      if (str.startsWith('{')) {
        final nameMatch = RegExp(r'name:\s*([^,}]+)').firstMatch(str);
        final idMatch = RegExp(r'id:\s*([^,}]+)').firstMatch(str);
        if (nameMatch != null) {
          catName = nameMatch.group(1)?.trim() ?? 'General';
        }
        if (idMatch != null && catId == null) {
          catId = idMatch.group(1)?.trim();
        }
      } else if (str.isNotEmpty) {
        catName = str;
      }
    }

    return Product(
      id: json['id']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      sku: json['sku']?.toString() ?? json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      categoryName: catName,
      categoryId: catId,
      buyingPrice: double.tryParse(json['buyingPrice']?.toString() ?? json['costPrice']?.toString() ?? '0') ?? 0.0,
      price: double.tryParse(json['price']?.toString() ?? json['sellingPrice']?.toString() ?? '0') ?? 0.0,
      stockQuantity: qty,
      openingStock: int.tryParse(json['openingStock']?.toString() ?? '$qty') ?? qty,
      onTheWay: int.tryParse(json['onTheWay']?.toString() ?? '0') ?? 0,
      lowStockThreshold: threshold,
      unit: json['unit']?.toString() ?? 'Units',
      location: json['location']?.toString() ?? 'Main Store',
      expiryDate: json['expiryDate']?.toString(),
      supplierName: json['supplierName']?.toString() ?? json['supplier']?.toString(),
      supplierContact: json['supplierContact']?.toString(),
      supplierId: json['supplierId']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      status: qty <= 0 ? 'Out of Stock' : (qty <= threshold ? 'Low Stock' : 'Available'),
      locations: json['locations'] != null
          ? Map<String, int>.from(json['locations'] as Map)
          : {
              'Main Branch': (qty * 0.6).round(),
              'Sub Branch': (qty * 0.4).round(),
            },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'sku': sku,
      'name': name,
      'description': description,
      'categoryName': categoryName,
      'categoryId': categoryId,
      'buyingPrice': buyingPrice,
      'price': price,
      'stockQuantity': stockQuantity,
      'openingStock': openingStock,
      'onTheWay': onTheWay,
      'lowStockThreshold': lowStockThreshold,
      'unit': unit,
      'location': location,
      'expiryDate': expiryDate,
      'supplierName': supplierName,
      'supplierContact': supplierContact,
      'supplierId': supplierId,
      'imageUrl': imageUrl,
      'status': status,
      'locations': locations,
    };
  }

  Product copyWith({
    String? id,
    String? shopId,
    String? sku,
    String? name,
    String? description,
    String? categoryName,
    String? categoryId,
    double? buyingPrice,
    double? price,
    int? stockQuantity,
    int? openingStock,
    int? onTheWay,
    int? lowStockThreshold,
    String? unit,
    String? location,
    String? expiryDate,
    String? supplierName,
    String? supplierContact,
    String? supplierId,
    String? imageUrl,
    String? status,
    Map<String, int>? locations,
  }) {
    return Product(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      openingStock: openingStock ?? this.openingStock,
      onTheWay: onTheWay ?? this.onTheWay,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      expiryDate: expiryDate ?? this.expiryDate,
      supplierName: supplierName ?? this.supplierName,
      supplierContact: supplierContact ?? this.supplierContact,
      supplierId: supplierId ?? this.supplierId,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      locations: locations ?? this.locations,
    );
  }
}
