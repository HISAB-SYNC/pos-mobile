import '../../../core/network/api_client.dart';
import '../models/product.dart';
import '../models/product_purchase.dart';
import '../models/product_adjustment.dart';
import '../models/product_history.dart';

class ProductRepository {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getProducts({
    required String shopId,
    String? token,
    String? search,
    String? categoryId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null && categoryId.isNotEmpty) queryParams['categoryId'] = categoryId;

      final uri = queryParams.isEmpty
          ? '/shops/$shopId/products'
          : '/shops/$shopId/products?${Uri(queryParameters: queryParams).query}';

      final response = await _client.get(uri, token: token);
      if (response['success'] == true && response['data'] is List) {
        final list = (response['data'] as List)
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': list};
      }
      if (response['error'] != null) {
        return {'success': false, 'error': response['error'], 'data': <Product>[]};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'data': <Product>[]};
    }

    return {'success': true, 'data': <Product>[]};
  }

  /// GET /shops/{shopId}/products/low-stock
  Future<Map<String, dynamic>> getLowStockProducts({
    required String shopId,
    String? token,
  }) async {
    try {
      final response = await _client.get('/shops/$shopId/products/low-stock', token: token);
      if (response['success'] == true && response['data'] is List) {
        final list = (response['data'] as List)
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': list};
      }
    } catch (_) {}

    return {'success': true, 'data': <Product>[]};
  }

  Future<Map<String, dynamic>> createProduct({
    required String shopId,
    required String token,
    required Product product,
  }) async {
    try {
      final body = {
        'sku': product.sku,
        'name': product.name,
        if (product.description != null && product.description!.isNotEmpty) 'description': product.description,
        'price': product.price,
        'stockQuantity': product.stockQuantity,
        'unit': product.unit.isNotEmpty ? product.unit : 'pcs',
        'lowStockThreshold': product.lowStockThreshold,
        'minStockLevel': product.lowStockThreshold,
        'costPrice': product.buyingPrice,
        'categoryName': product.categoryName,
        if (product.categoryId != null && product.categoryId!.isNotEmpty) 'categoryId': product.categoryId,
        if (product.supplierId != null && product.supplierId!.isNotEmpty) 'supplierId': product.supplierId,
      };

      final response = await _client.post('/shops/$shopId/products', body, token: token);
      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'data': Product.fromJson(response['data'] as Map<String, dynamic>),
        };
      }
      return {
        'success': false,
        'error': response['error'] ?? 'Failed to create product',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProduct({
    required String shopId,
    required String token,
    required String productId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _client.patch(
        '/shops/$shopId/products/$productId',
        updates,
        token: token,
      );
      if (response['success'] == true) {
        return response;
      }
      return {
        'success': false,
        'error': response['error'] ?? 'Failed to update product',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteProduct({
    required String shopId,
    required String token,
    required String productId,
  }) async {
    try {
      final response = await _client.delete(
        '/shops/$shopId/products/$productId',
        token: token,
      );
      if (response['success'] == true) {
        return response;
      }
      return {
        'success': false,
        'error': response['error'] ?? 'Failed to delete product',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  List<ProductPurchase> getPurchasesForProduct(String productId) {
    return [];
  }

  List<ProductAdjustment> getAdjustmentsForProduct(String productId) {
    return [];
  }

  List<ProductHistory> getHistoryForProduct(String productId) {
    return [];
  }
}
