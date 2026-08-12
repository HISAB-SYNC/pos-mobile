/// Represents a logged-in user of the MiniShop app.
/// Field names and the `role` casing match the real backend exactly
/// (see API_GUIDE.md §2), so parsing a real response later needs no changes.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'OWNER' | 'ADMIN' | 'SALES' — always uppercase from the API
  final String? shopId; // null for OWNER (multi-shop), required UUID for ADMIN/SALES

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.shopId,
  });

  bool get isOwner => role == 'OWNER';
  bool get isAdmin => role == 'ADMIN';
  bool get isSales => role == 'SALES';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      shopId: json['shopId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'shopId': shopId,
    };
  }
}