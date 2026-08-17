class Shop {
  final String id;
  final String name;
  final String businessType;
  final String address;
  final double taxRate;
  final String currency;
  final String language;
  final String ownerId;
  final String createdAt;
  final String updatedAt;

  Shop({
    required this.id,
    required this.name,
    required this.businessType,
    required this.address,
    required this.taxRate,
    required this.currency,
    required this.language,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      address: json['address'] as String? ?? '',
      taxRate: double.tryParse(
            json['taxRate']?.toString() ?? '0',
          ) ??
          0,
      currency: json['currency'] as String? ?? 'ETB',
      language: json['language'] as String? ?? 'en',
      ownerId: json['ownerId'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'businessType': businessType,
      'address': address,
      'taxRate': taxRate,
      'currency': currency,
      'language': language,
      'ownerId': ownerId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}