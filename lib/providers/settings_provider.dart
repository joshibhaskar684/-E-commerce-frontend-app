import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../core/network/api_client.dart';

/// App settings stored on the phone: backend URL and theme.
///
/// The backend URL can be changed at runtime from Account → Server settings,
/// which is handy when switching between USB (adb reverse → localhost) and
/// Wi-Fi (PC LAN IP) without rebuilding the app.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs) {
    _baseUrl = _prefs.getString(_kBaseUrl) ?? AppConfig.defaultApiBaseUrl;
    ApiClient.instance.baseUrl = _baseUrl;
    final themeIndex = _prefs.getInt(_kTheme) ?? 0;
    _themeMode = ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)];
  }

  static const _kBaseUrl = 'api_base_url';
  static const _kTheme = 'theme_mode';

  final SharedPreferences _prefs;
  late String _baseUrl;
  late ThemeMode _themeMode;

  String get baseUrl => _baseUrl;
  ThemeMode get themeMode => _themeMode;
  bool get isCustomBaseUrl => _prefs.containsKey(_kBaseUrl);

  /// Accepts "192.168.1.5:8085", "http://localhost:8085/" … and normalises it.
  static String normalizeUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith(RegExp(r'https?://'))) url = 'http://$url';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = normalizeUrl(url);
    ApiClient.instance.baseUrl = _baseUrl;
    await _prefs.setString(_kBaseUrl, _baseUrl);
    notifyListeners();
  }

  Future<void> resetBaseUrl() async {
    _baseUrl = AppConfig.defaultApiBaseUrl;
    ApiClient.instance.baseUrl = _baseUrl;
    await _prefs.remove(_kBaseUrl);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(_kTheme, mode.index);
    notifyListeners();
  }
}
