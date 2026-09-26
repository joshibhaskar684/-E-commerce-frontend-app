import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/shell_controller.dart';
import '../../widgets/net_image.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';
import '../checkout/checkout_screen.dart';
import '../routes.dart';
import 'price_details_card.dart';

/// Shopping cart (website: app/(public)/(account)/account/cart/page.jsx).
/// GET /cart · PUT /cart/item · DELETE /cart/item/{id} · DELETE /cart/clear
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);
    final cart = context.watch<CartProvider>();
    final items = cart.cart?.items ?? const <CartItem>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(loggedIn && items.isNotEmpty ? 'My Cart (${cart.count})' : 'My Cart'),
        actions: [
          if (loggedIn && items.isNotEmpty)
            IconButton(
              tooltip: 'Clear cart',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: _body(context, loggedIn, cart, items),
      bottomNavigationBar: loggedIn && items.isNotEmpty ? _CheckoutBar(cart: cart.cart!) : null,
    );
  }

  Widget _body(BuildContext context, bool loggedIn, CartProvider cart, List<CartItem> items) {
    if (!loggedIn) {
      return EmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Login to see your cart',
        message: 'Items you add to your cart are saved to your Quick account.',
        actionLabel: 'Login / Sign up',
        onAction: () => AppRoutes.ensureLoggedIn(context),
      );
    }
    if (cart.loading && cart.cart == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(4, (_) => const ListTileSkeleton()),
      );
    }
    if (cart.cart == null && cart.error != null) {
      return ErrorView(error: cart.error!, onRetry: cart.fetch);
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: cart.fetch,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: c.maxHeight,
              child: EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Your cart is empty',
                message: 'Looks like you haven\'t added anything yet. Explore products and find something you love.',
                actionLabel: 'Start shopping',
                onAction: () => context.read<ShellController>().goTo(ShellTab.home),
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: cart.fetch,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (cart.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(cart.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          for (final item in items)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: _CartItemCard(item: item)),
          const SizedBox(height: 4),
          PriceDetailsCard(summary: cart.cart!.effectiveSummary, itemCount: cart.count),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Safe and secure payments',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('All items will be removed from your cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<CartProvider>().clear();
    } on ApiException catch (e) {
      if (context.mounted) showAppSnack(context, e.message);
    }
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});
  final CartItem item;

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      if (context.mounted) showAppSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final cart = context.read<CartProvider>();
    final busy = context.select<CartProvider, bool>((c) => c.isBusy(item.productId) || c.isBusy('*'));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AppRoutes.openProduct(context, item.productId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 88,
                  height: 88,
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: NetImage(item.productImage, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.productName ?? 'Product',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip: 'Remove',
                            onPressed: busy ? null : () => _run(context, () => cart.remove(item.productId)),
                            icon: Icon(Icons.delete_outline_rounded, color: scheme.error, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${formatPrice(item.unitPrice, forceDecimals: item.unitPrice % 1 != 0)} each',
                        style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Stepper(
                          quantity: item.quantity,
                          busy: busy,
                          onMinus: () => _run(context, () => cart.updateQuantity(item.productId, item.quantity - 1)),
                          onPlus: () => _run(context, () => cart.updateQuantity(item.productId, item.quantity + 1)),
                        ),
                        const Spacer(),
                        Text(formatPrice(item.lineTotal), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.quantity, required this.busy, required this.onMinus, required this.onPlus});

  final int quantity;
  final bool busy;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(quantity > 1 ? Icons.remove_rounded : Icons.delete_outline_rounded, busy ? null : onMinus),
          SizedBox(
            width: 32,
            child: Center(
              child: busy
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          _btn(Icons.add_rounded, busy ? null : onPlus),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) => InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(icon, size: 18)),
      );
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = cart.effectiveSummary.totalAmount;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatPrice(total, forceDecimals: true),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Total incl. GST', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => AppRoutes.push(context, const CheckoutScreen()),
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
