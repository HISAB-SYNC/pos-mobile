import 'package:flutter/foundation.dart';
import '../data/customer_repository.dart';
import '../models/customer_model.dart';
import '../models/debt_model.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();

  List<Customer> _customers = [];
  List<Debt> _debts = [];
  Customer? _selectedCustomer;
  String _searchQuery = '';
  String _selectedDebtFilter = 'All Customers'; // 'All Customers' | 'With debt' | 'No debt'
  bool _isLoading = false;

  List<Customer> get customers {
    var list = _customers;
    if (_selectedDebtFilter == 'With debt') {
      list = list.where((c) => c.hasDebt).toList();
    } else if (_selectedDebtFilter == 'No debt') {
      list = list.where((c) => !c.hasDebt).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.customerCode.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<Customer> get allCustomers => _customers;
  List<Debt> get debts => _debts;
  Customer? get selectedCustomer => _selectedCustomer;
  String get searchQuery => _searchQuery;
  String get selectedDebtFilter => _selectedDebtFilter;
  bool get isLoading => _isLoading;

  Future<void> loadCustomers({required String shopId, String? token}) async {
    _isLoading = true;
    notifyListeners();

    _customers = await _repository.getCustomers(shopId: shopId, token: token);
    if (_selectedCustomer != null) {
      final found = _customers.firstWhere((c) => c.id == _selectedCustomer!.id, orElse: () => _selectedCustomer!);
      _selectedCustomer = found;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDebtFilter(String filter) {
    _selectedDebtFilter = filter;
    notifyListeners();
  }

  Future<Customer?> loadCustomerDetail({
    required String shopId,
    String? token,
    required String customerId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final detail = await _repository.getCustomerDetail(
      shopId: shopId,
      token: token,
      customerId: customerId,
    );

    if (detail != null) {
      _selectedCustomer = detail;
      final idx = _customers.indexWhere((c) => c.id == customerId);
      if (idx != -1) {
        _customers[idx] = detail;
      }
    }

    _isLoading = false;
    notifyListeners();
    return detail;
  }

  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  Future<bool> createCustomer({
    required String shopId,
    String? token,
    required Customer customer,
  }) async {
    _isLoading = true;
    notifyListeners();

    final created = await _repository.createCustomer(
      shopId: shopId,
      token: token,
      customer: customer,
    );

    _customers.insert(0, created);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> updateCustomer({
    required String shopId,
    String? token,
    required Customer customer,
  }) async {
    _isLoading = true;
    notifyListeners();

    final updated = await _repository.updateCustomer(
      shopId: shopId,
      token: token,
      customer: customer,
    );

    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) _customers[idx] = updated;
    if (_selectedCustomer?.id == customer.id) _selectedCustomer = updated;

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteCustomer({
    required String shopId,
    String? token,
    required String customerId,
  }) async {
    _isLoading = true;
    notifyListeners();

    await _repository.deleteCustomer(
      shopId: shopId,
      token: token,
      customerId: customerId,
    );

    _customers.removeWhere((c) => c.id == customerId);
    if (_selectedCustomer?.id == customerId) _selectedCustomer = null;

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> loadDebts({
    required String shopId,
    String? token,
    String? status,
    String? customerId,
  }) async {
    _debts = await _repository.getDebts(
      shopId: shopId,
      token: token,
      status: status,
      customerId: customerId,
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>> createStandaloneDebt({
    required String shopId,
    required String token,
    required String customerId,
    required double amount,
    String? dueDate,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await _repository.createStandaloneDebt(
      shopId: shopId,
      token: token,
      customerId: customerId,
      amount: amount,
      dueDate: dueDate,
      notes: notes,
    );

    if (res['success'] == true && res['data'] is Debt) {
      final createdDebt = res['data'] as Debt;
      _debts.insert(0, createdDebt);
      await loadCustomerDetail(shopId: shopId, token: token, customerId: customerId);
    }

    _isLoading = false;
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> recordDebtPayment({
    required String shopId,
    required String token,
    required String debtId,
    required String customerId,
    required double amount,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await _repository.recordDebtPayment(
      shopId: shopId,
      token: token,
      debtId: debtId,
      amount: amount,
    );

    if (res['success'] == true && res['data'] is Debt) {
      final updatedDebt = res['data'] as Debt;
      final idx = _debts.indexWhere((d) => d.id == debtId);
      if (idx != -1) {
        _debts[idx] = updatedDebt;
      }
      await loadCustomerDetail(shopId: shopId, token: token, customerId: customerId);
    }

    _isLoading = false;
    notifyListeners();
    return res;
  }

  Future<bool> recordPayment({
    required String shopId,
    String? token,
    required String customerId,
    required double amount,
  }) async {
    _isLoading = true;
    notifyListeners();

    final updated = await _repository.recordPayment(
      shopId: shopId,
      token: token,
      customerId: customerId,
      paymentAmount: amount,
    );

    if (updated != null) {
      final idx = _customers.indexWhere((c) => c.id == customerId);
      if (idx != -1) _customers[idx] = updated;
      if (_selectedCustomer?.id == customerId) _selectedCustomer = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
