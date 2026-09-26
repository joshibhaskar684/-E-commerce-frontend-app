import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/shell_controller.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/net_image.dart';
import '../../widgets/price_row.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';
import '../ai/ai_chat_screen.dart';
import '../routes.dart';

/// Product page (website: app/(public)/products/[productid]/ProductDetailsClient.jsx)
/// Data: GET /products/{productId}
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId, this.preview});

  final String productId;

  /// Card data already on screen, shown instantly while details load.
  final ProductSummary? preview;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<ProductDetail> _future;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = ProductService().getProductDetails(widget.productId);

  void _goToCart() {
    final shell = context.read<ShellController>();
    context.read<CartProvider>().fetch();
    Navigator.of(context).popUntil((r) => r.isFirst);
    shell.goTo(ShellTab.cart);
  }

  /// Website AddToCart / BuyNow buttons → POST /cart/item/add
  Future<void> _addToCart(ProductDetail product, {bool buyNow = false}) async {
    final loggedIn = await AppRoutes.ensureLoggedIn(context, reason: 'Log in to add items to your cart.');
    if (!loggedIn || !mounted) return;
    final cart = context.read<CartProvider>();
    if (cart.contains(product.id)) {
      _goToCart();
      return;
    }
    setState(() => _adding = true);
    try {
      await cart.add(product);
      if (!mounted) return;
      if (buyNow) {
        _goToCart();
      } else {
        showAppSnack(context, 'Added to cart', actionLabel: 'VIEW CART', onAction: _goToCart);
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductDetail>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _LoadingView(preview: widget.preview);
        if (snap.hasError || snap.data == null || snap.data!.id.isEmpty) {
          final error = snap.error;
          final notFound = snap.data?.id.isEmpty == true || (error is ApiException && error.isNotFound);
          return Scaffold(
            appBar: AppBar(),
            body: notFound
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Product not found',
                    message: 'The item you are looking for is currently unavailable or does not exist.',
                    actionLabel: 'Continue shopping',
                    onAction: () => Navigator.of(context).pop(),
                  )
                : ErrorView(error: error ?? 'Unknown error', onRetry: () => setState(_load)),
          );
        }
        return _DetailView(
          product: snap.data!,
          adding: _adding,
          onAddToCart: () => _addToCart(snap.data!),
          onBuyNow: () => _addToCart(snap.data!, buyNow: true),
          onOpenCart: _goToCart,
        );
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({
    required this.product,
    required this.adding,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onOpenCart,
  });

  final ProductDetail product;
  final bool adding;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wished = context.select<WishlistProvider, bool>((w) => w.contains(product.id));
    final cartCount = context.select<CartProvider, int>((c) => c.count);
    final inCart = context.select<CartProvider, bool>((c) => c.contains(product.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: width.clamp(280, 460),
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: const Padding(padding: EdgeInsets.all(6), child: _CircleBack()),
            actions: [
              _CircleAction(
                icon: wished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: wished ? const Color(0xFFE11D48) : null,
                tooltip: 'Wishlist',
                onTap: () {
                  final added = context.read<WishlistProvider>().toggle(product.toSummary());
                  showAppSnack(context, added ? 'Added to wishlist' : 'Removed from wishlist');
                },
              ),
              _CircleAction(
                icon: Icons.shopping_bag_outlined,
                tooltip: 'Cart',
                badge: cartCount,
                onTap: onOpenCart,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _Gallery(images: product.images),
            ),
          ),
          SliverList.list(
            children: [
              _HeaderCard(product: product),
              _OffersCard(),
              _ServicesCard(product: product),
              if ((product.description ?? '').trim().isNotEmpty) _DescriptionCard(text: product.description!),
              if (product.specifications.isNotEmpty) _SpecsCard(specs: product.specifications),
              _RatingsCard(product: product),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _BuyBar(
        inStock: product.inStock,
        inCart: inCart,
        busy: adding,
        onAddToCart: onAddToCart,
        onBuyNow: onBuyNow,
      ),
    );
  }
}

// ── Image gallery ───────────────────────────────────────────────────────────

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});
  final List<String> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? const <String?>[null] : widget.images;
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => GestureDetector(
                onTap: images[i] == null
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => _FullscreenGallery(images: widget.images, initial: i),
                        )),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 56, 32, 36),
                  child: NetImage(images[i], fit: BoxFit.contain),
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? AppColors.navy : const Color(0xFFCBD2DC),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatelessWidget {
  const _FullscreenGallery({required this.images, required this.initial});
  final List<String> images;
  final int initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: AppColors.navy),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: images.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(child: NetImage(images[i], fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

class _CircleBack extends StatelessWidget {
  const _CircleBack();

  @override
  Widget build(BuildContext context) => _CircleAction(
        icon: Icons.arrow_back_rounded,
        tooltip: 'Back',
        onTap: () => Navigator.of(context).maybePop(),
      );
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap, this.tooltip, this.color, this.badge = 0});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 1.5,
        shadowColor: Colors.black26,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Badge(
            isLabelVisible: badge > 0,
            label: Text('$badge'),
            child: Icon(icon, color: color ?? AppColors.navy, size: 22),
          ),
        ),
      ),
    );
  }
}

// ── Info sections ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.child, this.title});
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.product});
  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final qty = product.quantity ?? 0;

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.brand != null)
            Text(
              product.brand!.toUpperCase(),
              style: t.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          const SizedBox(height: 4),
          Text(product.name, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.25)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RatingBadge(rating: product.averageRating ?? 0),
              Text('${product.totalReviews ?? 0} Ratings & Reviews',
                  style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('✓ Quick Assured',
                    style: t.labelSmall?.copyWith(color: AppColors.info, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PriceRow(price: product.price, originalPrice: product.originalPrice, large: true),
          const SizedBox(height: 8),
          if (!product.inStock)
            Text('Currently out of stock',
                style: t.bodyMedium?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600))
          else if (qty <= 5)
            Text('Hurry, only $qty left!',
                style: t.bodyMedium?.copyWith(color: const Color(0xFFEA580C), fontWeight: FontWeight.w600))
          else
            Text('In stock', style: t.bodyMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _OffersCard extends StatelessWidget {
  // Same offers text as the website product page.
  static const _offers = [
    ('Bank Offer', '5% Cashback on Axis Bank Card'),
    ('Special Price', 'Get extra 10% off (price inclusive of cashback/coupon)'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Section(
      title: 'Available offers',
      child: Column(
        children: [
          for (final (title, text) in _offers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.local_offer_rounded, size: 18, color: AppColors.success),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: text),
                        const TextSpan(text: '  T&C', style: TextStyle(color: AppColors.info)),
                      ]),
                      style: t.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ServicesCard extends StatelessWidget {
  const _ServicesCard({required this.product});
  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <(IconData, String, String?)>[
      (
        Icons.local_shipping_outlined,
        'Delivery in ${product.deliveryDays ?? 3} days',
        product.freeShipping == true ? 'FREE delivery on this item' : null,
      ),
      (Icons.autorenew_rounded, '${product.returnDay ?? 7} days return policy', null),
      (Icons.verified_user_outlined, 'Secure payments', 'Pay online via Razorpay'),
      if (product.sellerId != null) (Icons.storefront_outlined, 'Sold by seller #${product.sellerId}', null),
    ];

    return _Section(
      title: 'Delivery & services',
      child: Column(
        children: [
          for (final (icon, title, subtitle) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 20, color: scheme.onSecondaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (subtitle != null)
                          Text(subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: product.freeShipping == true ? AppColors.success : null)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.support_agent_rounded, size: 20, color: scheme.onSecondaryContainer),
            ),
            title: const Text('Questions about this product?', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Ask Ayira AI, 24×7'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => AppRoutes.push(
              context,
              AiChatScreen(initialPrompt: 'Tell me about "${product.name}"${product.brand != null ? ' by ${product.brand}' : ''}. Is it worth buying?'),
            ),
          ),
          if (product.color != null && product.color!.trim().isNotEmpty) ...[
            const Divider(height: 20),
            Row(
              children: [
                Text('Color', style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _parseColor(product.color!) ?? scheme.outline,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(capitalize(product.color!), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color? _parseColor(String name) {
    const named = {
      'black': Colors.black,
      'white': Colors.white,
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'brown': Colors.brown,
      'navy': AppColors.navy,
      'silver': Color(0xFFC0C0C0),
      'gold': Color(0xFFD4AF37),
    };
    final key = name.trim().toLowerCase();
    if (named.containsKey(key)) return named[key];
    for (final entry in named.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    final hex = key.replaceFirst('#', '');
    if (RegExp(r'^[0-9a-f]{6}$').hasMatch(hex)) return Color(int.parse('ff$hex', radix: 16));
    return null;
  }
}

class _DescriptionCard extends StatefulWidget {
  const _DescriptionCard({required this.text});
  final String text;

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final long = widget.text.length > 260;
    return _Section(
      title: 'Product description',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: Text(
              widget.text,
              maxLines: _expanded || !long ? null : 5,
              overflow: _expanded || !long ? null : TextOverflow.ellipsis,
              style: t.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          if (long)
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Show less' : 'Read more'),
            ),
        ],
      ),
    );
  }
}

class _SpecsCard extends StatelessWidget {
  const _SpecsCard({required this.specs});
  final Map<String, dynamic> specs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = specs.entries.toList();
    return _Section(
      title: 'Specifications',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: i.isEven ? scheme.surfaceContainerLow : null,
                  border: i == entries.length - 1 ? null : Border(bottom: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(prettyCategory(entries[i].key), style: TextStyle(color: scheme.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(_valueText(entries[i].value), style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _valueText(dynamic v) {
    if (v is List) return v.join(', ');
    if (v is Map) return v.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return '$v';
  }
}

class _RatingsCard extends StatelessWidget {
  const _RatingsCard({required this.product});
  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final rating = product.averageRating ?? 0;
    return _Section(
      title: 'Ratings & reviews',
      child: Row(
        children: [
          Text(rating.toStringAsFixed(1), style: t.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (i) {
                  final filled = rating >= i + 1;
                  final half = !filled && rating > i;
                  return Icon(
                    filled ? Icons.star_rounded : (half ? Icons.star_half_rounded : Icons.star_outline_rounded),
                    color: AppColors.brandYellow,
                    size: 22,
                  );
                }),
              ),
              Text('${product.totalReviews ?? 0} ratings', style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ──────────────────────────────────────────────────────────────

class _BuyBar extends StatelessWidget {
  const _BuyBar({
    required this.inStock,
    required this.inCart,
    required this.busy,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final bool inStock;
  final bool inCart;
  final bool busy;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: !inStock
            ? const FilledButton(onPressed: null, child: Text('Out of stock'))
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onAddToCart,
                      icon: busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(inCart ? Icons.shopping_bag_rounded : Icons.add_shopping_cart_rounded),
                      label: Text(inCart ? 'Go to cart' : 'Add to cart'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandYellow,
                        foregroundColor: AppColors.navy,
                      ),
                      onPressed: busy ? null : onBuyNow,
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('Buy now'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Loading state ───────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView({this.preview});
  final ProductSummary? preview;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final p = preview;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          Container(
            color: Colors.white,
            height: width.clamp(240, 380) - 60,
            padding: const EdgeInsets.all(32),
            child: p?.image != null ? NetImage(p!.image, fit: BoxFit.contain) : const ShimmerBox(radius: 16),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p != null) ...[
                  Text(p.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  PriceRow(price: p.price, originalPrice: p.originalPrice, large: true),
                ] else ...[
                  const ShimmerBox(height: 22, radius: 6),
                  const SizedBox(height: 10),
                  const ShimmerBox(width: 140, height: 28, radius: 6),
                ],
                const SizedBox(height: 24),
                const ShimmerBox(height: 90, radius: 12),
                const SizedBox(height: 12),
                const ShimmerBox(height: 140, radius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
