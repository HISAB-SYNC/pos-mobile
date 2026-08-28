import 'dart:convert';

class Supplier {
  final String id;
  final String shopId;
  final String name;
  final String contactInfo; // Combined or phone from backend
  final String? email;
  final String? phone;
  final String? product;
  final String? category;
  final String type; // 'Taking Return' | 'Not Taking Return'
  final int onTheWay;
  final String createdAt;
  final String updatedAt;

  Supplier({
    required this.id,
    this.shopId = '',
    required this.name,
    this.contactInfo = '',
    this.email,
    this.phone,
    this.product,
    this.category,
    this.type = 'Taking Return',
    this.onTheWay = 0,
    this.createdAt = '',
    this.updatedAt = '',
  });

  bool get isTakingReturn {
    final t = type.toLowerCase().trim();
    if (t.contains('not') || t.contains('no')) return false;
    return t.contains('taking');
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    String rawContact = json['contactInfo']?.toString() ?? '';
    String? email = json['email']?.toString();
    String? phone = json['phone']?.toString() ?? json['contactNumber']?.toString();
    String? product = json['product']?.toString();
    String? category = json['category']?.toString();
    String type = json['type']?.toString() ?? 'Taking Return';
    int onTheWay = int.tryParse(json['onTheWay']?.toString() ?? '0') ?? 0;

    // 1. Parse JSON embedded inside contactInfo
    if (rawContact.contains('{') && rawContact.contains('}')) {
      try {
        final startIdx = rawContact.indexOf('{');
        final endIdx = rawContact.lastIndexOf('}');
        final jsonSub = rawContact.substring(startIdx, endIdx + 1);
        final map = jsonDecode(jsonSub) as Map<String, dynamic>;
        email = map['email']?.toString() ?? email;
        phone = map['phone']?.toString() ?? phone;
        product = map['product']?.toString() ?? product;
        category = map['category']?.toString() ?? category;
        if (map['type'] != null && map['type'].toString().isNotEmpty) {
          type = map['type'].toString();
        }
        onTheWay = int.tryParse(map['onTheWay']?.toString() ?? '$onTheWay') ?? onTheWay;
      } catch (_) {}
    } else if (rawContact.isNotEmpty) {
      final lower = rawContact.toLowerCase();
      if (lower.contains('not taking') || lower.contains('not_taking') || lower.contains('no return') || lower.contains('not return')) {
        type = 'Not Taking Return';
      } else if (lower.contains('taking return')) {
        type = 'Taking Return';
      }

      if (phone == null || phone.isEmpty) {
        if (rawContact.contains('@')) {
          email ??= rawContact;
        } else {
          phone ??= rawContact;
        }
      }
    }

    return Supplier(
      id: json['id']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contactInfo: rawContact,
      email: email,
      phone: phone,
      product: product ?? 'Assorted Goods',
      category: category ?? 'General',
      type: type,
      onTheWay: onTheWay,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'name': name,
      'contactInfo': phone ?? contactInfo,
      'email': email,
      'phone': phone,
      'product': product,
      'category': category,
      'type': type,
      'onTheWay': onTheWay,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toBackendJson() {
    final contactMap = {
      'phone': phone ?? '',
      'email': email ?? '',
      'product': product ?? '',
      'category': category ?? '',
      'type': type, // "Not Taking Return" or "Taking Return"
      'onTheWay': onTheWay,
    };
    return {
      'name': name,
      'contactInfo': jsonEncode(contactMap),
    };
  }

  Supplier copyWith({
    String? id,
    String? shopId,
    String? name,
    String? contactInfo,
    String? email,
    String? phone,
    String? product,
    String? category,
    String? type,
    int? onTheWay,
  }) {
    return Supplier(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      contactInfo: contactInfo ?? this.contactInfo,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      product: product ?? this.product,
      category: category ?? this.category,
      type: type ?? this.type,
      onTheWay: onTheWay ?? this.onTheWay,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
