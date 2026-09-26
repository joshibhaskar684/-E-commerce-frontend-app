import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shell_controller.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/quick_logo.dart';
import '../../widgets/state_views.dart';
import '../ai/ai_chat_screen.dart';
import '../auth/signup_screen.dart';
import '../routes.dart';
import 'orders_screen.dart';
import 'server_settings_screen.dart';
import 'wishlist_screen.dart';

/// Account / profile (website: app/(public)/(account)/account/profile/page.jsx).
/// Data: GET /auth/profile
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final wishCount = context.select<WishlistProvider, int>((w) => w.count);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: RefreshIndicator(
        onRefresh: auth.isLoggedIn ? auth.loadProfile : () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            auth.isLoggedIn ? const _ProfileCard() : const _GuestCard(),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [
                _QuickAction(
                  icon: Icons.inventory_2_outlined,
                  label: 'Orders',
                  onTap: () async {
                    if (await AppRoutes.ensureLoggedIn(context, reason: 'Log in to see your orders.') &&
                        context.mounted) {
                      AppRoutes.push(context, const OrdersScreen());
                    }
                  },
                ),
                _QuickAction(
                  icon: Icons.favorite_border_rounded,
                  label: 'Wishlist',
                  badge: wishCount,
                  onTap: () => AppRoutes.push(context, const WishlistScreen()),
                ),
                _QuickAction(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Cart',
                  onTap: () => context.read<ShellController>().goTo(ShellTab.cart),
                ),
                _QuickAction(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Ask AI',
                  onTap: () => AppRoutes.push(context, const AiChatScreen()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Group(
              title: 'Settings',
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Theme'),
                  subtitle: Text(switch (settings.themeMode) {
                    ThemeMode.system => 'System default',
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                  }),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickTheme(context),
                ),
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('Server settings'),
                  subtitle: Text(settings.baseUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => AppRoutes.push(context, const ServerSettingsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Group(
              title: 'Help & info',
              children: [
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded),
                  title: const Text('Help center'),
                  subtitle: const Text('Chat with Ayira AI'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => AppRoutes.push(context, const AiChatScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.policy_outlined),
                  title: const Text('Policies'),
                  subtitle: const Text('Privacy, returns, shipping, terms'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () => launchUrl(Uri.parse(AppConfig.policyUrl), mode: LaunchMode.externalApplication),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About Quick'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Quick',
                    applicationVersion: '1.0.0',
                    applicationIcon: const QuickLogo(height: 48),
                    applicationLegalese: 'Modern full-stack ecommerce platform.\nWebsite: ${AppConfig.websiteUrl}',
                  ),
                ),
              ],
            ),
            if (auth.isLoggedIn) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
                ),
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickTheme(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final mode = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: settings.themeMode,
          onChanged: (v) => Navigator.pop(context, v),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(value: ThemeMode.system, title: Text('System default')),
              RadioListTile(value: ThemeMode.light, title: Text('Light')),
              RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (mode != null) settings.setThemeMode(mode);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to see your cart and orders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) showAppSnack(context, 'You have been logged out.');
    }
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandYellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const QuickLogo(symbolOnly: true, height: 40),
          const SizedBox(height: 14),
          Text('Welcome to Quick',
              style: t.titleLarge?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Log in to track orders, manage your cart and check out faster.',
              style: t.bodyMedium?.copyWith(color: AppColors.navy.withValues(alpha: 0.8))),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                  onPressed: () => AppRoutes.ensureLoggedIn(context),
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy, width: 1.4),
                  ),
                  onPressed: () => AppRoutes.push(context, const SignupScreen()),
                  child: const Text('Sign up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final p = auth.profile;

    Widget info(IconData icon, String? value, String fallback) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (value == null || value.isEmpty) ? fallback : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: AppColors.navy,
                  child: Text(initialsOf(auth.name ?? auth.email),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.name ?? (auth.profileLoading ? 'Loading…' : 'Quick shopper'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_outlined, size: 14, color: scheme.onSecondaryContainer),
                            const SizedBox(width: 4),
                            Text(auth.roleLabel,
                                style: t.labelMedium
                                    ?.copyWith(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (auth.profileLoading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 10),
            info(Icons.mail_outline_rounded, auth.email, 'Email not provided'),
            info(Icons.phone_outlined, p?.mobileno, 'Mobile not provided'),
            if (auth.profileError != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(auth.profileError!,
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.error, fontSize: 12)),
                  ),
                  TextButton(onPressed: auth.loadProfile, child: const Text('Retry')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.badge = 0});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: scheme.secondaryContainer, shape: BoxShape.circle),
                child: Icon(icon, color: scheme.onSecondaryContainer, size: 22),
              ),
            ),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}
