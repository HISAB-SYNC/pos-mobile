import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Backend base URL — Muhammed's backend deployed on Render.
///
/// Note: the "Servers" dropdown inside his Swagger page shows
/// 'localhost:3000' — that's just unedited documentation metadata, NOT
/// the real address. The actual reachable URL is wherever the Swagger
/// page itself is hosted (same domain, without the /api-docs path).
class ApiConfig {
  static const String baseUrl = 'https://pos-backend-0fzk.onrender.com';
}

/// Thin wrapper around package:http that:
/// - builds full URLs from ApiConfig.baseUrl
/// - attaches Content-Type / Authorization headers
/// - always returns a Map in the API's own envelope shape
///   ({success: true, data: ...} or {success: false, error: ...}),
///   even on network failure or a malformed response — so callers
///   (the repositories) never need try/catch, they just check `success`.
class ApiClient {
  final http.Client _client = http.Client();
  // Render's free tier spins the server down when idle — the first
  // request after inactivity can take 30-60+ seconds to "wake it up."
  // A short timeout would kill that request before it ever responds.
  static const Duration _timeout = Duration(seconds: 60);

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {String? token}) async {
    try {
      final response = await _client
          .post(_uri(path), headers: _headers(token: token), body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(response);
    } on TimeoutException catch (e) {
      // ignore: avoid_print
      print('API TIMEOUT on $path: $e');
      return _networkError('Request timed out.');
    } catch (e) {
      // ignore: avoid_print
      print('API ERROR on $path: $e');
      return _networkError('Could not reach the server.');
    }
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    try {
      final response = await _client.get(_uri(path), headers: _headers(token: token)).timeout(_timeout);
      return _parse(response);
    } on TimeoutException catch (e) {
      // ignore: avoid_print
      print('API TIMEOUT on $path: $e');
      return _networkError('Request timed out.');
    } catch (e) {
      // ignore: avoid_print
      print('API ERROR on $path: $e');
      return _networkError('Could not reach the server.');
    }
  }

  Map<String, dynamic> _parse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'error': 'Unexpected response format'};
    } catch (_) {
      return {'success': false, 'error': 'Server returned an invalid response (status ${response.statusCode})'};
    }
  }

  Map<String, dynamic> _networkError(String reason) {
    return {
      'success': false,
      'error': '$reason Check your internet connection and the API base URL in api_client.dart.',
    };
  }

  Future<Map<String, dynamic>> patch(
  String path,
  Map<String, dynamic> body, {
  String? token,
}) async {
  try {
    final response = await _client
        .patch(
          _uri(path),
          headers: _headers(token: token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    return _parse(response);
  } on TimeoutException catch (e) {
    print('API TIMEOUT on $path: $e');
    return _networkError('Request timed out.');
  } catch (e) {
    print('API ERROR on $path: $e');
    return _networkError('Could not reach the server.');
  }
}

Future<Map<String, dynamic>> delete(
  String path, {
  String? token,
}) async {
  try {
    final response = await _client
        .delete(
          _uri(path),
          headers: _headers(token: token),
        )
        .timeout(_timeout);

    return _parse(response);
  } on TimeoutException catch (e) {
    print('API TIMEOUT on $path: $e');
    return _networkError('Request timed out.');
  } catch (e) {
    print('API ERROR on $path: $e');
    return _networkError('Could not reach the server.');
  }
}
}