class StaffSummary {
  final int totalMembers;
  final int shopAdmins;
  final int shopSales;

  const StaffSummary({
    this.totalMembers = 3,
    this.shopAdmins = 1,
    this.shopSales = 2,
  });
}

class StaffMember {
  final String id;
  final String name;
  final String email;
  final String role; // 'Shop Admin' | 'Shop Sale'
  final String joinedDate; // e.g. '11/11/22'
  final String lastLogin; // e.g. '11/12/22'
  final String status; // 'Active' | 'Inactive'

  StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedDate,
    required this.lastLogin,
    this.status = 'Active',
  });

  bool get isAdmin => role.toLowerCase().contains('admin');
  bool get isSales => role.toLowerCase().contains('sale');

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Shop Sale',
      joinedDate: json['joinedDate']?.toString() ?? 'Today',
      lastLogin: json['lastLogin']?.toString() ?? 'Never',
      status: json['status']?.toString() ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'joinedDate': joinedDate,
      'lastLogin': lastLogin,
      'status': status,
    };
  }

  StaffMember copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? joinedDate,
    String? lastLogin,
    String? status,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      joinedDate: joinedDate ?? this.joinedDate,
      lastLogin: lastLogin ?? this.lastLogin,
      status: status ?? this.status,
    );
  }
}
