import '../../../core/network/api_client.dart';
import '../models/dashboard_metrics.dart';

class DashboardRepository {
  final ApiClient _client = ApiClient();

  /// GET /shops/:shopId/dashboard
  Future<Map<String, dynamic>> getDashboardMetrics({
    required String shopId,
    required String token,
  }) async {
    try {
      final response = await _client.get(
        '/shops/$shopId/dashboard',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final metrics = DashboardMetrics.fromJson(response['data'] as Map<String, dynamic>);
        return {
          'success': true,
          'data': metrics,
        };
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Failed to load dashboard metrics',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
