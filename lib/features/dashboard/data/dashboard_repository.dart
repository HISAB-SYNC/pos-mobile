import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_metrics.dart';

class DashboardRepository {
  final ApiClient _client = ApiClient();

  /// GET /shops/:shopId/dashboard with persistent fallback caching
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
        final data = response['data'] as Map<String, dynamic>;
        final metrics = DashboardMetrics.fromJson(data);

        // Cache latest metrics to disk
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('dashboard_metrics_$shopId', jsonEncode(data));
        } catch (e) {
          debugPrint('Error caching dashboard metrics: $e');
        }

        return {
          'success': true,
          'data': metrics,
        };
      }

      // Check cache on failure
      final cached = await _getCachedMetrics(shopId);
      if (cached != null) {
        return {'success': true, 'data': cached};
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Failed to load dashboard metrics',
      };
    } catch (e) {
      final cached = await _getCachedMetrics(shopId);
      if (cached != null) {
        return {'success': true, 'data': cached};
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<DashboardMetrics?> _getCachedMetrics(String shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('dashboard_metrics_$shopId');
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        return DashboardMetrics.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error reading cached metrics: $e');
    }
    return null;
  }
}
