import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';

class ExpensesRepository {
  final Map<String, List<ShopExpense>> _shopExpenseMap = {};

  Future<void> _loadCached(String shopId) async {
    if (_shopExpenseMap.containsKey(shopId)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('shop_expenses_$shopId');
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((item) => ShopExpense.fromJson(item as Map<String, dynamic>))
            .toList();
        _shopExpenseMap[shopId] = list;
        return;
      }
    } catch (_) {}
    _shopExpenseMap[shopId] = [];
  }

  Future<void> _saveCached(String shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _shopExpenseMap[shopId] ?? [];
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString('shop_expenses_$shopId', encoded);
    } catch (_) {}
  }

  Future<ExpenseSummary> getSummary({required String shopId, String? token}) async {
    await _loadCached(shopId);
    final list = _shopExpenseMap[shopId] ?? [];
    final total = list.fold<double>(0.0, (sum, e) => sum + e.amount);
    final pending = list
        .where((e) => e.isPending || e.isOverdue)
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    return ExpenseSummary(
      totalExpenses: total,
      growthPercent: 0.0,
      thisWeek: 0.0,
      pendingPayment: pending,
    );
  }

  Future<List<ShopExpense>> getExpenses({
    required String shopId,
    String? token,
    String? search,
    String? categoryFilter,
    String? statusFilter,
  }) async {
    await _loadCached(shopId);
    var list = List<ShopExpense>.from(_shopExpenseMap[shopId] ?? []);

    if (categoryFilter != null && categoryFilter != 'All' && categoryFilter.isNotEmpty) {
      list = list.where((e) => e.category.toLowerCase() == categoryFilter.toLowerCase()).toList();
    }

    if (statusFilter != null && statusFilter != 'All' && statusFilter.isNotEmpty) {
      list = list.where((e) => e.status.toLowerCase() == statusFilter.toLowerCase()).toList();
    }

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((e) =>
          e.description.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.paymentMethod.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  Future<ShopExpense> createExpense({
    required String shopId,
    String? token,
    required ShopExpense expense,
  }) async {
    await _loadCached(shopId);
    _shopExpenseMap.putIfAbsent(shopId, () => []).insert(0, expense);
    await _saveCached(shopId);
    return expense;
  }

  Future<ShopExpense> updateExpense({
    required String shopId,
    String? token,
    required ShopExpense expense,
  }) async {
    await _loadCached(shopId);
    final list = _shopExpenseMap[shopId] ?? [];
    final idx = list.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      list[idx] = expense;
      await _saveCached(shopId);
    }
    return expense;
  }

  Future<bool> deleteExpense({
    required String shopId,
    String? token,
    required String expenseId,
  }) async {
    await _loadCached(shopId);
    final list = _shopExpenseMap[shopId] ?? [];
    list.removeWhere((e) => e.id == expenseId);
    await _saveCached(shopId);
    return true;
  }
}
