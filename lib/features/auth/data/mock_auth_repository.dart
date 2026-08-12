import 'dart:async';

/// Fake backend for now. Returns the SAME envelope shape the real API
/// returns (see API_GUIDE.md): { "success": bool, "data": {...} } or
/// { "success": false, "error": "message" }. Once Muhammed's endpoints
/// are live, replace the body of each method with a real http.post() call
/// that returns jsonDecode(response.body) — the envelope shape won't change,
/// so AuthProvider doesn't need to change either.
class MockAuthRepository {
  // Pretend "database" of users. Only OWNER has shopId: null — ADMIN and
  // SALES always belong to exactly one shop, per API_GUIDE.md §2.
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 'u1',
      'name': 'Salim Owner',
      'email': 'owner@minishop.com',
      'password': '123456',
      'role': 'OWNER',
      'shopId': null,
      'createdAt': '2026-08-01T08:00:00.000Z',
      'updatedAt': '2026-08-01T08:00:00.000Z',
    },
    {
      'id': 'u2',
      'name': 'Amina Admin',
      'email': 'admin@minishop.com',
      'password': '123456',
      'role': 'ADMIN',
      'shopId': 's1',
      'createdAt': '2026-08-01T08:00:00.000Z',
      'updatedAt': '2026-08-01T08:00:00.000Z',
    },
    {
      'id': 'u3',
      'name': 'Yusuf Sales',
      'email': 'sales@minishop.com',
      'password': '123456',
      'role': 'SALES',
      'shopId': 's1',
      'createdAt': '2026-08-01T08:00:00.000Z',
      'updatedAt': '2026-08-01T08:00:00.000Z',
    },
  ];

  // The mock's "correct" reset code. NOTE: the real API's example token
  // ("K6H6XZX3") is 8-char alphanumeric, not a fixed 6-digit code — ask
  // Muhammed to confirm the actual format/length before this ships.
  static const String _mockResetToken = '123456';

  /// Simulates POST /auth/login
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final match = _mockUsers.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (match.isEmpty) {
      return {'success': false, 'error': 'Invalid email or password'};
    }

    final fakeToken = 'mock-jwt-token-${match['id']}-${DateTime.now().millisecondsSinceEpoch}';

    return {
      'success': true,
      'data': {
        'user': Map<String, dynamic>.from(match)..remove('password'),
        'token': fakeToken,
      },
    };
  }

  /// Simulates POST /auth/logout — no real endpoint documented yet, kept
  /// as a local no-op (clearing the token client-side is usually enough).
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Simulates POST /auth/request-reset-password
  Future<Map<String, dynamic>> requestResetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Real API always returns success (doesn't reveal if the email exists),
    // per the guide's example response — mirroring that here.
    return {
      'success': true,
      'data': {'message': 'If that email exists, a password reset token has been generated.'},
    };
  }

  /// Simulates POST /auth/reset-password
  /// This is the ONLY place the reset token is actually verified —
  /// there's no separate "verify OTP" endpoint in the real API.
  Future<Map<String, dynamic>> resetPassword(String email, String token, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (token != _mockResetToken) {
      return {'success': false, 'error': 'Invalid or expired token'};
    }

    final index = _mockUsers.indexWhere((u) => u['email'] == email);
    if (index == -1) {
      return {'success': false, 'error': 'No account found for that email'};
    }
    _mockUsers[index]['password'] = newPassword;

    return {
      'success': true,
      'data': {'message': 'Password has been reset successfully'},
    };
  }
}