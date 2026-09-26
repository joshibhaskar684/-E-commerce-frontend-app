import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../providers/paged_products.dart';
import '../../services/product_service.dart';
import '../../widgets/inline_error.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';
import '../routes.dart';

enum _Mode { all, category, search }

enum ProductSort { relevance, priceLowHigh, priceHighLow, discount }

/// Product grid for:
///   all products   → GET /products/page                (website /products)
///   a category     → GET /products/page/category/main  (website /products?category=)
///   a search query → GET /products/page/query/main     (website /search?query=)
class ProductListScreen extends StatefulWidget {
  const ProductListScreen.all({super.key})
      : _mode = _Mode.all,
        value = '',
        title = null;

  const ProductListScreen.category({super.key, required String category, this.title})
      : _mode = _Mode.category,
        value = category;

  const ProductListScreen.search({super.key, required String query})
      : _mode = _Mode.search,
        value = query,
        title = null;

  final _Mode _mode;
  final String value;
  final String? title;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _service = ProductService();
  late final PagedProducts _pager;
  ProductSort _sort = ProductSort.relevance;

  @override
  void initState() {
    super.initState();
    _pager = PagedProducts((page) {
      switch (widget._mode) {
        case _Mode.all:
          return _service.getProducts(pageNo: page);
        case _Mode.category:
          return _service.getProductsByCategory(category: widget.value, pageNo: page);
        case _Mode.search:
          return _service.searchProducts(query: widget.value, pageNo: page);
      }
    })
      ..loadMore();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  String get _title => switch (widget._mode) {
        _Mode.all => 'All Products',
        _Mode.category => widget.title ?? prettyCategory(widget.value),
        _Mode.search => '"${widget.value}"',
      };

  /// Sorting is applied to the products loaded so far (the backend page
  /// endpoints don't take a sort parameter yet).
  List<ProductSummary> get _sorted {
    final list = [..._pager.items];
    int byPrice(ProductSummary a, ProductSummary b) => (a.price ?? 0).compareTo(b.price ?? 0);
    switch (_sort) {
      case ProductSort.relevance:
        break;
      case ProductSort.priceLowHigh:
        list.sort(byPrice);
      case ProductSort.priceHighLow:
        list.sort((a, b) => byPrice(b, a));
      case ProductSort.discount:
        list.sort((a, b) => b.discount.compareTo(a.discount));
    }
    return list;
  }

  Future<void> _chooseSort() async {
    final choice = await showModalBottomSheet<ProductSort>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Sort by',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            RadioGroup<ProductSort>(
              groupValue: _sort,
              onChanged: (v) => Navigator.pop(context, v),
              child: Column(
                children: [
                  for (final (value, label) in const [
                    (ProductSort.relevance, 'Relevance'),
                    (ProductSort.priceLowHigh, 'Price — Low to High'),
                    (ProductSort.priceHighLow, 'Price — High to Low'),
                    (ProductSort.discount, 'Discount'),
                  ])
                    RadioListTile<ProductSort>(value: value, title: Text(label)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice != null) setState(() => _sort = choice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => AppRoutes.openSearch(context),
          ),
          IconButton(tooltip: 'Sort', icon: const Icon(Icons.sort_rounded), onPressed: _chooseSort),
        ],
      ),
      body: ListenableBuilder(
        listenable: _pager,
        builder: (context, _) {
          if (_pager.items.isEmpty && _pager.error != null) {
            return ErrorView(error: _pager.error!, onRetry: _pager.refresh);
          }
          if (_pager.isEmpty) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No products found',
              message: widget._mode == _Mode.search
                  ? 'We couldn\'t find anything for "${widget.value}". Try a different keyword.'
                  : 'There are no products here yet. Please check back later.',
              actionLabel: 'Browse all products',
              onAction: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProductListScreen.all()),
              ),
            );
          }
          final items = _sorted;
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels > n.metrics.maxScrollExtent - 500) _pager.loadMore();
              return false;
            },
            child: RefreshIndicator(
              onRefresh: _pager.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _pager.isFirstLoad
                                  ? 'Loading products…'
                                  : '${_pager.totalElements} product${_pager.totalElements == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          if (_sort != ProductSort.relevance)
                            InputChip(
                              label: Text(switch (_sort) {
                                ProductSort.priceLowHigh => 'Price ↑',
                                ProductSort.priceHighLow => 'Price ↓',
                                ProductSort.discount => 'Discount',
                                ProductSort.relevance => '',
                              }),
                              onDeleted: () => setState(() => _sort = ProductSort.relevance),
                              onPressed: _chooseSort,
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: productGridDelegate(context),
                      delegate: _pager.isFirstLoad
                          ? SliverChildBuilderDelegate((_, _) => const ProductCardSkeleton(), childCount: 6)
                          : SliverChildBuilderDelegate(
                              (_, i) => ProductCard(product: items[i]),
                              childCount: items.length,
                            ),
                    ),
                  ),
                  if (!_pager.isFirstLoad) SliverToBoxAdapter(child: PagerFooter(pager: _pager)),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
