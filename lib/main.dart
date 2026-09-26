import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved settings (server URL, theme) and the saved login token
  // before the first frame, so the app opens in the right state.
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsProvider(prefs);
  final auth = AuthProvider();
  await auth.init();

  runApp(QuickApp(prefs: prefs, settings: settings, auth: auth));
}
