import 'package:flutter/foundation.dart';
import '../data/reports_repository.dart';
import '../models/report_models.dart';

class ReportsProvider extends ChangeNotifier {
  final ReportsRepository _repository = ReportsRepository();

  ReportOverview _overview = const ReportOverview(totalProfit: 21190, revenue: 18300, sales: 17432);
  List<BestSellingCategoryItem> _categories = [];
  List<ProfitRevenuePoint> _chartData = [];
  List<BestSellingProductItem> _products = [];
  String _selectedPeriod = 'Monthly'; // 'Monthly' | 'Weekly'
  int _selectedPointIndex = 3; // Highlight 'Dec' by default
  bool _isLoading = false;

  ReportOverview get overview => _overview;
  List<BestSellingCategoryItem> get categories => _categories;
  List<ProfitRevenuePoint> get chartData => _chartData;
  List<BestSellingProductItem> get products => _products;
  String get selectedPeriod => _selectedPeriod;
  int get selectedPointIndex => _selectedPointIndex;
  bool get isLoading => _isLoading;

  Future<void> loadReports({required String shopId, String? token}) async {
    _isLoading = true;
    notifyListeners();

    final data = await _repository.fetchRealReportData(
      shopId: shopId,
      token: token,
      period: _selectedPeriod,
    );

    _overview = data['overview'] as ReportOverview;
    _categories = data['categories'] as List<BestSellingCategoryItem>;
    _products = data['products'] as List<BestSellingProductItem>;
    _chartData = data['chartData'] as List<ProfitRevenuePoint>;
    _selectedPointIndex = _chartData.length > 3 ? 3 : 0;

    _isLoading = false;
    notifyListeners();
  }

  void setPeriod(String period, {required String shopId, String? token}) async {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;

    final data = await _repository.fetchRealReportData(
      shopId: shopId,
      token: token,
      period: _selectedPeriod,
    );
    _chartData = data['chartData'] as List<ProfitRevenuePoint>;
    _selectedPointIndex = _chartData.length > 3 ? 3 : 0;
    notifyListeners();
  }

  void selectPoint(int index) {
    _selectedPointIndex = index;
    notifyListeners();
  }
}
