class ExpenseSummary {
  final double totalExpenses;
  final double growthPercent;
  final double thisWeek;
  final double pendingPayment;

  const ExpenseSummary({
    this.totalExpenses = 5040,
    this.growthPercent = 12.5,
    this.thisWeek = 0.0,
    this.pendingPayment = 1200,
  });
}

class ShopExpense {
  final String id;
  final String date; // e.g. 'Jan 18, 2025'
  final String description; // e.g. 'Monthly Electricity Bill'
  final String category; // 'Utilities' | 'Staff' | 'Equipment' | 'Marketing'
  final double amount; // e.g. 2450
  final String paymentMethod; // 'Bank Transfer' | 'Credit Card' | 'Digital Payment' | 'Cash'
  final String status; // 'Paid' | 'Pending' | 'Overdue'

  ShopExpense({
    required this.id,
    required this.date,
    required this.description,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.status,
  });

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isOverdue => status.toLowerCase() == 'overdue';

  factory ShopExpense.fromJson(Map<String, dynamic> json) {
    return ShopExpense(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
      status: json['status']?.toString() ?? 'Paid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'description': description,
      'category': category,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
    };
  }

  ShopExpense copyWith({
    String? id,
    String? date,
    String? description,
    String? category,
    double? amount,
    String? paymentMethod,
    String? status,
  }) {
    return ShopExpense(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
    );
  }
}
