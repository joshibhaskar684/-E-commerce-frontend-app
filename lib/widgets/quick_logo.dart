import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The Quick logo (transparent PNGs generated from the original logo).
///   full   → bag + "quick" word  (assets/images/logo_mark.png)
///   symbol → bag only           (assets/images/logo_symbol.png)
class QuickLogo extends StatelessWidget {
  const QuickLogo({super.key, this.height = 40, this.color, this.symbolOnly = false});

  final double height;
  final Color? color;
  final bool symbolOnly;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      symbolOnly ? 'assets/images/logo_symbol.png' : 'assets/images/logo_mark.png',
      height: height,
      color: color ?? AppColors.navy,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high,
    );
  }
}

/// Bag symbol + "quick" wordmark in a row, for app bars.
class QuickWordmark extends StatelessWidget {
  const QuickWordmark({super.key, this.color, this.size = 26});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.navy;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        QuickLogo(symbolOnly: true, height: size, color: c),
        const SizedBox(width: 8),
        Text(
          'quick',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: c,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1,
              ),
        ),
      ],
    );
  }
}
