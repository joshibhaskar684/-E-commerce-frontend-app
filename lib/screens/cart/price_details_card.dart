import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart.dart';

/// Price breakdown from the backend CartSummary
/// (subTotal, discount, deliveryFee, tax = 18% GST, totalAmount).
class PriceDetailsCard extends StatelessWidget {
  const PriceDetailsCard({super.key, required this.summary, required this.itemCount});

  final CartSummary summary;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final discount = summary.discount ?? 0;
    final delivery = summary.deliveryFee ?? 0;

    Widget row(String label, String value, {Color? color, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(label, style: bold ? const TextStyle(fontWeight: FontWeight.w700) : null)),
              Text(value,
                  style: TextStyle(color: color, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 17 : null)),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price details', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            row('Price ($itemCount item${itemCount == 1 ? '' : 's'})', formatPrice(summary.subTotal, forceDecimals: true)),
            row('Discount', discount > 0 ? '− ${formatPrice(discount, forceDecimals: true)}' : formatPrice(0),
                color: AppColors.success),
            row('Delivery charges', delivery > 0 ? formatPrice(delivery, forceDecimals: true) : 'FREE',
                color: delivery > 0 ? null : AppColors.success),
            row('GST (18%)', formatPrice(summary.tax, forceDecimals: true)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: scheme.outlineVariant),
            ),
            row('Total amount', formatPrice(summary.totalAmount, forceDecimals: true), bold: true),
          ],
        ),
      ),
    );
  }
}
