import 'package:flutter/foundation.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_metrics.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();

  DashboardMetrics _metrics = const DashboardMetrics();
  bool _isLoading = false;
  String? _errorMessage;

  DashboardMetrics get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboardMetrics({
    required String shopId,
    required String token,
    required bool isSalesRole,
  }) async {
    // Role 'SALES' is forbidden 403 by backend, so skip calling to avoid unnecessary 403 error
    if (isSalesRole) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getDashboardMetrics(
      shopId: shopId,
      token: token,
    );

    _isLoading = false;

    if (result['success'] == true && result['data'] is DashboardMetrics) {
      _metrics = result['data'] as DashboardMetrics;
    } else {
      _errorMessage = result['error']?.toString();
    }

    notifyListeners();
  }
}
