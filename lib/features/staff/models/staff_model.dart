class StaffSummary {
  final int totalMembers;
  final int shopAdmins;
  final int shopSales;

  const StaffSummary({
    this.totalMembers = 0,
    this.shopAdmins = 0,
    this.shopSales = 0,
  });
}

class StaffMember {
  final String id;
  final String name;
  final String email;
  final String role; // 'Shop Admin' | 'Shop Sale' or 'ADMIN' | 'SALES'
  final String? shopId;
  final bool isActive;
  final String joinedDate; // e.g. '11/11/22' or 'Sep 5, 2026'
  final String lastLogin; // e.g. 'Never'
  final String status; // 'Active' | 'Inactive'
  final String? createdAt;
  final String? updatedAt;

  StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.shopId,
    this.isActive = true,
    required this.joinedDate,
    required this.lastLogin,
    this.status = 'Active',
    this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role.toUpperCase().contains('ADMIN');
  bool get isSales => role.toUpperCase().contains('SALE');

  /// The exact uppercase role string expected by the backend API: 'ADMIN' or 'SALES'
  String get apiRole => isAdmin ? 'ADMIN' : 'SALES';

  /// Human-friendly display title
  String get displayRole => isAdmin ? 'Shop Admin' : 'Shop Sale';

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role']?.toString().toUpperCase() ?? 'SALES';
    final normalizedRole = rawRole.contains('ADMIN') ? 'Shop Admin' : 'Shop Sale';

    final bool active = json['isActive'] is bool
        ? (json['isActive'] as bool)
        : (json['status']?.toString().toLowerCase() != 'inactive');

    String formattedJoined = json['joinedDate']?.toString() ?? '';
    if (formattedJoined.isEmpty && json['createdAt'] != null) {
      try {
        final parsed = DateTime.parse(json['createdAt'].toString()).toLocal();
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        formattedJoined = '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
      } catch (_) {
        formattedJoined = json['createdAt'].toString().split('T').first;
      }
    }
    if (formattedJoined.isEmpty) {
      formattedJoined = 'Today';
    }

    return StaffMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: normalizedRole,
      shopId: json['shopId']?.toString(),
      isActive: active,
      joinedDate: formattedJoined,
      lastLogin: json['lastLogin']?.toString() ?? 'Never',
      status: active ? 'Active' : 'Inactive',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': apiRole,
      'shopId': shopId,
      'isActive': isActive,
      'joinedDate': joinedDate,
      'lastLogin': lastLogin,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  StaffMember copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? shopId,
    bool? isActive,
    String? joinedDate,
    String? lastLogin,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate ?? this.joinedDate,
      lastLogin: lastLogin ?? this.lastLogin,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
