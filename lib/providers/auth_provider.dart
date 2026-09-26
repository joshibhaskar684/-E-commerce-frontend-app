import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/token_storage.dart';
import '../core/utils/jwt.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

/// Login state — the Flutter version of the website's UserReducer +
/// `usertoken` cookie handling.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    ApiClient.instance.onSessionExpired = _onSessionExpired;
  }

  final AuthService _service;

  AuthStatus _status = AuthStatus.unknown;
  String? _token;
  Map<String, dynamic>? _claims;
  UserProfile? _profile;
  bool _profileLoading = false;
  String? _profileError;
  bool _sessionExpired = false;

  AuthStatus get status => _status;
  bool get isLoggedIn => _status == AuthStatus.loggedIn;
  UserProfile? get profile => _profile;
  bool get profileLoading => _profileLoading;
  String? get profileError => _profileError;

  /// True once after the backend rejected/expired the token (shown as a hint).
  bool consumeSessionExpired() {
    final v = _sessionExpired;
    _sessionExpired = false;
    return v;
  }

  String? get email => _profile?.email ?? _claims?['sub'] as String?;
  String? get name => _profile?.name;
  int? get userId => (_claims?['userId'] as num?)?.toInt();

  List<String> get roles =>
      (_claims?['roles'] as List?)?.map((e) => '$e'.replaceFirst('ROLE_', '')).toList() ?? const [];

  /// "Admin" / "Seller" / "Customer" (the website shows "Customer" by default).
  String get roleLabel {
    final all = {...roles, if (_profile?.role != null) _profile!.role!.toUpperCase()};
    if (all.contains('ADMIN')) return 'Admin';
    if (all.contains('SELLER')) return 'Seller';
    return 'Customer';
  }

  /// Called once at start-up: restores the saved token.
  Future<void> init() async {
    final token = await TokenStorage.instance.load();
    if (token == null || isJwtExpired(token)) {
      if (token != null) await TokenStorage.instance.clear();
      _status = AuthStatus.loggedOut;
    } else {
      _token = token;
      _claims = decodeJwtPayload(token);
      _status = AuthStatus.loggedIn;
      loadProfile();
    }
    notifyListeners();
  }

  /// LoginUser → POST /auth/login
  Future<void> login(String email, String password) async {
    final token = await _service.login(email: email, password: password);
    await TokenStorage.instance.save(token);
    _token = token;
    _claims = decodeJwtPayload(token);
    _status = AuthStatus.loggedIn;
    _profile = null;
    notifyListeners();
    loadProfile();
  }

  /// RegisterUser → POST /auth/signup
  Future<String> signup({
    required String name,
    required String mobileno,
    required String email,
    required String password,
  }) =>
      _service.signup(name: name, mobileno: mobileno, email: email, password: password);

  /// GetUser → GET /auth/profile
  Future<void> loadProfile() async {
    if (_token == null) return;
    _profileLoading = true;
    _profileError = null;
    notifyListeners();
    try {
      _profile = await _service.profile();
    } on ApiException catch (e) {
      _profileError = e.message;
    } catch (e) {
      _profileError = 'Could not load profile.';
    } finally {
      _profileLoading = false;
      notifyListeners();
    }
  }

  /// LogoutUser → removes the token (website: Cookies.remove("usertoken")).
  Future<void> logout() async {
    await TokenStorage.instance.clear();
    _token = null;
    _claims = null;
    _profile = null;
    _profileError = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }

  void _onSessionExpired() {
    if (_status != AuthStatus.loggedIn) return;
    _sessionExpired = true;
    logout();
  }
}
