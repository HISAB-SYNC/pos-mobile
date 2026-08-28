class DebtPayment {
  final String id;
  final double amount;
  final String paidAt;

  DebtPayment({
    required this.id,
    required this.amount,
    required this.paidAt,
  });

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: json['id']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paidAt: json['paidAt']?.toString() ?? json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'paidAt': paidAt,
    };
  }
}

class Debt {
  final String id;
  final String customerId;
  final double amount;
  final String status; // 'PENDING' | 'PARTIAL' | 'PAID'
  final String? dueDate;
  final String? notes;
  final String? createdAt;
  final List<DebtPayment> payments;

  Debt({
    required this.id,
    required this.customerId,
    required this.amount,
    this.status = 'PENDING',
    this.dueDate,
    this.notes,
    this.createdAt,
    this.payments = const [],
  });

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isPartial => status.toUpperCase() == 'PARTIAL';
  bool get isPending => status.toUpperCase() == 'PENDING';

  double get totalPaid => payments.fold<double>(0.0, (sum, p) => sum + p.amount);
  double get remainingAmount => (amount - totalPaid).clamp(0.0, amount);

  factory Debt.fromJson(Map<String, dynamic> json) {
    var rawPayments = json['payments'];
    List<DebtPayment> parsedPayments = [];
    if (rawPayments is List) {
      parsedPayments = rawPayments
          .map((p) => DebtPayment.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return Debt(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      dueDate: json['dueDate']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString(),
      payments: parsedPayments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'amount': amount,
      'status': status,
      'dueDate': dueDate,
      'notes': notes,
      'createdAt': createdAt,
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }
}
