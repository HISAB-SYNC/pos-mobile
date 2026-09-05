import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/staff_model.dart';

class StaffRepository {
  final ApiClient _client = ApiClient();
  final Map<String, List<StaffMember>> _shopStaffMap = {};

  Future<void> _loadCachedStaff(String shopId) async {
    if (_shopStaffMap.containsKey(shopId) && _shopStaffMap[shopId]!.isNotEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Exact shop key
      final raw = prefs.getString('shop_staff_$shopId');
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
            .toList();
        _shopStaffMap[shopId] = list;
        return;
      }

      // 2. Fallback check: look for legacy 'default-shop' or 'shop_staff_all'
      final fallbackDefault = prefs.getString('shop_staff_default-shop');
      if (fallbackDefault != null && fallbackDefault.isNotEmpty) {
        final list = (jsonDecode(fallbackDefault) as List<dynamic>)
            .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _shopStaffMap[shopId] = list;
          await _saveCachedStaff(shopId);
          return;
        }
      }

      final fallbackAll = prefs.getString('shop_staff_all');
      if (fallbackAll != null && fallbackAll.isNotEmpty) {
        final list = (jsonDecode(fallbackAll) as List<dynamic>)
            .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _shopStaffMap[shopId] = list;
          await _saveCachedStaff(shopId);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading cached staff: $e');
    }

    _shopStaffMap[shopId] = [];
  }

  Future<void> _saveCachedStaff(String shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _shopStaffMap[shopId] ?? [];
      final encoded = jsonEncode(list.map((s) => s.toJson()).toList());

      // Save to shop-specific key
      await prefs.setString('shop_staff_$shopId', encoded);

      // Save to global fallback key to ensure staff is never lost across logins
      await prefs.setString('shop_staff_all', encoded);
    } catch (e) {
      debugPrint('Error saving cached staff: $e');
    }
  }

  /// GET /shops/:shopId/staff (with role, isActive, search filters)
  Future<List<StaffMember>> getStaffMembers({
    required String shopId,
    String? token,
    String? search,
    String? roleFilter,
    bool? isActive,
  }) async {
    await _loadCachedStaff(shopId);

    final bool hasValidShopUuid = shopId.isNotEmpty && shopId != 'default-shop';

    if (token != null && token.isNotEmpty && hasValidShopUuid) {
      try {
        final queryParams = <String, String>{};
        if (roleFilter != null && roleFilter != 'All' && roleFilter.isNotEmpty) {
          queryParams['role'] = roleFilter.toUpperCase().contains('ADMIN') ? 'ADMIN' : 'SALES';
        }
        if (isActive != null) {
          queryParams['isActive'] = isActive ? 'true' : 'false';
        }
        if (search != null && search.trim().isNotEmpty) {
          queryParams['search'] = search.trim();
        }

        final queryString = queryParams.isNotEmpty ? '?${Uri(queryParameters: queryParams).query}' : '';
        var response = await _client.get('/shops/$shopId/staff$queryString', token: token);

        if (response['success'] != true) {
          // Try versioned alias endpoint
          response = await _client.get('/api/v1/shops/$shopId/staff$queryString', token: token);
        }

        if (response['success'] == true && response['data'] is List) {
          final list = (response['data'] as List)
              .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
              .toList();

          _shopStaffMap[shopId] = list;
          await _saveCachedStaff(shopId);
          return list;
        }
      } catch (e) {
        debugPrint('Failed to fetch staff from server: $e');
      }
    }

    // Offline / fallback filtering from cache
    var list = List<StaffMember>.from(_shopStaffMap[shopId] ?? []);

    if (roleFilter != null && roleFilter != 'All' && roleFilter.isNotEmpty) {
      list = list.where((s) => s.role.toLowerCase().contains(roleFilter.toLowerCase())).toList();
    }

    if (isActive != null) {
      list = list.where((s) => s.isActive == isActive).toList();
    }

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          s.role.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  Future<StaffSummary> getSummary({required String shopId, String? token}) async {
    final list = await getStaffMembers(shopId: shopId, token: token);
    final total = list.length;
    final admins = list.where((s) => s.isAdmin).length;
    final sales = list.where((s) => s.isSales).length;

    return StaffSummary(
      totalMembers: total,
      shopAdmins: admins,
      shopSales: sales,
    );
  }

  /// POST /shops/:shopId/staff
  /// Request Body: { "email": "...", "password": "...", "name": "...", "role": "ADMIN" | "SALES" }
  Future<Map<String, dynamic>> createStaffMember({
    required String shopId,
    String? token,
    required StaffMember member,
    String password = 'Password@123',
  }) async {
    await _loadCachedStaff(shopId);

    final bool hasValidShopUuid = shopId.isNotEmpty && shopId != 'default-shop';
    final role = member.apiRole; // 'ADMIN' or 'SALES'

    if (token != null && token.isNotEmpty && hasValidShopUuid) {
      try {
        final body = {
          'name': member.name,
          'email': member.email,
          'password': password,
          'role': role,
        };

        // Primary endpoint: POST /shops/:shopId/staff
        var response = await _client.post(
          '/shops/$shopId/staff',
          body,
          token: token,
        );

        if (response['success'] != true) {
          // Try versioned endpoint alias
          response = await _client.post(
            '/api/v1/shops/$shopId/staff',
            body,
            token: token,
          );
        }

        if (response['success'] != true) {
          // Try legacy endpoint fallback: POST /auth/register/staff
          response = await _client.post(
            '/auth/register/staff',
            {...body, 'shopId': shopId},
            token: token,
          );
        }

        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          final created = StaffMember.fromJson(data);
          _shopStaffMap.putIfAbsent(shopId, () => []).insert(0, created);
          await _saveCachedStaff(shopId);
          return {'success': true, 'data': created};
        } else {
          return {
            'success': false,
            'error': response['error'] ?? 'Failed to register staff member on server',
          };
        }
      } catch (e) {
        return {'success': false, 'error': e.toString()};
      }
    }

    _shopStaffMap.putIfAbsent(shopId, () => []).insert(0, member);
    await _saveCachedStaff(shopId);
    return {'success': true, 'data': member};
  }

  /// DELETE /shops/:shopId/staff/:id
  Future<bool> deleteStaffMember({
    required String shopId,
    String? token,
    required String staffId,
  }) async {
    await _loadCachedStaff(shopId);

    final bool hasValidShopUuid = shopId.isNotEmpty && shopId != 'default-shop';

    if (token != null && token.isNotEmpty && hasValidShopUuid) {
      try {
        var response = await _client.delete(
          '/shops/$shopId/staff/$staffId',
          token: token,
        );

        if (response['success'] != true) {
          // Try versioned endpoint alias
          response = await _client.delete(
            '/api/v1/shops/$shopId/staff/$staffId',
            token: token,
          );
        }

        if (response['success'] == true) {
          final list = _shopStaffMap[shopId] ?? [];
          list.removeWhere((s) => s.id == staffId);
          await _saveCachedStaff(shopId);
          return true;
        }
      } catch (e) {
        debugPrint('Failed to delete staff on server: $e');
      }
    }

    // Local update fallback
    final list = _shopStaffMap[shopId] ?? [];
    list.removeWhere((s) => s.id == staffId);
    await _saveCachedStaff(shopId);
    return true;
  }

  Future<StaffMember> updateStaffMember({
    required String shopId,
    String? token,
    required StaffMember member,
  }) async {
    await _loadCachedStaff(shopId);
    final list = _shopStaffMap[shopId] ?? [];
    final idx = list.indexWhere((s) => s.id == member.id);
    if (idx != -1) {
      list[idx] = member;
      await _saveCachedStaff(shopId);
    }
    return member;
  }
}