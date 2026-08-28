import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Restores saved selected shop from local storage on app launch.
  Future<void> initShop() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedShopJson = prefs.getString('selected_shop');
      if (savedShopJson != null) {
        final map = jsonDecode(savedShopJson) as Map<String, dynamic>;
        _selectedShop = Shop.fromJson(map);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring selected shop: $e');
    }
  }

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
        _saveSelectedShop();
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
      _saveSelectedShop();

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

    if (response['success'] == true && response['data'] != null) {
      final returnedData = response['data'] as Map<String, dynamic>;
      final updatedShop = Shop.fromJson(returnedData);

      final index = _shops.indexWhere((s) => s.id == shopId);
      final existingShop = index != -1 ? _shops[index] : _selectedShop;

      final mergedShop = existingShop != null
          ? existingShop.copyWith(
              name: updatedShop.name.isNotEmpty ? updatedShop.name : existingShop.name,
              address: updatedShop.address.isNotEmpty ? updatedShop.address : existingShop.address,
              businessType: updatedShop.businessType.isNotEmpty ? updatedShop.businessType : existingShop.businessType,
              taxRate: returnedData['taxRate'] != null ? updatedShop.taxRate : existingShop.taxRate,
              currency: updatedShop.currency.isNotEmpty ? updatedShop.currency : existingShop.currency,
              language: updatedShop.language.isNotEmpty ? updatedShop.language : existingShop.language,
            )
          : updatedShop;

      if (index != -1) {
        _shops[index] = mergedShop;
      }
      if (_selectedShop?.id == shopId) {
        _selectedShop = mergedShop;
        _saveSelectedShop();
      }

      notifyListeners();
      return true;
    }

    _errorMessage =
        response['error'] as String? ?? 'Failed to update shop';

    notifyListeners();
    return false;
  }

  Future<bool> deleteShop({
    required String token,
    required String shopId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _repository.deleteShop(
      shopId: shopId,
      token: token,
    );

    _isLoading = false;

    if (response['success'] == true) {
      _shops.removeWhere((s) => s.id == shopId);
      if (_selectedShop?.id == shopId) {
        _selectedShop = _shops.isNotEmpty ? _shops.first : null;
        _saveSelectedShop();
      }
      notifyListeners();
      return true;
    }

    _errorMessage = response['error'] as String? ?? 'Failed to delete shop';
    notifyListeners();
    return false;
  }

  void selectShop(Shop shop) {
    _selectedShop = shop;
    _saveSelectedShop();
    notifyListeners();
  }

  void setShopForStaff({required String shopId, String name = 'My Shop'}) {
    _selectedShop = Shop(
      id: shopId,
      name: name,
      businessType: 'Retail',
      address: '',
      taxRate: 15.0,
      currency: 'ETB',
      language: 'en',
      ownerId: '',
      createdAt: '',
      updatedAt: '',
    );
    _saveSelectedShop();
    notifyListeners();
  }

  Future<void> _saveSelectedShop() async {
    if (_selectedShop == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_shop', jsonEncode(_selectedShop!.toJson()));
    } catch (e) {
      debugPrint('Error saving selected shop: $e');
    }
  }

  Future<void> clear() async {
    _shops = [];
    _selectedShop = null;
    _errorMessage = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_shop');
    } catch (e) {
      debugPrint('Error clearing selected shop: $e');
    }
    notifyListeners();
  }
}