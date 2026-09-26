import 'package:flutter/material.dart';

import '../../../models/page_response.dart';
import '../../../models/product.dart';
import '../../../services/product_service.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/skeletons.dart';
import '../../routes.dart';

/// Horizontal row of products from one category.
/// Hides itself when the category has no products (or the call fails),
/// so the home page never shows empty sections.
class ProductRowSection extends StatefulWidget {
  const ProductRowSection({
    super.key,
    required this.title,
    required this.category,
    this.subtitle,
    this.reloadToken = 0,
  });

  final String title;
  final String? subtitle;
  final String category;
  final int reloadToken;

  @override
  State<ProductRowSection> createState() => _ProductRowSectionState();
}

class _ProductRowSectionState extends State<ProductRowSection> {
  static const _cardWidth = 156.0;
  late Future<PageResponse<ProductSummary>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProductRowSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken || oldWidget.category != widget.category) _load();
  }

  void _load() {
    _future = ProductService().getProductsByCategory(category: widget.category, pageNo: 1, pageSize: 10);
  }

  @override
  Widget build(BuildContext context) {
    final rowHeight = _cardWidth + ProductCard.infoHeight(context);
    return FutureBuilder<PageResponse<ProductSummary>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            height: rowHeight + 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 14),
                  child: ShimmerBox(width: 160, height: 20, radius: 6),
                ),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 3,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, _) => const SizedBox(width: _cardWidth, child: ProductCardSkeleton()),
                  ),
                ),
              ],
            ),
          );
        }
        final items = snap.data?.content ?? const <ProductSummary>[];
        if (snap.hasError || items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: widget.title,
              subtitle: widget.subtitle,
              onViewAll: () => AppRoutes.openCategory(context, category: widget.category, title: widget.title),
            ),
            SizedBox(
              height: rowHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => ProductCard(product: items[i], width: _cardWidth),
              ),
            ),
          ],
        );
      },
    );
  }
}
