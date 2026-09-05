import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/expense_model.dart';

class ExpensesRepository {
  final ApiClient _client = ApiClient();
  final Map<String, List<ShopExpense>> _shopExpenseMap = {};
  final Map<String, double> _shopTotalAmountMap = {};

  Future<void> _loadCached(String shopId) async {
    if (_shopExpenseMap.containsKey(shopId) && _shopExpenseMap[shopId]!.isNotEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Try exact shop ID key
      final raw = prefs.getString('shop_expenses_$shopId');
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((item) => ShopExpense.fromJson(item as Map<String, dynamic>))
            .toList();
        _shopExpenseMap[shopId] = list;
        return;
      }

      // 2. Fallback check: look for legacy 'default-shop' or 'shop_expenses_all'
      final fallbackDefault = prefs.getString('shop_expenses_default-shop');
      if (fallbackDefault != null && fallbackDefault.isNotEmpty) {
        final list = (jsonDecode(fallbackDefault) as List<dynamic>)
            .map((item) => ShopExpense.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _shopExpenseMap[shopId] = list;
          await _saveCached(shopId);
          return;
        }
      }

      final fallbackAll = prefs.getString('shop_expenses_all');
      if (fallbackAll != null && fallbackAll.isNotEmpty) {
        final list = (jsonDecode(fallbackAll) as List<dynamic>)
            .map((item) => ShopExpense.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _shopExpenseMap[shopId] = list;
          await _saveCached(shopId);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading cached expenses: $e');
    }

    _shopExpenseMap[shopId] = [];
  }

  Future<void> _saveCached(String shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _shopExpenseMap[shopId] ?? [];
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());

      // Save to shop-specific key
      await prefs.setString('shop_expenses_$shopId', encoded);

      // Save to global fallback key to ensure data is never lost across logins
      await prefs.setString('shop_expenses_all', encoded);
    } catch (e) {
      debugPrint('Error saving cached expenses: $e');
    }
  }

  /// GET /shops/:shopId/expenses (with category, paymentMethod, startDate, endDate, search filters)
  Future<List<ShopExpense>> getExpenses({
    required String shopId,
    String? token,
    String? search,
    String? categoryFilter,
    String? paymentMethodFilter,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    await _loadCached(shopId);

    final bool hasValidShopUuid = shopId.isNotEmpty && shopId != 'default-shop';

    if (token != null && token.isNotEmpty && hasValidShopUuid) {
      try {
        final queryParams = <String, String>{};
        if (categoryFilter != null && categoryFilter != 'All' && categoryFilter.isNotEmpty) {
          queryParams['category'] = categoryFilter;
        }
        if (paymentMethodFilter != null && paymentMethodFilter != 'All' && paymentMethodFilter.isNotEmpty) {
          queryParams['paymentMethod'] = ShopExpense.normalizePaymentMethod(paymentMethodFilter);
        }
        if (startDate != null && startDate.isNotEmpty) {
          queryParams['startDate'] = startDate;
        }
        if (endDate != null && endDate.isNotEmpty) {
          queryParams['endDate'] = endDate;
        }
        if (search != null && search.trim().isNotEmpty) {
          queryParams['search'] = search.trim();
        }
        if (page > 1) {
          queryParams['page'] = page.toString();
        }
        if (limit != 50) {
          queryParams['limit'] = limit.toString();
        }

        final queryString = queryParams.isNotEmpty ? '?${Uri(queryParameters: queryParams).query}' : '';
        var response = await _client.get('/shops/$shopId/expenses$queryString', token: token);

        if (response['success'] != true) {
          // Try versioned endpoint alias
          response = await _client.get('/api/v1/shops/$shopId/expenses$queryString', token: token);
        }

        if (response['success'] == true && response['data'] != null) {
          final data = response['data'];
          List<dynamic> items = [];

          if (data is Map<String, dynamic>) {
            if (data['expenses'] is List) {
              items = data['expenses'] as List;
            }
            if (data['totalAmount'] != null) {
              final rawTotal = data['totalAmount'];
              _shopTotalAmountMap[shopId] = rawTotal is num
                  ? rawTotal.toDouble()
                  : double.tryParse(rawTotal.toString()) ?? 0.0;
            }
          } else if (data is List) {
            items = data;
          }

          final list = items
              .map((item) => ShopExpense.fromJson(item as Map<String, dynamic>))
              .toList();

          _shopExpenseMap[shopId] = list;
          await _saveCached(shopId);
          return list;
        }
      } catch (e) {
        debugPrint('Failed to fetch expenses from server: $e');
      }
    }

    // Cache fallback with client-side filtering
    var list = List<ShopExpense>.from(_shopExpenseMap[shopId] ?? []);

    if (categoryFilter != null && categoryFilter != 'All' && categoryFilter.isNotEmpty) {
      list = list.where((e) => e.category.toLowerCase() == categoryFilter.toLowerCase()).toList();
    }

    if (paymentMethodFilter != null && paymentMethodFilter != 'All' && paymentMethodFilter.isNotEmpty) {
      final norm = ShopExpense.normalizePaymentMethod(paymentMethodFilter);
      list = list.where((e) => e.paymentMethod == norm).toList();
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

  Future<ExpenseSummary> getSummary({required String shopId, String? token}) async {
    final list = await getExpenses(shopId: shopId, token: token);

    // Prefer backend totalAmount if returned, otherwise sum the list
    final double serverTotal = _shopTotalAmountMap[shopId] ?? 0.0;
    final double computedTotal = list.fold<double>(0.0, (sum, e) => sum + e.amount);
    final double total = serverTotal > 0.0 ? serverTotal : computedTotal;

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final double thisWeek = list.where((e) {
      try {
        final d = DateTime.parse(e.expenseDate);
        return d.isAfter(sevenDaysAgo);
      } catch (_) {
        return false;
      }
    }).fold<double>(0.0, (sum, e) => sum + e.amount);

    final double pending = list
        .where((e) => e.isPending || e.isOverdue)
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    return ExpenseSummary(
      totalExpenses: total,
      growthPercent: 0.0,
      thisWeek: thisWeek,
      pendingPayment: pending,
      totalCount: list.length,
    );
  }

  /// POST /shops/:shopId/expenses
  /// Request Body: { "category": "...", "amount": 1500.00, "paymentMethod": "CASH"|"CARD"|"MOBILE", "description": "...", "expenseDate": "..." }
  Future<Map<String, dynamic>> createExpense({
    required String shopId,
    String? token,
    required ShopExpense expense,
  }) async {
    await _loadCached(shopId);

    final bool hasValidShopUuid = shopId.isNotEmpty && shopId != 'default-shop';

    if (token != null && token.isNotEmpty && hasValidShopUuid) {
      try {
        final body = <String, dynamic>{
          'category': expense.category,
          'amount': expense.amount,
          'paymentMethod': expense.paymentMethod,
          'description': expense.description,
          'expenseDate': expense.expenseDate,
        };

        var response = await _client.post(
          '/shops/$shopId/expenses',
          body,
          token: token,
        );

        if (response['success'] != true) {
          // Try versioned endpoint alias
          response = await _client.post(
            '/api/v1/shops/$shopId/expenses',
            body,
            token: token,
          );
        }

        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          final created = ShopExpense.fromJson(data);
          _shopExpenseMap.putIfAbsent(shopId, () => []).insert(0, created);
          await _saveCached(shopId);
          return {'success': true, 'data': created};
        } else {
          return {
            'success': false,
            'error': response['error'] ?? 'Failed to record expense on server',
          };
        }
      } catch (e) {
        return {'success': false, 'error': e.toString()};
      }
    }

    _shopExpenseMap.putIfAbsent(shopId, () => []).insert(0, expense);
    await _saveCached(shopId);
    return {'success': true, 'data': expense};
  }

  /// PATCH /shops/:shopId/expenses/:id
  Future<Map<String, dynamic>> updateExpense({
    required String shopId,
    String? token,
    required ShopExpense expense,
  }) async {
    await _loadCached(shopId);

    final bool hasValidShopUuid = shopId.isNotEmpty && shopId != 'default-shop';

    if (token != null && token.isNotEmpty && hasValidShopUuid) {
      try {
        final body = <String, dynamic>{
          'category': expense.category,
          'amount': expense.amount,
          'paymentMethod': expense.paymentMethod,
          'description': expense.description,
          'expenseDate': expense.expenseDate,
        };

        var response = await _client.patch(
          '/shops/$shopId/expenses/${expense.id}',
          body,
          token: token,
        );

        if (response['success'] != true) {
          // Try versioned endpoint alias
          response = await _client.patch(
            '/api/v1/shops/$shopId/expenses/${expense.id}',
            body,
            token: token,
          );
        }

        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          final updated = ShopExpense.fromJson(data);
          final list = _shopExpenseMap[shopId] ?? [];
          final idx = list.indexWhere((e) => e.id == expense.id);
          if (idx != -1) {
            list[idx] = updated;
          }
          await _saveCached(shopId);
          return {'success': true, 'data': updated};
        } else {
          return {
            'success': false,
            'error': response['error'] ?? 'Failed to update expense on server',
          };
        }
      } catch (e) {
        return {'success': false, 'error': e.toString()};
      }
    }

    final list = _shopExpenseMap[shopId] ?? [];
    final idx = list.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      list[idx] = expense;
      await _saveCached(shopId);
    }
    return {'success': true, 'data': expense};
  }

  /// DELETE /shops/:shopId/expenses/:id
  Future<bool> deleteExpense({
    required String shopId,
    String? token,
    required String expenseId,
  }) async {
    await _loadCached(shopId);

    final bool hasValidShopUuid = shopId.isNotEmpty && shopId != 'default-shop';

    if (token != null && token.isNotEmpty && hasValidShopUuid) {
      try {
        var response = await _client.delete(
          '/shops/$shopId/expenses/$expenseId',
          token: token,
        );

        if (response['success'] != true) {
          // Try versioned endpoint alias
          response = await _client.delete(
            '/api/v1/shops/$shopId/expenses/$expenseId',
            token: token,
          );
        }

        if (response['success'] == true) {
          final list = _shopExpenseMap[shopId] ?? [];
          list.removeWhere((e) => e.id == expenseId);
          await _saveCached(shopId);
          return true;
        }
      } catch (e) {
        debugPrint('Failed to delete expense on server: $e');
      }
    }

    final list = _shopExpenseMap[shopId] ?? [];
    list.removeWhere((e) => e.id == expenseId);
    await _saveCached(shopId);
    return true;
  }
}
