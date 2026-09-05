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
    this.businessType = '',
    this.address = '',
    this.taxRate = 0.0,
    this.currency = 'ETB',
    this.language = 'en',
    this.ownerId = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      businessType: json['businessType']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      taxRate: double.tryParse(json['taxRate']?.toString() ?? '0') ?? 0.0,
      currency: json['currency']?.toString() ?? 'ETB',
      language: json['language']?.toString() ?? 'en',
      ownerId: json['ownerId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
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

  Shop copyWith({
    String? id,
    String? name,
    String? businessType,
    String? address,
    double? taxRate,
    String? currency,
    String? language,
    String? ownerId,
    String? createdAt,
    String? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      address: address ?? this.address,
      taxRate: taxRate ?? this.taxRate,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}