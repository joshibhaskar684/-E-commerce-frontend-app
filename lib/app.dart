import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/shell_controller.dart';
import 'providers/wishlist_provider.dart';
import 'screens/shell/main_shell.dart';

class QuickApp extends StatelessWidget {
  const QuickApp({super.key, required this.prefs, required this.settings, required this.auth});

  final SharedPreferences prefs;
  final SettingsProvider settings;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => WishlistProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ShellController()),
        // Cart follows the login state: fetched on login, cleared on logout.
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) => cart!..onAuthChanged(auth.isLoggedIn),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: const MainShell(),
        ),
      ),
    );
  }
}
