class ProductAdjustment {
  final String id;
  final String productId;
  final String adjustmentId;
  final int quantityChange; // e.g. -5, +3
  final String reason; // 'Damaged' | 'Expired' | 'Found stock' | 'Theft' | 'Inventory Count'
  final String storeLocation;
  final String date;

  ProductAdjustment({
    required this.id,
    required this.productId,
    required this.adjustmentId,
    required this.quantityChange,
    required this.reason,
    required this.storeLocation,
    required this.date,
  });

  factory ProductAdjustment.fromJson(Map<String, dynamic> json) {
    return ProductAdjustment(
      id: json['id']?.toString() ?? json['adjustmentId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      adjustmentId: json['adjustmentId']?.toString() ?? 'A-0001',
      quantityChange: int.tryParse(json['quantityChange']?.toString() ?? '0') ?? 0,
      reason: json['reason']?.toString() ?? 'Damaged',
      storeLocation: json['storeLocation']?.toString() ?? json['store']?.toString() ?? 'Main Branch',
      date: json['date']?.toString() ?? '15/07/2025',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'adjustmentId': adjustmentId,
      'quantityChange': quantityChange,
      'reason': reason,
      'storeLocation': storeLocation,
      'date': date,
    };
  }
}
