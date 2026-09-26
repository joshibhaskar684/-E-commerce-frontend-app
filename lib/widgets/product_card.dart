import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/product.dart';
import '../providers/wishlist_provider.dart';
import '../screens/routes.dart';
import 'net_image.dart';
import 'price_row.dart';

/// Product tile used in grids and horizontal lists
/// (website: components/Products/ProductCard/ProductCard.jsx).
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.width});

  final ProductSummary product;
  final double? width;

  /// Height of everything below the square image.
  static double infoHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(100) + 14;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final wished = context.select<WishlistProvider, bool>((w) => w.contains(product.id));

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => AppRoutes.openProduct(context, product.id, preview: product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: NetImage(product.image, fit: BoxFit.contain),
                    ),
                    if (product.discount > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.discount}% OFF',
                            style: t.labelSmall?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _WishButton(
                        active: wished,
                        onTap: () {
                          final added = context.read<WishlistProvider>().toggle(product);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                              content: Text(added ? 'Added to wishlist' : 'Removed from wishlist'),
                              duration: const Duration(seconds: 1),
                            ));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (product.brand ?? 'Quick').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.25),
                      ),
                      const Spacer(),
                      PriceRow(price: product.price, originalPrice: product.originalPrice, showDiscount: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishButton extends StatelessWidget {
  const _WishButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(active),
              size: 18,
              color: active ? const Color(0xFFE11D48) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid layout for product cards: 2 columns on phones, 3+ on wide screens.
SliverGridDelegate productGridDelegate(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final columns = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
  const spacing = 12.0;
  final itemWidth = (width - 32 - spacing * (columns - 1)) / columns;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: spacing,
    crossAxisSpacing: spacing,
    mainAxisExtent: itemWidth + ProductCard.infoHeight(context),
  );
}
