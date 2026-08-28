class ProductHistory {
  final String id;
  final String productId;
  final String transactionId;
  final String type; // 'Purchase' | 'Sale' | 'Adjustment' | 'Restock'
  final int quantity; // e.g. +50, -5
  final String storeLocation;
  final double value;
  final String date;
  final String personName;

  ProductHistory({
    required this.id,
    required this.productId,
    required this.transactionId,
    required this.type,
    required this.quantity,
    required this.storeLocation,
    required this.value,
    required this.date,
    required this.personName,
  });

  factory ProductHistory.fromJson(Map<String, dynamic> json) {
    return ProductHistory(
      id: json['id']?.toString() ?? json['transactionId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? 'T-1234',
      type: json['type']?.toString() ?? 'Sale',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      storeLocation: json['storeLocation']?.toString() ?? json['store']?.toString() ?? 'Main Branch',
      value: double.tryParse(json['value']?.toString() ?? '0') ?? 0.0,
      date: json['date']?.toString() ?? '15/07/2025',
      personName: json['personName']?.toString() ?? json['person']?.toString() ?? 'Admin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'transactionId': transactionId,
      'type': type,
      'quantity': quantity,
      'storeLocation': storeLocation,
      'value': value,
      'date': date,
      'personName': personName,
    };
  }
}
