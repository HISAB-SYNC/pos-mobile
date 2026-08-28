import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/customer_model.dart';
import '../models/debt_model.dart';

class CustomerRepository {
  final ApiClient _client = ApiClient();
  final Map<String, List<Customer>> _shopCustomerMap = {};

  Future<void> _loadCached(String shopId) async {
    if (_shopCustomerMap.containsKey(shopId)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('shop_customers_$shopId');
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((item) => Customer.fromJson(item as Map<String, dynamic>))
            .toList();
        _shopCustomerMap[shopId] = list;
        return;
      }
    } catch (_) {}
    _shopCustomerMap[shopId] = [];
  }

  Future<void> _saveCached(String shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _shopCustomerMap[shopId] ?? [];
      final encoded = jsonEncode(list.map((c) => c.toJson()).toList());
      await prefs.setString('shop_customers_$shopId', encoded);
    } catch (_) {}
  }

  /// GET /shops/:shopId/customers
  Future<List<Customer>> getCustomers({
    required String shopId,
    String? token,
    String? search,
    String? filter, // 'All' | 'With debt' | 'No debt'
  }) async {
    if (token != null && token.isNotEmpty) {
      try {
        final queryParams = <String, String>{};
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
        }

        final uri = queryParams.isEmpty
            ? '/shops/$shopId/customers'
            : '/shops/$shopId/customers?${Uri(queryParameters: queryParams).query}';

        final response = await _client.get(uri, token: token);
        if (response['success'] == true && response['data'] is List) {
          final liveList = (response['data'] as List)
              .map((item) => Customer.fromJson(item as Map<String, dynamic>))
              .toList();
          _shopCustomerMap[shopId] = liveList;
          await _saveCached(shopId);

          var list = List<Customer>.from(liveList);
          if (filter == 'With debt') {
            list = list.where((c) => c.hasDebt).toList();
          } else if (filter == 'No debt') {
            list = list.where((c) => !c.hasDebt).toList();
          }
          return list;
        }
      } catch (_) {}
    }

    await _loadCached(shopId);
    var list = List<Customer>.from(_shopCustomerMap[shopId] ?? []);

    if (filter == 'With debt') {
      list = list.where((c) => c.hasDebt).toList();
    } else if (filter == 'No debt') {
      list = list.where((c) => !c.hasDebt).toList();
    }

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.customerCode.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  /// POST /shops/:shopId/customers
  Future<Customer> createCustomer({
    required String shopId,
    String? token,
    required Customer customer,
  }) async {
    Customer toReturn = customer;

    if (token != null && token.isNotEmpty) {
      try {
        final body = customer.toCreateBackendJson();
        final response = await _client.post(
          '/shops/$shopId/customers',
          body,
          token: token,
        );

        if (response['success'] == true && response['data'] != null) {
          final serverData = response['data'] as Map<String, dynamic>;
          toReturn = customer.copyWith(
            id: serverData['id']?.toString() ?? customer.id,
            name: serverData['name']?.toString() ?? customer.name,
            totalDebt: double.tryParse(serverData['debtBalance']?.toString() ?? '0') ?? customer.totalDebt,
          );
        }
      } catch (_) {}
    }

    await _loadCached(shopId);
    _shopCustomerMap.putIfAbsent(shopId, () => []).insert(0, toReturn);
    await _saveCached(shopId);
    return toReturn;
  }

  /// PATCH /shops/:shopId/customers/:id
  Future<Customer> updateCustomer({
    required String shopId,
    String? token,
    required Customer customer,
  }) async {
    Customer toReturn = customer;

    if (token != null && token.isNotEmpty) {
      try {
        final body = {
          'name': customer.name,
          'phone': customer.phone,
          if (customer.email != null && customer.email!.isNotEmpty) 'email': customer.email,
          if (customer.address.isNotEmpty) 'address': customer.address,
        };

        final response = await _client.patch(
          '/shops/$shopId/customers/${customer.id}',
          body,
          token: token,
        );

        if (response['success'] == true && response['data'] != null) {
          final serverData = response['data'] as Map<String, dynamic>;
          toReturn = customer.copyWith(
            name: serverData['name']?.toString() ?? customer.name,
            phone: serverData['phone']?.toString() ?? customer.phone,
          );
        }
      } catch (_) {}
    }

    await _loadCached(shopId);
    final list = _shopCustomerMap[shopId] ?? [];
    final idx = list.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      list[idx] = toReturn;
      await _saveCached(shopId);
    }
    return toReturn;
  }

  /// GET /shops/:shopId/customers/:id
  Future<Customer?> getCustomerDetail({
    required String shopId,
    String? token,
    required String customerId,
  }) async {
    if (token != null && token.isNotEmpty) {
      try {
        final response = await _client.get(
          '/shops/$shopId/customers/$customerId',
          token: token,
        );
        if (response['success'] == true && response['data'] != null) {
          final c = Customer.fromJson(response['data'] as Map<String, dynamic>);
          await _loadCached(shopId);
          final list = _shopCustomerMap[shopId] ?? [];
          final idx = list.indexWhere((item) => item.id == customerId);
          if (idx != -1) {
            list[idx] = c;
            await _saveCached(shopId);
          }
          return c;
        }
      } catch (_) {}
    }

    await _loadCached(shopId);
    final list = _shopCustomerMap[shopId] ?? [];
    try {
      return list.firstWhere((c) => c.id == customerId);
    } catch (_) {
      return null;
    }
  }

  /// GET /shops/:shopId/debts
  Future<List<Debt>> getDebts({
    required String shopId,
    String? token,
    String? status,
    String? customerId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (customerId != null && customerId.isNotEmpty) queryParams['customerId'] = customerId;

      final uri = queryParams.isEmpty
          ? '/shops/$shopId/debts'
          : '/shops/$shopId/debts?${Uri(queryParameters: queryParams).query}';

      final response = await _client.get(uri, token: token);
      if (response['success'] == true && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => Debt.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// POST /shops/:shopId/debts (Create Standalone Debt)
  Future<Map<String, dynamic>> createStandaloneDebt({
    required String shopId,
    required String token,
    required String customerId,
    required double amount,
    String? dueDate,
    String? notes,
  }) async {
    try {
      final body = {
        'customerId': customerId,
        'amount': amount,
        if (dueDate != null && dueDate.isNotEmpty) 'dueDate': dueDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _client.post(
        '/shops/$shopId/debts',
        body,
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final created = Debt.fromJson(response['data'] as Map<String, dynamic>);
        return {'success': true, 'data': created};
      }
      return {
        'success': false,
        'error': response['error'] ?? 'Failed to create debt',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// POST /shops/:shopId/debts/:id/payments
  Future<Map<String, dynamic>> recordDebtPayment({
    required String shopId,
    required String token,
    required String debtId,
    required double amount,
  }) async {
    try {
      final body = {'amount': amount};
      final response = await _client.post(
        '/shops/$shopId/debts/$debtId/payments',
        body,
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final updated = Debt.fromJson(response['data'] as Map<String, dynamic>);
        return {'success': true, 'data': updated};
      }
      return {
        'success': false,
        'error': response['error'] ?? 'Failed to record debt payment',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> deleteCustomer({
    required String shopId,
    String? token,
    required String customerId,
  }) async {
    await _loadCached(shopId);
    final list = _shopCustomerMap[shopId] ?? [];
    list.removeWhere((c) => c.id == customerId);
    await _saveCached(shopId);
    return true;
  }

  Future<Customer?> recordPayment({
    required String shopId,
    String? token,
    required String customerId,
    required double paymentAmount,
  }) async {
    // If there is an active debt on backend, we can pay through debts endpoint
    final debts = await getDebts(shopId: shopId, token: token, customerId: customerId, status: 'PENDING');
    if (debts.isNotEmpty && token != null && token.isNotEmpty) {
      await recordDebtPayment(
        shopId: shopId,
        token: token,
        debtId: debts.first.id,
        amount: paymentAmount,
      );
      return getCustomerDetail(shopId: shopId, token: token, customerId: customerId);
    }

    await _loadCached(shopId);
    final list = _shopCustomerMap[shopId] ?? [];
    final idx = list.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      final c = list[idx];
      final newDebt = (c.totalDebt - paymentAmount).clamp(0.0, c.creditLimit);
      final updated = c.copyWith(
        totalDebt: newDebt,
        daysOverdue: newDebt == 0 ? 0 : c.daysOverdue,
        status: newDebt == 0 ? 'Active' : c.status,
      );
      list[idx] = updated;
      await _saveCached(shopId);
      return updated;
    }
    return null;
  }
}
