import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/jwt.dart';

/// Keeps the JWT returned by `POST /auth/login`.
///
/// The website keeps it in the `usertoken` cookie. On the phone it is kept in
/// encrypted storage (Android Keystore) under the same name, and cached in
/// memory so the API client can attach it to every request.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _key = 'usertoken';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cached;

  String? get cachedToken => _cached;

  bool get hasValidToken => _cached != null && !isJwtExpired(_cached!);

  Future<String?> load() async {
    try {
      _cached = await _storage.read(key: _key);
    } catch (e) {
      // Keystore data can become unreadable after a reinstall/restore.
      debugPrint('TokenStorage: could not read token ($e), clearing it.');
      await _safeDeleteAll();
      _cached = null;
    }
    return _cached;
  }

  Future<void> save(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      await _safeDeleteAll();
    }
  }

  Future<void> _safeDeleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
