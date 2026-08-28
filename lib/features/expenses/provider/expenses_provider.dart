import 'package:flutter/foundation.dart';
import '../data/expenses_repository.dart';
import '../models/expense_model.dart';

class ExpensesProvider extends ChangeNotifier {
  final ExpensesRepository _repository = ExpensesRepository();

  ExpenseSummary _summary = const ExpenseSummary();
  List<ShopExpense> _expenses = [];
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  String _selectedStatusFilter = 'All';
  bool _isLoading = false;

  ExpenseSummary get summary => _summary;
  List<ShopExpense> get expenses {
    var list = _expenses;
    if (_selectedCategoryFilter != 'All') {
      list = list.where((e) => e.category.toLowerCase() == _selectedCategoryFilter.toLowerCase()).toList();
    }
    if (_selectedStatusFilter != 'All') {
      list = list.where((e) => e.status.toLowerCase() == _selectedStatusFilter.toLowerCase()).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) =>
          e.description.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.paymentMethod.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  String get searchQuery => _searchQuery;
  String get selectedCategoryFilter => _selectedCategoryFilter;
  String get selectedStatusFilter => _selectedStatusFilter;
  bool get isLoading => _isLoading;

  Future<void> loadExpenses({required String shopId, String? token}) async {
    _isLoading = true;
    notifyListeners();

    _summary = await _repository.getSummary(shopId: shopId, token: token);
    _expenses = await _repository.getExpenses(shopId: shopId, token: token);

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  Future<bool> createExpense({
    required String shopId,
    String? token,
    required ShopExpense expense,
  }) async {
    _isLoading = true;
    notifyListeners();

    final created = await _repository.createExpense(
      shopId: shopId,
      token: token,
      expense: expense,
    );

    _expenses.insert(0, created);
    _summary = await _repository.getSummary(shopId: shopId, token: token);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> updateExpense({
    required String shopId,
    String? token,
    required ShopExpense expense,
  }) async {
    _isLoading = true;
    notifyListeners();

    final updated = await _repository.updateExpense(
      shopId: shopId,
      token: token,
      expense: expense,
    );

    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) _expenses[idx] = updated;
    _summary = await _repository.getSummary(shopId: shopId, token: token);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteExpense({
    required String shopId,
    String? token,
    required String expenseId,
  }) async {
    _isLoading = true;
    notifyListeners();

    await _repository.deleteExpense(
      shopId: shopId,
      token: token,
      expenseId: expenseId,
    );

    _expenses.removeWhere((e) => e.id == expenseId);
    _summary = await _repository.getSummary(shopId: shopId, token: token);

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
