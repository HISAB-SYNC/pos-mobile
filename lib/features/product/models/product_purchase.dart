class ProductPurchase {
  final String id;
  final String productId;
  final String purchaseId;
  final String supplierName;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final String date;
  final String status; // 'completed' | 'pending' | 'cancelled'

  ProductPurchase({
    required this.id,
    required this.productId,
    required this.purchaseId,
    required this.supplierName,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    required this.date,
    this.status = 'completed',
  });

  factory ProductPurchase.fromJson(Map<String, dynamic> json) {
    final qty = int.tryParse(json['quantity']?.toString() ?? '0') ?? 0;
    final unit = double.tryParse(json['unitCost']?.toString() ?? '0') ?? 0.0;
    final total = double.tryParse(json['totalCost']?.toString() ?? '${qty * unit}') ?? (qty * unit);

    return ProductPurchase(
      id: json['id']?.toString() ?? json['purchaseId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      purchaseId: json['purchaseId']?.toString() ?? json['id']?.toString() ?? 'P-1000',
      supplierName: json['supplierName']?.toString() ?? json['supplier']?.toString() ?? 'Vendor',
      quantity: qty,
      unitCost: unit,
      totalCost: total,
      date: json['date']?.toString() ?? '15/07/2025',
      status: json['status']?.toString() ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'purchaseId': purchaseId,
      'supplierName': supplierName,
      'quantity': quantity,
      'unitCost': unitCost,
      'totalCost': totalCost,
      'date': date,
      'status': status,
    };
  }
}
