import '../../../core/network/api_client.dart';
import '../models/supplier.dart';

class SupplierRepository {
  final ApiClient _client = ApiClient();

  /// GET /shops/:shopId/suppliers
  Future<Map<String, dynamic>> getSuppliers({
    required String shopId,
    String? token,
    String? search,
  }) async {
    final response = await _client.get('/shops/$shopId/suppliers', token: token);
    if (response['success'] == true && response['data'] is List) {
      final list = (response['data'] as List)
          .map((item) => Supplier.fromJson(item as Map<String, dynamic>))
          .toList();
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        return {
          'success': true,
          'data': list
              .where((s) =>
                  s.name.toLowerCase().contains(q) ||
                  (s.product?.toLowerCase().contains(q) ?? false) ||
                  (s.phone?.toLowerCase().contains(q) ?? false) ||
                  (s.email?.toLowerCase().contains(q) ?? false))
              .toList(),
        };
      }
      return {'success': true, 'data': list};
    }
    return {
      'success': false,
      'error': response['error'] ?? 'Failed to load suppliers',
      'data': <Supplier>[],
    };
  }

  /// POST /shops/:shopId/suppliers
  Future<Map<String, dynamic>> createSupplier({
    required String shopId,
    required String token,
    required Supplier supplier,
  }) async {
    final response = await _client.post(
      '/shops/$shopId/suppliers',
      supplier.toBackendJson(),
      token: token,
    );
    if (response['success'] == true && response['data'] != null) {
      return {
        'success': true,
        'data': Supplier.fromJson(response['data'] as Map<String, dynamic>),
      };
    }
    return {
      'success': false,
      'error': response['error'] ?? 'Failed to create supplier',
    };
  }

  /// PATCH /shops/:shopId/suppliers/:id
  Future<Map<String, dynamic>> updateSupplier({
    required String shopId,
    required String token,
    required String supplierId,
    required Supplier supplier,
  }) async {
    final response = await _client.patch(
      '/shops/$shopId/suppliers/$supplierId',
      supplier.toBackendJson(),
      token: token,
    );
    return response;
  }

  /// DELETE /shops/:shopId/suppliers/:id
  Future<Map<String, dynamic>> deleteSupplier({
    required String shopId,
    required String token,
    required String supplierId,
  }) async {
    final response = await _client.delete(
      '/shops/$shopId/suppliers/$supplierId',
      token: token,
    );
    return response;
  }
}
