import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/app_user.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

/// Central auth state for the app with persistent session storage.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  AuthStatus _status = AuthStatus.unauthenticated;
  AppUser? _currentUser;
  String? _token;
  String? _errorMessage;
  bool _isBusy = false; // generic loading flag for forgot/verify/reset actions

  // Holds the short-lived reset token between the OTP-verify step and the
  // final confirm-password step, exactly like the real API's flow.
  String? _resetToken;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.authenticating;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isBusy => _isBusy;

  /// Restores saved authentication session from local storage on app launch.
  Future<bool> initAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUserJson = prefs.getString('auth_user');

      if (savedToken != null && savedUserJson != null) {
        final userMap = jsonDecode(savedUserJson) as Map<String, dynamic>;
        _currentUser = AppUser.fromJson(userMap);
        _token = savedToken;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error restoring auth session: $e');
    }

    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

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

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_user', jsonEncode(_currentUser!.toJson()));
      } catch (e) {
        debugPrint('Error saving auth session: $e');
      }

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
    if (_token != null) {
      try {
        await _repository.logout(_token!);
      } catch (e) {
        debugPrint('Error during backend logout: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
    } catch (e) {
      debugPrint('Error clearing auth session: $e');
    }

    _currentUser = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// POST /auth/reset-password/request
  /// Returns null on success, or an error message string on failure.
  Future<String?> requestPasswordReset(String email) async {
    _isBusy = true;
    notifyListeners();
    final response = await _repository.requestResetPassword(email);
    _isBusy = false;
    notifyListeners();
    return response['success'] == true ? null : response['error'] as String?;
  }

  /// POST /auth/reset-password/verify
  /// On success, stores the resetToken internally (used by confirmPasswordReset)
  /// and returns null. On failure, returns the error message.
  Future<String?> verifyResetOtp(String email, String otp) async {
    _isBusy = true;
    notifyListeners();
    final response = await _repository.verifyResetOtp(email, otp);
    _isBusy = false;

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      _resetToken = data['resetToken'] as String;
      notifyListeners();
      return null;
    } else {
      notifyListeners();
      return response['error'] as String?;
    }
  }

  /// POST /auth/reset-password/confirm
  /// Uses the resetToken captured during verifyResetOtp — no email needed
  /// here, matching the real API.
  Future<String?> confirmPasswordReset(String newPassword) async {
    if (_resetToken == null) {
      return 'Reset session expired. Please start over.';
    }

    _isBusy = true;
    notifyListeners();
    final response = await _repository.confirmResetPassword(_resetToken!, newPassword);
    _isBusy = false;

    if (response['success'] == true) {
      _resetToken = null; // consumed — one-time use, like a real token
      notifyListeners();
      return null;
    } else {
      notifyListeners();
      return response['error'] as String?;
    }
  }
}