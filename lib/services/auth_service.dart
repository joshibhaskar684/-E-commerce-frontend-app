import '../config/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/user_profile.dart';

/// Mirrors website `src/redux-store/user/action.js`
/// (LoginUser, RegisterUser, GetUser).
class AuthService {
  AuthService({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// LoginUser → POST /auth/login {email, password}
  ///
  /// The backend returns `{token, message}` in the body and also sets a
  /// `usertoken` cookie. Browsers use the cookie; the app keeps the token
  /// from the body.
  Future<String> login({required String email, required String password}) async {
    try {
      final data = await _api.post(
        ApiEndpoints.login,
        data: {'email': email.trim(), 'password': password},
        auth: false,
      );
      final token = data is Map ? data['token'] as String? : null;
      if (token == null || token.isEmpty) {
        throw ApiException('Login failed: the server did not return a token.');
      }
      return token;
    } on ApiException catch (e) {
      final badCredentials = e.statusCode == 401 ||
          e.statusCode == 403 ||
          e.statusCode == 302 ||
          e.message.toLowerCase().contains('bad credentials');
      if (badCredentials) {
        throw ApiException('Invalid email or password.', statusCode: e.statusCode);
      }
      rethrow;
    }
  }

  /// RegisterUser → POST /auth/signup {name, mobileno, email, password}
  /// Returns the server message, e.g. "User Registered Successfully!".
  Future<String> signup({
    required String name,
    required String mobileno,
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      ApiEndpoints.signup,
      data: {
        'name': name.trim(),
        'mobileno': mobileno.trim(),
        'email': email.trim(),
        'password': password,
      },
      auth: false,
    );
    final message = data is Map ? data['message'] as String? : null;
    return message ?? 'Registration successful! Please log in.';
  }

  /// GetUser → GET /auth/profile  (`Authorization: Bearer <token>`)
  Future<UserProfile> profile() async {
    final data = await _api.get(ApiEndpoints.profile);
    return UserProfile.fromJson(data);
  }
}
