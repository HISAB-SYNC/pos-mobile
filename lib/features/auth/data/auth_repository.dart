import '../../../core/network/api_client.dart';

/// Real backend integration — every method here calls Muhammed's actual
/// NestJS API, matching the Swagger doc exactly. This replaces
/// MockAuthRepository; AuthProvider's code barely changed because the
/// mock was already built to return the same {success, data}/{success,
/// error} envelope shape as the real API.
class AuthRepository {
  final ApiClient _client = ApiClient();

  /// POST /auth/register/owner — public, registers a new Owner account.
  /// Not currently wired to any screen (Owners sign up on web per the
  /// spec), but here for completeness / if a mobile register screen is
  /// ever added.
  Future<Map<String, dynamic>> registerOwner({
    required String email,
    required String password,
    required String name,
  }) {
    return _client.post('/auth/register/owner', {
      'email': email,
      'password': password,
      'name': name,
    });
  }

  /// POST /auth/register/staff — protected (Owner or Admin only).
  /// Requires the caller's own token, since only a logged-in Owner/Admin
  /// can create Admin/Sales accounts.
  Future<Map<String, dynamic>> registerStaff({
    required String email,
    required String password,
    required String name,
    required String role, // 'ADMIN' or 'SALES'
    required String shopId,
    required String callerToken,
  }) {
    return _client.post(
      '/auth/register/staff',
      {
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        'shopId': shopId,
      },
      token: callerToken,
    );
  }

  /// POST /auth/login
  Future<Map<String, dynamic>> login(String email, String password) {
    return _client.post('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  /// POST /auth/logout — protected, needs the current token.
  Future<Map<String, dynamic>> logout(String token) {
    return _client.post('/auth/logout', {}, token: token);
  }

  /// POST /auth/reset-password/request
  Future<Map<String, dynamic>> requestResetPassword(String email) {
    return _client.post('/auth/reset-password/request', {'email': email});
  }

  /// POST /auth/reset-password/verify
  Future<Map<String, dynamic>> verifyResetOtp(String email, String otp) {
    return _client.post('/auth/reset-password/verify', {
      'email': email,
      'otp': otp,
    });
  }

  /// POST /auth/reset-password/confirm
  Future<Map<String, dynamic>> confirmResetPassword(String resetToken, String newPassword) {
    return _client.post('/auth/reset-password/confirm', {
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
  }
}