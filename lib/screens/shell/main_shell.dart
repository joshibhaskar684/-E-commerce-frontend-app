import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/shell_controller.dart';
import '../../widgets/state_views.dart';
import '../account/account_screen.dart';
import '../cart/cart_screen.dart';
import '../categories/categories_screen.dart';
import '../home/home_screen.dart';

/// Bottom navigation: Home · Categories · Cart · Account.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _pages = [HomeScreen(), CategoriesScreen(), CartScreen(), AccountScreen()];

  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>()..addListener(_onAuthChange);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    if (!_auth.isLoggedIn && _auth.consumeSessionExpired() && mounted) {
      showAppSnack(context, 'Your session has expired. Please log in again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final cartCount = context.select<CartProvider, int>((c) => c.count);

    return PopScope(
      // Android back button: go to Home first, exit from Home.
      canPop: shell.tab == ShellTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goTo(ShellTab.home);
      },
      child: Scaffold(
        body: IndexedStack(index: shell.tab.index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.tab.index,
          onDestinationSelected: (i) {
            shell.goTo(ShellTab.values[i]);
            if (ShellTab.values[i] == ShellTab.cart) context.read<CartProvider>().fetch();
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_bag_rounded),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
