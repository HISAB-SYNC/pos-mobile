import 'package:flutter/foundation.dart';
import '../../../core/models/app_user.dart';
import '../data/mock_auth_repository.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

/// Central auth state for the app. Wrap MaterialApp with this via
/// ChangeNotifierProvider so any screen can read login state or trigger login/logout.
class AuthProvider extends ChangeNotifier {
  final MockAuthRepository _repository = MockAuthRepository();

  AuthStatus _status = AuthStatus.unauthenticated;
  AppUser? _currentUser;
  String? _token;
  String? _errorMessage;
  bool _isBusy = false; // generic loading flag for forgot/reset actions

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.authenticating;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isBusy => _isBusy;

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    final response = await _repository.login(email, password);

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      _currentUser = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      _token = data['token'] as String;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response['error'] as String? ?? 'Login failed';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Corresponds to POST /auth/request-reset-password.
  /// Returns null on success, or an error message string on failure.
  Future<String?> requestPasswordReset(String email) async {
    _isBusy = true;
    notifyListeners();
    final response = await _repository.requestResetPassword(email);
    _isBusy = false;
    notifyListeners();
    return response['success'] == true ? null : response['error'] as String?;
  }

  /// Corresponds to POST /auth/reset-password.
  /// This is where the token is actually checked — there's no separate
  /// verify-only endpoint in the real API.
  Future<String?> resetPassword(String email, String token, String newPassword) async {
    _isBusy = true;
    notifyListeners();
    final response = await _repository.resetPassword(email, token, newPassword);
    _isBusy = false;
    notifyListeners();
    return response['success'] == true ? null : response['error'] as String?;
  }
}