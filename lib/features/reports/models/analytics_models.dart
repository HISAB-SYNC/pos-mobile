class ShopAnalytics {
  final String period; // 'daily' | 'weekly' | 'monthly' | 'custom'
  final AnalyticsDateRange dateRange;
  final SalesAnalytics salesAnalytics;
  final ProductAnalytics productAnalytics;
  final CustomerAnalytics customerAnalytics;

  const ShopAnalytics({
    required this.period,
    required this.dateRange,
    required this.salesAnalytics,
    required this.productAnalytics,
    required this.customerAnalytics,
  });

  factory ShopAnalytics.fromJson(Map<String, dynamic> json) {
    return ShopAnalytics(
      period: json['period']?.toString() ?? 'daily',
      dateRange: AnalyticsDateRange.fromJson(json['dateRange'] as Map<String, dynamic>? ?? {}),
      salesAnalytics: SalesAnalytics.fromJson(json['salesAnalytics'] as Map<String, dynamic>? ?? {}),
      productAnalytics: ProductAnalytics.fromJson(json['productAnalytics'] as Map<String, dynamic>? ?? {}),
      customerAnalytics: CustomerAnalytics.fromJson(json['customerAnalytics'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class AnalyticsDateRange {
  final String startDate;
  final String endDate;

  const AnalyticsDateRange({
    required this.startDate,
    required this.endDate,
  });

  factory AnalyticsDateRange.fromJson(Map<String, dynamic> json) {
    return AnalyticsDateRange(
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
    );
  }
}

class SalesAnalytics {
  final int totalSalesCount;
  final double totalRevenue;
  final double totalTaxCollected;
  final double totalDiscountsGiven;
  final double averageOrderValue;
  final PaymentMethodBreakdown paymentMethodBreakdown;
  final List<SalesTrendPoint> salesTrend;

  const SalesAnalytics({
    required this.totalSalesCount,
    required this.totalRevenue,
    required this.totalTaxCollected,
    required this.totalDiscountsGiven,
    required this.averageOrderValue,
    required this.paymentMethodBreakdown,
    required this.salesTrend,
  });

  factory SalesAnalytics.fromJson(Map<String, dynamic> json) {
    final trendList = (json['salesTrend'] is List)
        ? (json['salesTrend'] as List)
            .map((item) => SalesTrendPoint.fromJson(item as Map<String, dynamic>))
            .toList()
        : <SalesTrendPoint>[];

    return SalesAnalytics(
      totalSalesCount: int.tryParse(json['totalSalesCount']?.toString() ?? '0') ?? 0,
      totalRevenue: double.tryParse(json['totalRevenue']?.toString() ?? '0') ?? 0.0,
      totalTaxCollected: double.tryParse(json['totalTaxCollected']?.toString() ?? '0') ?? 0.0,
      totalDiscountsGiven: double.tryParse(json['totalDiscountsGiven']?.toString() ?? '0') ?? 0.0,
      averageOrderValue: double.tryParse(json['averageOrderValue']?.toString() ?? '0') ?? 0.0,
      paymentMethodBreakdown: PaymentMethodBreakdown.fromJson(json['paymentMethodBreakdown'] as Map<String, dynamic>? ?? {}),
      salesTrend: trendList,
    );
  }
}

class PaymentMethodBreakdown {
  final PaymentMethodStat cash;
  final PaymentMethodStat card;
  final PaymentMethodStat mobile;

  const PaymentMethodBreakdown({
    required this.cash,
    required this.card,
    required this.mobile,
  });

  double get grandTotal => cash.totalAmount + card.totalAmount + mobile.totalAmount;

  factory PaymentMethodBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentMethodBreakdown(
      cash: PaymentMethodStat.fromJson(json['CASH'] as Map<String, dynamic>? ?? {}),
      card: PaymentMethodStat.fromJson(json['CARD'] as Map<String, dynamic>? ?? {}),
      mobile: PaymentMethodStat.fromJson(json['MOBILE'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class PaymentMethodStat {
  final int count;
  final double totalAmount;

  const PaymentMethodStat({
    required this.count,
    required this.totalAmount,
  });

  factory PaymentMethodStat.fromJson(Map<String, dynamic> json) {
    return PaymentMethodStat(
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class SalesTrendPoint {
  final String date;
  final int salesCount;
  final double totalRevenue;

  const SalesTrendPoint({
    required this.date,
    required this.salesCount,
    required this.totalRevenue,
  });

  factory SalesTrendPoint.fromJson(Map<String, dynamic> json) {
    return SalesTrendPoint(
      date: json['date']?.toString() ?? '',
      salesCount: int.tryParse(json['salesCount']?.toString() ?? '0') ?? 0,
      totalRevenue: double.tryParse(json['totalRevenue']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ProductAnalytics {
  final List<TopSellingProduct> topSellingProducts;
  final int lowStockCount;
  final int totalProductsCount;

  const ProductAnalytics({
    required this.topSellingProducts,
    required this.lowStockCount,
    required this.totalProductsCount,
  });

  factory ProductAnalytics.fromJson(Map<String, dynamic> json) {
    final list = (json['topSellingProducts'] is List)
        ? (json['topSellingProducts'] as List)
            .map((item) => TopSellingProduct.fromJson(item as Map<String, dynamic>))
            .toList()
        : <TopSellingProduct>[];

    return ProductAnalytics(
      topSellingProducts: list,
      lowStockCount: int.tryParse(json['lowStockCount']?.toString() ?? '0') ?? 0,
      totalProductsCount: int.tryParse(json['totalProductsCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class TopSellingProduct {
  final String productId;
  final String name;
  final String sku;
  final int totalQuantitySold;
  final double totalRevenue;

  const TopSellingProduct({
    required this.productId,
    required this.name,
    required this.sku,
    required this.totalQuantitySold,
    required this.totalRevenue,
  });

  factory TopSellingProduct.fromJson(Map<String, dynamic> json) {
    return TopSellingProduct(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Product',
      sku: json['sku']?.toString() ?? '',
      totalQuantitySold: int.tryParse(json['totalQuantitySold']?.toString() ?? '0') ?? 0,
      totalRevenue: double.tryParse(json['totalRevenue']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class CustomerAnalytics {
  final int totalCustomers;
  final int newCustomersInPeriod;
  final List<TopCustomer> topCustomers;
  final OutstandingDebtSummary outstandingDebt;

  const CustomerAnalytics({
    required this.totalCustomers,
    required this.newCustomersInPeriod,
    required this.topCustomers,
    required this.outstandingDebt,
  });

  factory CustomerAnalytics.fromJson(Map<String, dynamic> json) {
    final topList = (json['topCustomers'] is List)
        ? (json['topCustomers'] as List)
            .map((item) => TopCustomer.fromJson(item as Map<String, dynamic>))
            .toList()
        : <TopCustomer>[];

    return CustomerAnalytics(
      totalCustomers: int.tryParse(json['totalCustomers']?.toString() ?? '0') ?? 0,
      newCustomersInPeriod: int.tryParse(json['newCustomersInPeriod']?.toString() ?? '0') ?? 0,
      topCustomers: topList,
      outstandingDebt: OutstandingDebtSummary.fromJson(json['outstandingDebt'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class TopCustomer {
  final String customerId;
  final String name;
  final String? email;
  final String? phone;
  final int salesCount;
  final double totalSpent;

  const TopCustomer({
    required this.customerId,
    required this.name,
    this.email,
    this.phone,
    required this.salesCount,
    required this.totalSpent,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      customerId: json['customerId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Customer',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      salesCount: int.tryParse(json['salesCount']?.toString() ?? '0') ?? 0,
      totalSpent: double.tryParse(json['totalSpent']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class OutstandingDebtSummary {
  final int count;
  final double totalAmount;

  const OutstandingDebtSummary({
    required this.count,
    required this.totalAmount,
  });

  factory OutstandingDebtSummary.fromJson(Map<String, dynamic> json) {
    return OutstandingDebtSummary(
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
    );
  }
}
