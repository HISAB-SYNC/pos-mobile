class ReportOverview {
  final double totalProfit;
  final double revenue;
  final double sales;

  const ReportOverview({
    required this.totalProfit,
    required this.revenue,
    required this.sales,
  });

  factory ReportOverview.fromJson(Map<String, dynamic> json) {
    return ReportOverview(
      totalProfit: double.tryParse(json['totalProfit']?.toString() ?? '0') ?? 21190,
      revenue: double.tryParse(json['revenue']?.toString() ?? '0') ?? 18300,
      sales: double.tryParse(json['sales']?.toString() ?? '0') ?? 17432,
    );
  }
}

class BestSellingCategoryItem {
  final String category;
  final double turnover;
  final double increasePercent;

  const BestSellingCategoryItem({
    required this.category,
    required this.turnover,
    required this.increasePercent,
  });
}

class ProfitRevenuePoint {
  final String label; // 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'
  final double revenue;
  final double profit;

  const ProfitRevenuePoint({
    required this.label,
    required this.revenue,
    required this.profit,
  });
}

class BestSellingProductItem {
  final String name;
  final String productId;
  final String category;
  final String remainingQuantity;
  final double turnover;
  final double increasePercent;

  const BestSellingProductItem({
    required this.name,
    required this.productId,
    required this.category,
    required this.remainingQuantity,
    required this.turnover,
    required this.increasePercent,
  });
}
