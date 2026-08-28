import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/staff_model.dart';

class StaffRepository {
  final ApiClient _client = ApiClient();
  final Map<String, List<StaffMember>> _shopStaffMap = {};

  Future<void> _loadCachedStaff(String shopId) async {
    if (_shopStaffMap.containsKey(shopId)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('shop_staff_$shopId');
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
            .toList();
        _shopStaffMap[shopId] = list;
        return;
      }
    } catch (_) {}
    _shopStaffMap[shopId] = [];
  }

  Future<void> _saveCachedStaff(String shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _shopStaffMap[shopId] ?? [];
      final encoded = jsonEncode(list.map((s) => s.toJson()).toList());
      await prefs.setString('shop_staff_$shopId', encoded);
    } catch (_) {}
  }

  Future<StaffSummary> getSummary({required String shopId, String? token}) async {
    await _loadCachedStaff(shopId);
    final list = _shopStaffMap[shopId] ?? [];
    final total = list.length;
    final admins = list.where((s) => s.isAdmin).length;
    final sales = list.where((s) => s.isSales).length;

    return StaffSummary(
      totalMembers: total,
      shopAdmins: admins,
      shopSales: sales,
    );
  }

  Future<List<StaffMember>> getStaffMembers({
    required String shopId,
    String? token,
    String? search,
    String? roleFilter,
  }) async {
    await _loadCachedStaff(shopId);
    var list = List<StaffMember>.from(_shopStaffMap[shopId] ?? []);

    if (roleFilter != null && roleFilter != 'All' && roleFilter.isNotEmpty) {
      list = list.where((s) => s.role.toLowerCase().contains(roleFilter.toLowerCase())).toList();
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

  /// POST /auth/register/staff
  Future<Map<String, dynamic>> createStaffMember({
    required String shopId,
    String? token,
    required StaffMember member,
    String password = 'Password@123',
  }) async {
    await _loadCachedStaff(shopId);

    if (token != null && token.isNotEmpty && shopId.isNotEmpty) {
      try {
        final role = member.role.toUpperCase().contains('ADMIN') ? 'ADMIN' : 'SALES';
        final response = await _client.post(
          '/auth/register/staff',
          {
            'name': member.name,
            'email': member.email,
            'password': password,
            'role': role,
            'shopId': shopId,
          },
          token: token,
        );

        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          final created = StaffMember(
            id: data['id']?.toString() ?? member.id,
            name: data['name']?.toString() ?? member.name,
            email: data['email']?.toString() ?? member.email,
            role: data['role'] == 'ADMIN' ? 'Shop Admin' : 'Shop Sale',
            joinedDate: member.joinedDate,
            lastLogin: member.lastLogin,
            status: 'Active',
          );
          _shopStaffMap.putIfAbsent(shopId, () => []).insert(0, created);
          await _saveCachedStaff(shopId);
          return {'success': true, 'data': created};
        } else {
          return {
            'success': false,
            'error': response['error'] ?? 'Failed to register staff member',
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

  Future<bool> deleteStaffMember({
    required String shopId,
    String? token,
    required String staffId,
  }) async {
    await _loadCachedStaff(shopId);
    final list = _shopStaffMap[shopId] ?? [];
    list.removeWhere((s) => s.id == staffId);
    await _saveCachedStaff(shopId);
    return true;
  }
}