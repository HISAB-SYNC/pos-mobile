class CustomerTransaction {
  final String id;
  final String title; // 'Purchase'
  final String date; // '30/07/2025'
  final double amount; // 1000
  final String status; // 'Unpaid' | 'Paid'

  const CustomerTransaction({
    required this.id,
    this.title = 'Purchase',
    required this.date,
    required this.amount,
    this.status = 'Unpaid',
  });

  factory CustomerTransaction.fromJson(Map<String, dynamic> json) {
    return CustomerTransaction(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['type']?.toString() ?? 'Purchase',
      date: json['date']?.toString() ?? json['createdAt']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? json['totalAmount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'Unpaid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'amount': amount,
      'status': status,
    };
  }
}

class Customer {
  final String id;
  final String customerCode; // e.g. 'Cust - 001'
  final String name;
  final String phone;
  final String? email;
  final String address;
  final double totalDebt; // debtBalance
  final double creditLimit;
  final int daysOverdue; // e.g. 5, 15, or 0
  final String registeredDate; // e.g. '18/07/2025'
  final String status; // 'Active' | 'Overdue'
  final List<CustomerTransaction> transactions;
  final List<dynamic> sales;
  final List<dynamic> debts;

  Customer({
    required this.id,
    this.customerCode = '',
    required this.name,
    required this.phone,
    this.email,
    this.address = '',
    this.totalDebt = 0.0,
    this.creditLimit = 0.0,
    this.daysOverdue = 0,
    this.registeredDate = '',
    this.status = 'Active',
    this.transactions = const [],
    this.sales = const [],
    this.debts = const [],
  });

  bool get hasDebt => totalDebt > 0;
  double get availableCredit => (creditLimit - totalDebt).clamp(0, creditLimit);
  double get creditUsedPercentage => creditLimit > 0 ? ((totalDebt / creditLimit) * 100).clamp(0, 100) : 0;
  bool get isOverdue => daysOverdue > 0 || status.toLowerCase() == 'overdue';

  factory Customer.fromJson(Map<String, dynamic> json) {
    final parsedDebt = double.tryParse(
          json['debtBalance']?.toString() ?? json['totalDebt']?.toString() ?? '0',
        ) ??
        0.0;

    List<CustomerTransaction> txList = [];
    if (json['transactions'] is List) {
      txList = (json['transactions'] as List)
          .map((t) => CustomerTransaction.fromJson(t as Map<String, dynamic>))
          .toList();
    } else if (json['debts'] is List) {
      txList = (json['debts'] as List).map((d) {
        final map = d is Map<String, dynamic> ? d : <String, dynamic>{};
        return CustomerTransaction(
          id: map['id']?.toString() ?? '',
          title: 'Debt: ${map['notes'] ?? 'Sale Credit'}',
          date: map['createdAt']?.toString() ?? '',
          amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
          status: map['status']?.toString() ?? 'PENDING',
        );
      }).toList();
    }

    final id = json['id']?.toString() ?? '';
    final code = json['customerCode']?.toString() ??
        (id.length > 6 ? 'CUST-${id.substring(0, 6).toUpperCase()}' : 'CUST');

    return Customer(
      id: id,
      customerCode: code,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      address: json['address']?.toString() ?? '',
      totalDebt: parsedDebt,
      creditLimit: double.tryParse(json['creditLimit']?.toString() ?? '0') ?? (parsedDebt > 0 ? parsedDebt * 1.5 : 5000.0),
      daysOverdue: int.tryParse(json['daysOverdue']?.toString() ?? '0') ?? 0,
      registeredDate: json['registeredDate']?.toString() ?? json['createdAt']?.toString() ?? '',
      status: json['status']?.toString() ?? (parsedDebt > 0 ? 'Active' : 'Active'),
      transactions: txList,
      sales: json['sales'] is List ? json['sales'] as List : const [],
      debts: json['debts'] is List ? json['debts'] as List : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerCode': customerCode,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'totalDebt': totalDebt,
      'debtBalance': totalDebt.toStringAsFixed(2),
      'creditLimit': creditLimit,
      'daysOverdue': daysOverdue,
      'registeredDate': registeredDate,
      'status': status,
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'sales': sales,
      'debts': debts,
    };
  }

  Map<String, dynamic> toCreateBackendJson() {
    return {
      'name': name,
      'phone': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (address.isNotEmpty) 'address': address,
    };
  }

  Customer copyWith({
    String? id,
    String? customerCode,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? totalDebt,
    double? creditLimit,
    int? daysOverdue,
    String? registeredDate,
    String? status,
    List<CustomerTransaction>? transactions,
    List<dynamic>? sales,
    List<dynamic>? debts,
  }) {
    return Customer(
      id: id ?? this.id,
      customerCode: customerCode ?? this.customerCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalDebt: totalDebt ?? this.totalDebt,
      creditLimit: creditLimit ?? this.creditLimit,
      daysOverdue: daysOverdue ?? this.daysOverdue,
      registeredDate: registeredDate ?? this.registeredDate,
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      sales: sales ?? this.sales,
      debts: debts ?? this.debts,
    );
  }
}
