import 'package:flutter/foundation.dart';
import '../data/supplier_repository.dart';
import '../models/supplier.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierRepository _repository = SupplierRepository();

  List<Supplier> _suppliers = [];
  String _searchQuery = '';
  String _selectedTypeFilter = 'All'; // 'All' | 'Taking Return' | 'Not Taking Return'
  bool _isLoading = false;
  String? _errorMessage;

  List<Supplier> get suppliers {
    var list = _suppliers;
    if (_selectedTypeFilter != 'All') {
      list = list.where((s) => s.type.toLowerCase() == _selectedTypeFilter.toLowerCase()).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) =>
          s.name.toLowerCase().contains(q) ||
          (s.product?.toLowerCase().contains(q) ?? false) ||
          (s.phone?.toLowerCase().contains(q) ?? false) ||
          (s.email?.toLowerCase().contains(q) ?? false)).toList();
    }
    return list;
  }

  List<Supplier> get allSuppliers => _suppliers;
  String get searchQuery => _searchQuery;
  String get selectedTypeFilter => _selectedTypeFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSuppliers({required String shopId, String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getSuppliers(shopId: shopId, token: token);
    _isLoading = false;

    if (result['success'] == true && result['data'] is List<Supplier>) {
      _suppliers = result['data'] as List<Supplier>;
    } else {
      _errorMessage = result['error']?.toString() ?? 'Failed to load suppliers';
    }

    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  Future<bool> addSupplier({
    required String shopId,
    String? token,
    required Supplier supplier,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.createSupplier(
      shopId: shopId,
      token: token ?? '',
      supplier: supplier,
    );

    _isLoading = false;

    if (result['success'] == true && result['data'] is Supplier) {
      final returned = result['data'] as Supplier;
      final savedSupplier = supplier.copyWith(
        id: returned.id.isNotEmpty ? returned.id : supplier.id,
        shopId: returned.shopId.isNotEmpty ? returned.shopId : supplier.shopId,
        name: returned.name.isNotEmpty ? returned.name : supplier.name,
        contactInfo: returned.contactInfo.isNotEmpty ? returned.contactInfo : supplier.contactInfo,
        type: supplier.type,
      );
      _suppliers.insert(0, savedSupplier);
      notifyListeners();
      return true;
    }
    _errorMessage = result['error']?.toString() ?? 'Failed to create supplier';
    notifyListeners();
    return false;
  }

  Future<bool> updateSupplier({
    required String shopId,
    String? token,
    required Supplier supplier,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.updateSupplier(
      shopId: shopId,
      token: token ?? '',
      supplierId: supplier.id,
      supplier: supplier,
    );

    _isLoading = false;

    if (result['success'] == true) {
      final index = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (index != -1) {
        _suppliers[index] = supplier;
      }
      notifyListeners();
      return true;
    }

    _errorMessage = result['error']?.toString() ?? 'Failed to update supplier';
    notifyListeners();
    return false;
  }

  Future<bool> deleteSupplier({
    required String shopId,
    String? token,
    required String supplierId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.deleteSupplier(
      shopId: shopId,
      token: token ?? '',
      supplierId: supplierId,
    );

    _isLoading = false;

    if (result['success'] == true) {
      _suppliers.removeWhere((s) => s.id == supplierId);
      notifyListeners();
      return true;
    }

    _errorMessage = result['error']?.toString() ?? 'Failed to delete supplier';
    notifyListeners();
    return false;
  }
}
