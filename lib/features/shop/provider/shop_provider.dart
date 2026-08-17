import 'package:flutter/foundation.dart';

import '../data/shop_repository.dart';
import '../models/shop.dart';

class ShopProvider extends ChangeNotifier {
  final ShopRepository _repository = ShopRepository();

  List<Shop> _shops = [];
  Shop? _selectedShop;

  bool _isLoading = false;
  String? _errorMessage;

  List<Shop> get shops => _shops;
  Shop? get selectedShop => _selectedShop;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> loadShops(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _repository.getShops(token);

    _isLoading = false;

    if (response['success'] == true) {
      final data = response['data'] as List<dynamic>;

      _shops = data
          .map(
            (item) => Shop.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();

      if (_shops.isNotEmpty) {
        _selectedShop ??= _shops.first;
      }

      notifyListeners();
      return true;
    }

    _errorMessage =
        response['error'] as String? ?? 'Failed to load shops';

    notifyListeners();
    return false;
  }

  Future<bool> createShop({
    required String token,
    required String name,
    required String businessType,
    required String address,
    required double taxRate,
    required String currency,
    required String language,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _repository.createShop(
      name: name,
      businessType: businessType,
      address: address,
      taxRate: taxRate,
      currency: currency,
      language: language,
      token: token,
    );

    _isLoading = false;

    if (response['success'] == true) {
      final shop = Shop.fromJson(
        response['data'] as Map<String, dynamic>,
      );

      _shops.add(shop);
      _selectedShop = shop;

      notifyListeners();
      return true;
    }

    _errorMessage =
        response['error'] as String? ?? 'Failed to create shop';

    notifyListeners();
    return false;
  }

  Future<bool> updateShop({
    required String token,
    required String shopId,
    String? name,
    String? address,
    double? taxRate,
    String? currency,
    String? language,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _repository.updateShop(
      shopId: shopId,
      token: token,
      name: name,
      address: address,
      taxRate: taxRate,
      currency: currency,
      language: language,
    );

    _isLoading = false;

    if (response['success'] == true) {
      final updatedShop = Shop.fromJson(
        response['data'] as Map<String, dynamic>,
      );

      final index = _shops.indexWhere(
        (shop) => shop.id == updatedShop.id,
      );

      if (index != -1) {
        _shops[index] = updatedShop;
      }

      _selectedShop = updatedShop;

      notifyListeners();
      return true;
    }

    _errorMessage =
        response['error'] as String? ?? 'Failed to update shop';

    notifyListeners();
    return false;
  }

  void selectShop(Shop shop) {
    _selectedShop = shop;
    notifyListeners();
  }

  void clear() {
    _shops = [];
    _selectedShop = null;
    _errorMessage = null;
    notifyListeners();
  }
}