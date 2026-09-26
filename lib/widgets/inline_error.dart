import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../providers/paged_products.dart';
import '../screens/account/server_settings_screen.dart';

/// Compact error card for use inside scrolling pages.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.error, this.onRetry});

  final ApiException error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(error.isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                      color: scheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      error.isNetworkError ? 'Server not reachable' : 'Could not load products',
                      style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(error.message, style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onRetry != null)
                    FilledButton.tonalIcon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  if (error.isNetworkError)
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const ServerSettingsScreen())),
                      icon: const Icon(Icons.dns_outlined, size: 18),
                      label: const Text('Server settings'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom of an infinite list: spinner / retry / "end of list".
class PagerFooter extends StatelessWidget {
  const PagerFooter({super.key, required this.pager});
  final PagedProducts pager;

  @override
  Widget build(BuildContext context) {
    if (pager.loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.6))),
      );
    }
    if (pager.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextButton.icon(
            onPressed: pager.loadMore,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Couldn\'t load more. Tap to retry'),
          ),
        ),
      );
    }
    if (!pager.hasMore && pager.items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'You\'ve reached the end',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}
