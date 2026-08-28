class SaleProductItem {
  final String id;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String name;
  final String sku;

  SaleProductItem({
    this.id = '',
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.name = '',
    this.sku = '',
  });

  factory SaleProductItem.fromJson(Map<String, dynamic> json) {
    final prod = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : <String, dynamic>{};
    return SaleProductItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? prod['id']?.toString() ?? '',
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unitPrice: double.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      name: prod['name']?.toString() ?? json['productName']?.toString() ?? 'Item',
      sku: prod['sku']?.toString() ?? json['sku']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
      'product': {
        'id': productId,
        'name': name,
        'sku': sku,
      },
    };
  }
}

class Sale {
  final String id;
  final String shopId;
  final String userId;
  final String? customerId;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final bool isCredit;
  final String createdAt;
  final List<SaleProductItem> items;

  Sale({
    required this.id,
    this.shopId = '',
    this.userId = '',
    this.customerId,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    required this.totalAmount,
    this.paymentMethod = 'CASH',
    this.status = 'COMPLETED',
    this.isCredit = false,
    this.createdAt = '',
    this.items = const [],
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<SaleProductItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((item) => SaleProductItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Sale(
      id: json['id']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      customerId: json['customerId']?.toString(),
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      taxAmount: double.tryParse(json['taxAmount']?.toString() ?? '0') ?? 0.0,
      discountAmount:
          double.tryParse(json['discountAmount']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(
              json['totalAmount']?.toString() ?? json['total']?.toString() ?? '0') ??
          0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'CASH',
      status: json['status']?.toString() ?? 'COMPLETED',
      isCredit: json['isCredit'] == true || json['isCredit']?.toString() == 'true',
      createdAt: json['createdAt']?.toString() ?? '',
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'userId': userId,
      'customerId': customerId,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'status': status,
      'isCredit': isCredit,
      'createdAt': createdAt,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
