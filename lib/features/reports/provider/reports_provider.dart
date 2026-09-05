import 'package:flutter/foundation.dart';
import '../data/reports_repository.dart';
import '../models/analytics_models.dart';
import '../models/report_models.dart';

class ReportsProvider extends ChangeNotifier {
  final ReportsRepository _repository = ReportsRepository();

  ShopAnalytics? _analytics;
  ReportOverview _overview = const ReportOverview(totalProfit: 21190, revenue: 18300, sales: 17432);
  List<BestSellingCategoryItem> _categories = [];
  List<ProfitRevenuePoint> _chartData = [];
  List<BestSellingProductItem> _products = [];
  String _selectedPeriod = 'weekly'; // 'daily' | 'weekly' | 'monthly' | 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int _selectedPointIndex = 0;
  bool _isLoading = false;
  String? _error;

  ShopAnalytics? get analytics => _analytics;
  SalesAnalytics? get salesAnalytics => _analytics?.salesAnalytics;
  ProductAnalytics? get productAnalytics => _analytics?.productAnalytics;
  CustomerAnalytics? get customerAnalytics => _analytics?.customerAnalytics;
  ReportOverview get overview => _overview;
  List<BestSellingCategoryItem> get categories => _categories;
  List<ProfitRevenuePoint> get chartData => _chartData;
  List<BestSellingProductItem> get products => _products;
  String get selectedPeriod => _selectedPeriod;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  int get selectedPointIndex => _selectedPointIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReports({
    required String shopId,
    String? token,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    if (period != null) _selectedPeriod = period;
    if (startDate != null) _customStartDate = startDate;
    if (endDate != null) _customEndDate = endDate;
    notifyListeners();

    final formattedStart = _customStartDate != null
        ? '${_customStartDate!.year.toString().padLeft(4, '0')}-${_customStartDate!.month.toString().padLeft(2, '0')}-${_customStartDate!.day.toString().padLeft(2, '0')}'
        : null;
    final formattedEnd = _customEndDate != null
        ? '${_customEndDate!.year.toString().padLeft(4, '0')}-${_customEndDate!.month.toString().padLeft(2, '0')}-${_customEndDate!.day.toString().padLeft(2, '0')}'
        : null;

    if (token != null && token.isNotEmpty && shopId.isNotEmpty) {
      final analyticsRes = await _repository.getShopAnalytics(
        shopId: shopId,
        token: token,
        period: _selectedPeriod,
        startDate: formattedStart,
        endDate: formattedEnd,
      );

      if (analyticsRes['success'] == true && analyticsRes['data'] is ShopAnalytics) {
        _analytics = analyticsRes['data'] as ShopAnalytics;

        // Map backend analytics to UI overview & charts
        final sa = _analytics!.salesAnalytics;
        _overview = ReportOverview(
          totalProfit: sa.totalRevenue * 0.35, // Estimated gross margin
          revenue: sa.totalRevenue,
          sales: sa.totalSalesCount.toDouble(),
        );

        if (sa.salesTrend.isNotEmpty) {
          _chartData = sa.salesTrend.map((st) {
            String label = st.date;
            if (label.length >= 10) {
              label = label.substring(5); // e.g. '08-24'
            }
            return ProfitRevenuePoint(
              label: label,
              revenue: st.totalRevenue,
              profit: st.totalRevenue * 0.35,
            );
          }).toList();
          _selectedPointIndex = _chartData.length - 1;
        }

        // Top Selling Products
        _products = _analytics!.productAnalytics.topSellingProducts.map((p) {
          return BestSellingProductItem(
            name: p.name,
            productId: p.sku.isNotEmpty ? p.sku : (p.productId.length > 6 ? p.productId.substring(0, 6) : p.productId),
            category: 'Top Seller',
            remainingQuantity: '${p.totalQuantitySold} Sold',
            turnover: p.totalRevenue,
            increasePercent: 5.0,
          );
        }).toList();

        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    // Fallback: Client-computed real sales calculation if backend analytics endpoint is unavailable
    final data = await _repository.fetchRealReportData(
      shopId: shopId,
      token: token,
      period: _selectedPeriod,
    );

    _overview = data['overview'] as ReportOverview;
    _categories = data['categories'] as List<BestSellingCategoryItem>;
    _products = data['products'] as List<BestSellingProductItem>;
    _chartData = data['chartData'] as List<ProfitRevenuePoint>;
    _selectedPointIndex = _chartData.isNotEmpty ? (_chartData.length > 3 ? 3 : 0) : 0;

    _isLoading = false;
    notifyListeners();
  }

  void setPeriod(
    String period, {
    required String shopId,
    String? token,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _selectedPeriod = period;
    _customStartDate = startDate;
    _customEndDate = endDate;
    loadReports(
      shopId: shopId,
      token: token,
      period: _selectedPeriod,
      startDate: _customStartDate,
      endDate: _customEndDate,
    );
  }

  void selectPoint(int index) {
    _selectedPointIndex = index;
    notifyListeners();
  }
}
