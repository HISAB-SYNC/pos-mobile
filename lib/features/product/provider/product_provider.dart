import 'package:flutter/foundation.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import '../models/product_purchase.dart';
import '../models/product_adjustment.dart';
import '../models/product_history.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  List<Product> _products = [];
  Product? _selectedProduct;
  List<ProductPurchase> _purchases = [];
  List<ProductAdjustment> _adjustments = [];
  List<ProductHistory> _history = [];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products {
    var list = _products;
    if (_selectedCategory != 'All') {
      final selected = _selectedCategory.trim().toLowerCase();
      list = list.where((p) {
        final cat = p.categoryName.trim().toLowerCase();
        return cat == selected || (p.categoryId != null && p.categoryId!.toLowerCase() == selected);
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<Product> get allProducts => _products;
  Product? get selectedProduct => _selectedProduct;
  List<ProductPurchase> get purchases => _purchases;
  List<ProductAdjustment> get adjustments => _adjustments;
  List<ProductHistory> get history => _history;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<String> get availableCategories {
    final set = <String>{'All'};
    for (final p in _products) {
      if (p.categoryName.isNotEmpty) {
        set.add(p.categoryName);
      }
    }
    return set.toList();
  }

  Future<void> loadProducts({required String shopId, String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getProducts(shopId: shopId, token: token);
    _isLoading = false;

    if (result['success'] == true && result['data'] is List<Product>) {
      _products = result['data'] as List<Product>;
      if (_selectedProduct != null) {
        final found = _products.where((p) => p.id == _selectedProduct!.id);
        if (found.isNotEmpty) {
          _selectedProduct = found.first;
          _loadProductDetails(_selectedProduct!.id);
        }
      }
    } else {
      _errorMessage = result['error']?.toString() ?? 'Failed to load products';
    }

    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void selectProduct(Product product) {
    _selectedProduct = product;
    _loadProductDetails(product.id);
    notifyListeners();
  }

  void _loadProductDetails(String productId) {
    _purchases = _repository.getPurchasesForProduct(productId);
    _adjustments = _repository.getAdjustmentsForProduct(productId);
    _history = _repository.getHistoryForProduct(productId);
  }

  Future<bool> addProduct({
    required String shopId,
    String? token,
    required Product product,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.createProduct(
      shopId: shopId,
      token: token ?? '',
      product: product,
    );

    _isLoading = false;

    if (result['success'] == true && result['data'] is Product) {
      _products.insert(0, result['data'] as Product);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error']?.toString() ?? 'Failed to create product';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct({
    required String shopId,
    String? token,
    required Product product,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.updateProduct(
      shopId: shopId,
      token: token ?? '',
      productId: product.id,
      updates: product.toJson(),
    );

    _isLoading = false;

    if (result['success'] == true) {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
      if (_selectedProduct?.id == product.id) {
        _selectedProduct = product;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error']?.toString() ?? 'Failed to update product';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct({
    required String shopId,
    String? token,
    required String productId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.deleteProduct(
      shopId: shopId,
      token: token ?? '',
      productId: productId,
    );

    _isLoading = false;

    if (result['success'] == true) {
      _products.removeWhere((p) => p.id == productId);
      if (_selectedProduct?.id == productId) {
        _selectedProduct = null;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error']?.toString() ?? 'Failed to delete product';
      notifyListeners();
      return false;
    }
  }

  void addAdjustment({
    required String productId,
    required int quantityChange,
    required String reason,
    required String storeLocation,
  }) {
    final adj = ProductAdjustment(
      id: 'adj-${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      adjustmentId: 'A-${1000 + _adjustments.length + 1}',
      quantityChange: quantityChange,
      reason: reason,
      storeLocation: storeLocation,
      date: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );

    _adjustments.insert(0, adj);

    // Update product remaining stock quantity
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final old = _products[index];
      final newQty = (old.stockQuantity + quantityChange).clamp(0, 999999);
      _products[index] = old.copyWith(
        stockQuantity: newQty,
        status: newQty <= 0 ? 'Out of Stock' : (newQty <= old.lowStockThreshold ? 'Low Stock' : 'Available'),
      );
      if (_selectedProduct?.id == productId) {
        _selectedProduct = _products[index];
      }
    }

    // Add to history
    _history.insert(
      0,
      ProductHistory(
        id: 'h-${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        transactionId: 'T-${1000 + _history.length + 1}',
        type: 'Adjustment',
        quantity: quantityChange,
        storeLocation: storeLocation,
        value: (quantityChange.abs() * (_selectedProduct?.price ?? 0)),
        date: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        personName: 'Admin',
      ),
    );

    notifyListeners();
  }

  void addPurchase({
    required String productId,
    required String supplierName,
    required int quantity,
    required double unitCost,
  }) {
    final purchase = ProductPurchase(
      id: 'p-${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      purchaseId: 'P-${1000 + _purchases.length + 1}',
      supplierName: supplierName,
      quantity: quantity,
      unitCost: unitCost,
      totalCost: quantity * unitCost,
      date: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      status: 'completed',
    );

    _purchases.insert(0, purchase);

    // Increase product stock quantity
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final old = _products[index];
      final newQty = old.stockQuantity + quantity;
      _products[index] = old.copyWith(
        stockQuantity: newQty,
        status: newQty <= 0 ? 'Out of Stock' : (newQty <= old.lowStockThreshold ? 'Low Stock' : 'Available'),
      );
      if (_selectedProduct?.id == productId) {
        _selectedProduct = _products[index];
      }
    }

    // Add to history
    _history.insert(
      0,
      ProductHistory(
        id: 'h-${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        transactionId: 'T-${1000 + _history.length + 1}',
        type: 'Purchase',
        quantity: quantity,
        storeLocation: 'Main Branch',
        value: quantity * unitCost,
        date: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        personName: 'Manager',
      ),
    );

    notifyListeners();
  }
}
