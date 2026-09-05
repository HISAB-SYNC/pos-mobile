class ExpenseSummary {
  final double totalExpenses;
  final double growthPercent;
  final double thisWeek;
  final double pendingPayment;
  final int totalCount;

  const ExpenseSummary({
    this.totalExpenses = 0.0,
    this.growthPercent = 0.0,
    this.thisWeek = 0.0,
    this.pendingPayment = 0.0,
    this.totalCount = 0,
  });

  ExpenseSummary copyWith({
    double? totalExpenses,
    double? growthPercent,
    double? thisWeek,
    double? pendingPayment,
    int? totalCount,
  }) {
    return ExpenseSummary(
      totalExpenses: totalExpenses ?? this.totalExpenses,
      growthPercent: growthPercent ?? this.growthPercent,
      thisWeek: thisWeek ?? this.thisWeek,
      pendingPayment: pendingPayment ?? this.pendingPayment,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class ShopExpense {
  final String id;
  final String? shopId;
  final String? userId;
  final String date; // e.g. 'Jan 18, 2025' or 'Sep 5, 2026'
  final String description; // e.g. 'Monthly store rent'
  final String category; // 'Rent' | 'Utilities' | 'Salaries' | 'Inventory' | 'Other'
  final double amount;
  final String paymentMethod; // 'CASH' | 'CARD' | 'MOBILE'
  final String expenseDate; // ISO 8601 string: '2026-09-05T00:00:00.000Z'
  final String status; // 'Paid' | 'Pending' | 'Overdue'
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? user;

  ShopExpense({
    required this.id,
    this.shopId,
    this.userId,
    required this.date,
    required this.description,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    this.expenseDate = '',
    this.status = 'Paid',
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isOverdue => status.toLowerCase() == 'overdue';

  String get displayPaymentMethod {
    switch (paymentMethod.toUpperCase()) {
      case 'CASH':
        return 'Cash';
      case 'CARD':
        return 'Card';
      case 'MOBILE':
        return 'Mobile Payment';
      default:
        return paymentMethod;
    }
  }

  static String normalizePaymentMethod(String method) {
    final m = method.toUpperCase();
    if (m.contains('CASH')) return 'CASH';
    if (m.contains('CARD') || m.contains('CREDIT')) return 'CARD';
    if (m.contains('MOBILE') || m.contains('DIGITAL') || m.contains('TRANSFER') || m.contains('BANK')) {
      return 'MOBILE';
    }
    return 'CASH';
  }

  factory ShopExpense.fromJson(Map<String, dynamic> json) {
    // Parse amount from num, string, or fallback to 0.0
    final rawAmount = json['amount'];
    final double parsedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

    // Normalize payment method to CASH | CARD | MOBILE
    final rawMethod = json['paymentMethod']?.toString() ?? 'CASH';
    final normalizedMethod = normalizePaymentMethod(rawMethod);

    // Parse dates
    final rawExpenseDate = json['expenseDate']?.toString() ?? json['createdAt']?.toString() ?? '';
    String displayDate = json['date']?.toString() ?? '';

    if (displayDate.isEmpty && rawExpenseDate.isNotEmpty) {
      try {
        final parsed = DateTime.parse(rawExpenseDate).toLocal();
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        displayDate = '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
      } catch (_) {
        displayDate = rawExpenseDate.split('T').first;
      }
    }
    if (displayDate.isEmpty) {
      displayDate = 'Today';
    }

    return ShopExpense(
      id: json['id']?.toString() ?? '',
      shopId: json['shopId']?.toString(),
      userId: json['userId']?.toString(),
      date: displayDate,
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
      amount: parsedAmount,
      paymentMethod: normalizedMethod,
      expenseDate: rawExpenseDate.isNotEmpty ? rawExpenseDate : DateTime.now().toIso8601String(),
      status: json['status']?.toString() ?? 'Paid',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      user: json['user'] is Map<String, dynamic> ? (json['user'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (shopId != null) 'shopId': shopId,
      if (userId != null) 'userId': userId,
      'date': date,
      'description': description,
      'category': category,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'expenseDate': expenseDate,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (user != null) 'user': user,
    };
  }

  ShopExpense copyWith({
    String? id,
    String? shopId,
    String? userId,
    String? date,
    String? description,
    String? category,
    double? amount,
    String? paymentMethod,
    String? expenseDate,
    String? status,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? user,
  }) {
    return ShopExpense(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      description: description ?? this.description,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expenseDate: expenseDate ?? this.expenseDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }
}
