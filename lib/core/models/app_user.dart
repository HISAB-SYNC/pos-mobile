/// Represents a logged-in user of the MiniShop app.
/// Field names and the `role` casing match the real backend exactly
/// (see API_GUIDE.md §2), so parsing a real response later needs no changes.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'OWNER' | 'ADMIN' | 'SALES' — always uppercase from the API
  final String? shopId; // null for OWNER (multi-shop), required UUID for ADMIN/SALES
  final String? createdAt;
  final String? updatedAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.shopId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOwner => role == 'OWNER';
  bool get isAdmin => role == 'ADMIN';
  bool get isSales => role == 'SALES';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString().toUpperCase() ?? 'SALES',
      shopId: json['shopId']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'shopId': shopId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}