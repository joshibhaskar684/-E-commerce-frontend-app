import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

/// ₹price  ~~₹original~~  12% off
class PriceRow extends StatelessWidget {
  const PriceRow({
    super.key,
    required this.price,
    this.originalPrice,
    this.showDiscount = true,
    this.large = false,
  });

  final double? price;
  final double? originalPrice;
  final bool showDiscount;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final discount = discountPercent(price, originalPrice);
    final hasOriginal = originalPrice != null && discount > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          formatPrice(price),
          style: (large ? t.headlineMedium : t.titleMedium)?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (hasOriginal) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              formatPrice(originalPrice),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (large ? t.titleMedium : t.bodySmall)?.copyWith(
                color: scheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
                decorationColor: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (hasOriginal && showDiscount) ...[
          const SizedBox(width: 8),
          Text(
            '$discount% off',
            style: (large ? t.titleMedium : t.labelMedium)?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

/// Green "4.3 ★" pill (website: bg-[#388e3c]).
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.star_rounded, size: 13, color: Colors.white),
        ],
      ),
    );
  }
}
