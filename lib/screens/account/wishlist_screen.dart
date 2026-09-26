import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/shell_controller.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';

/// Wishlist (website: account/wishlist). Saved on the phone.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final items = wishlist.items;

    return Scaffold(
      appBar: AppBar(title: Text(items.isEmpty ? 'My Wishlist' : 'My Wishlist (${items.length})')),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Your wishlist is empty',
              message: 'Tap the heart on any product to save it for later.',
              actionLabel: 'Continue shopping',
              onAction: () {
                final shell = context.read<ShellController>();
                Navigator.of(context).popUntil((r) => r.isFirst);
                shell.goTo(ShellTab.home);
              },
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: productGridDelegate(context),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(product: items[i]),
                      childCount: items.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
