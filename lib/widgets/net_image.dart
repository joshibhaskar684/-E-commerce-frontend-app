import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'skeletons.dart';

/// Network image with disk cache, shimmer placeholder and a friendly fallback.
class NetImage extends StatelessWidget {
  const NetImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
    this.width,
    this.height,
  });

  final String? url;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();
    if (u == null || u.isEmpty || !(u.startsWith('http://') || u.startsWith('https://'))) {
      return _fallback(context);
    }
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (_, _) => const ShimmerBox(),
      errorWidget: (_, _, _) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainer,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: scheme.onSurfaceVariant.withValues(alpha: 0.5), size: 32),
    );
  }
}
