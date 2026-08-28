import '../../../core/network/api_client.dart';

class ShopRepository {
  final ApiClient _client = ApiClient();

  /// POST /shops
  /// OWNER only.
  Future<Map<String, dynamic>> createShop({
    required String name,
    required String businessType,
    required String address,
    required double taxRate,
    required String currency,
    required String language,
    required String token,
  }) {
    return _client.post(
      '/shops',
      {
        'name': name,
        'businessType': businessType,
        'address': address,
        'taxRate': taxRate,
        'currency': currency,
        'language': language,
      },
      token: token,
    );
  }

  /// GET /shops
  /// OWNER only.
  Future<Map<String, dynamic>> getShops(String token) {
    return _client.get(
      '/shops',
      token: token,
    );
  }

  /// PATCH /shops/{id}
  /// OWNER only.
  Future<Map<String, dynamic>> updateShop({
    required String shopId,
    required String token,
    String? name,
    String? address,
    double? taxRate,
    String? currency,
    String? language,
  }) {
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (taxRate != null) body['taxRate'] = taxRate;
    if (currency != null) body['currency'] = currency;
    if (language != null) body['language'] = language;

    return _client.patch(
      '/shops/$shopId',
      body,
      token: token,
    );
  }

  /// DELETE /shops/{id}
  /// OWNER only.
  Future<Map<String, dynamic>> deleteShop({
    required String shopId,
    required String token,
  }) {
    return _client.delete(
      '/shops/$shopId',
      token: token,
    );
  }
}