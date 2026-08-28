class SalesMetrics {
  final int count;
  final double totalAmount;

  const SalesMetrics({this.count = 0, this.totalAmount = 0.0});

  factory SalesMetrics.fromJson(Map<String, dynamic> json) {
    return SalesMetrics(
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'totalAmount': totalAmount,
    };
  }
}

class DebtsMetrics {
  final int count;
  final double totalAmount;

  const DebtsMetrics({this.count = 0, this.totalAmount = 0.0});

  factory DebtsMetrics.fromJson(Map<String, dynamic> json) {
    return DebtsMetrics(
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'totalAmount': totalAmount,
    };
  }
}

class DashboardMetrics {
  final SalesMetrics todaysSales;
  final int lowStockCount;
  final DebtsMetrics outstandingDebts;

  const DashboardMetrics({
    this.todaysSales = const SalesMetrics(),
    this.lowStockCount = 0,
    this.outstandingDebts = const DebtsMetrics(),
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      todaysSales: json['todaysSales'] is Map<String, dynamic>
          ? SalesMetrics.fromJson(json['todaysSales'] as Map<String, dynamic>)
          : const SalesMetrics(),
      lowStockCount: int.tryParse(json['lowStockCount']?.toString() ?? '0') ?? 0,
      outstandingDebts: json['outstandingDebts'] is Map<String, dynamic>
          ? DebtsMetrics.fromJson(json['outstandingDebts'] as Map<String, dynamic>)
          : const DebtsMetrics(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todaysSales': todaysSales.toJson(),
      'lowStockCount': lowStockCount,
      'outstandingDebts': outstandingDebts.toJson(),
    };
  }
}
