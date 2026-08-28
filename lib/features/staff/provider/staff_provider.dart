import 'package:flutter/foundation.dart';
import '../data/staff_repository.dart';
import '../models/staff_model.dart';

class StaffProvider extends ChangeNotifier {
  final StaffRepository _repository = StaffRepository();

  StaffSummary _summary = const StaffSummary();
  List<StaffMember> _staffMembers = [];
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';
  bool _isLoading = false;

  StaffSummary get summary => _summary;
  List<StaffMember> get staffMembers {
    var list = _staffMembers;
    if (_selectedRoleFilter != 'All') {
      list = list.where((s) => s.role.toLowerCase().contains(_selectedRoleFilter.toLowerCase())).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          s.role.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  String get searchQuery => _searchQuery;
  String get selectedRoleFilter => _selectedRoleFilter;
  bool get isLoading => _isLoading;

  Future<void> loadStaff({required String shopId, String? token}) async {
    _isLoading = true;
    notifyListeners();

    _summary = await _repository.getSummary(shopId: shopId, token: token);
    _staffMembers = await _repository.getStaffMembers(shopId: shopId, token: token);

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setRoleFilter(String role) {
    _selectedRoleFilter = role;
    notifyListeners();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> createStaffMember({
    required String shopId,
    String? token,
    required StaffMember member,
    String password = 'Password@123',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.createStaffMember(
      shopId: shopId,
      token: token,
      member: member,
      password: password,
    );

    _isLoading = false;

    if (result['success'] == true && result['data'] is StaffMember) {
      final created = result['data'] as StaffMember;
      final exists = _staffMembers.any((s) => s.id == created.id);
      if (!exists) {
        _staffMembers.insert(0, created);
      }
      _summary = await _repository.getSummary(shopId: shopId, token: token);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error']?.toString() ?? 'Failed to register staff member';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStaffMember({
    required String shopId,
    String? token,
    required StaffMember member,
  }) async {
    _isLoading = true;
    notifyListeners();

    final updated = await _repository.updateStaffMember(
      shopId: shopId,
      token: token,
      member: member,
    );

    final idx = _staffMembers.indexWhere((s) => s.id == member.id);
    if (idx != -1) _staffMembers[idx] = updated;
    _summary = await _repository.getSummary(shopId: shopId, token: token);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteStaffMember({
    required String shopId,
    String? token,
    required String staffId,
  }) async {
    _isLoading = true;
    notifyListeners();

    await _repository.deleteStaffMember(
      shopId: shopId,
      token: token,
      staffId: staffId,
    );

    _staffMembers.removeWhere((s) => s.id == staffId);
    _summary = await _repository.getSummary(shopId: shopId, token: token);

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
