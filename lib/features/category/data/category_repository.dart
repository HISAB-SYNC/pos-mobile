import '../../../core/network/api_client.dart';

class CategoryRepository {
  final ApiClient _client = ApiClient();

  /// GET /shops/{shopId}/categories
  Future<Map<String, dynamic>> getCategories({
    required String shopId,
    required String token,
  }) {
    return _client.get(
      '/shops/$shopId/categories',
      token: token,
    );
  }

  /// POST /shops/{shopId}/categories
  Future<Map<String, dynamic>> createCategory({
    required String shopId,
    required String name,
    required String token,
  }) {
    return _client.post(
      '/shops/$shopId/categories',
      {
        'name': name,
      },
      token: token,
    );
  }

  /// PATCH /shops/{shopId}/categories/{id}
  Future<Map<String, dynamic>> updateCategory({
    required String shopId,
    required String categoryId,
    required String name,
    required String token,
  }) {
    return _client.patch(
      '/shops/$shopId/categories/$categoryId',
      {
        'name': name,
      },
      token: token,
    );
  }

  /// DELETE /shops/{shopId}/categories/{id}
  Future<Map<String, dynamic>> deleteCategory({
    required String shopId,
    required String categoryId,
    required String token,
  }) {
    return _client.delete(
      '/shops/$shopId/categories/$categoryId',
      token: token,
    );
  }
}