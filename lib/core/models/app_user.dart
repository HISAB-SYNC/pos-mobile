/// Represents a logged-in user of the POS app.
/// Field names and the `role` casing match the real backend exactly
/// (see API_GUIDE.md §2), so parsing a real response needs no changes.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'OWNER' | 'ADMIN' | 'SALES' — always uppercase from the API
  final String? shopId; // null for OWNER (multi-shop), required UUID for ADMIN/SALES
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  final List<dynamic>? ownedShops;
  final Map<String, dynamic>? shop;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.shopId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.ownedShops,
    this.shop,
  });

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isOwner => role == 'OWNER' || role == 'SUPER_ADMIN';
  bool get isAdmin => role == 'ADMIN';
  bool get isSales => role == 'SALES';

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? shopId,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    List<dynamic>? ownedShops,
    Map<String, dynamic>? shop,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownedShops: ownedShops ?? this.ownedShops,
      shop: shop ?? this.shop,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString().toUpperCase() ?? 'SALES',
      shopId: json['shopId']?.toString(),
      isActive: json['isActive'] == true || json['isActive'] == null,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      ownedShops: json['ownedShops'] is List ? (json['ownedShops'] as List) : null,
      shop: json['shop'] is Map<String, dynamic> ? (json['shop'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'shopId': shopId,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (ownedShops != null) 'ownedShops': ownedShops,
      if (shop != null) 'shop': shop,
    };
  }
}