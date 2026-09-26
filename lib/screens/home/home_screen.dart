import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/home_data.dart';
import '../../providers/paged_products.dart';
import '../../services/product_service.dart';
import '../../widgets/inline_error.dart';
import '../../widgets/product_card.dart';
import '../../widgets/quick_logo.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeletons.dart';
import '../account/wishlist_screen.dart';
import '../ai/ai_chat_screen.dart';
import '../routes.dart';
import 'widgets/category_strip.dart';
import 'widgets/hero_carousel.dart';
import 'widgets/product_row_section.dart';

/// Home page (website: components/Home/MainHomePage.jsx) —
/// banners + categories like the website, plus live product sections.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ProductService();
  late final PagedProducts _all;
  int _reloadToken = 0;

  @override
  void initState() {
    super.initState();
    _all = PagedProducts((page) => _service.getProducts(pageNo: page))..loadMore();
  }

  @override
  void dispose() {
    _all.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _reloadToken++);
    await _all.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? AppColors.darkSurface : AppColors.brandYellow;
    final headerFg = isDark ? AppColors.brandYellow : AppColors.navy;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'ai-fab',
        tooltip: 'Ask Ayira AI',
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.brandYellow,
        onPressed: () => AppRoutes.push(context, const AiChatScreen()),
        child: const Icon(Icons.auto_awesome_rounded),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) _all.loadMore();
          return false;
        },
        child: RefreshIndicator(
          onRefresh: _refresh,
          edgeOffset: 150,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: headerBg,
                surfaceTintColor: Colors.transparent,
                systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
                titleSpacing: 16,
                title: QuickWordmark(color: headerFg),
                actions: [
                  IconButton(
                    tooltip: 'Wishlist',
                    color: headerFg,
                    icon: const Icon(Icons.favorite_border_rounded),
                    onPressed: () => AppRoutes.push(context, const WishlistScreen()),
                  ),
                  const SizedBox(width: 4),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(66),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _SearchPill(onTap: () => AppRoutes.openSearch(context)),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: headerBg,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  height: 28,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 4)),
              const SliverToBoxAdapter(child: _Translate(child: HeroCarousel(banners: HomeData.banners))),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(child: CategoryStrip()),
              SliverToBoxAdapter(
                child: ProductRowSection(
                  title: 'Top in Electronics',
                  subtitle: 'Gadgets & appliances',
                  category: 'electronics',
                  reloadToken: _reloadToken,
                ),
              ),
              const SliverToBoxAdapter(child: _AiPromoCard()),
              SliverToBoxAdapter(
                child: ProductRowSection(
                  title: 'Trending in Fashion',
                  subtitle: 'Clothing picks for you',
                  category: 'Clothing',
                  reloadToken: _reloadToken,
                ),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Explore all products',
                  subtitle: 'Fresh from Quick sellers',
                  onViewAll: () => AppRoutes.openAllProducts(context),
                ),
              ),
              ListenableBuilder(
                listenable: _all,
                builder: (context, _) => _AllProductsGrid(pager: _all),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulls the carousel up so it overlaps the curved yellow header.
class _Translate extends StatelessWidget {
  const _Translate({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Transform.translate(offset: const Offset(0, -26), child: child);
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurfaceHigh : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: isDark ? 0 : 1.5,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search_rounded, color: isDark ? AppColors.brandYellow : AppColors.navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search for products, brands and more',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiPromoCard extends StatelessWidget {
  const _AiPromoCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => AppRoutes.push(context, const AiChatScreen()),
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navy, AppColors.navySoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppColors.navy, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Not sure what to buy?',
                          style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Ask Ayira AI for product ideas, comparisons and gift picks.',
                          style: t.bodySmall?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.brandYellow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllProductsGrid extends StatelessWidget {
  const _AllProductsGrid({required this.pager});
  final PagedProducts pager;

  @override
  Widget build(BuildContext context) {
    if (pager.isFirstLoad) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: productGridDelegate(context),
          delegate: SliverChildBuilderDelegate((_, _) => const ProductCardSkeleton(), childCount: 4),
        ),
      );
    }
    if (pager.items.isEmpty && pager.error != null) {
      return SliverToBoxAdapter(child: InlineError(error: pager.error!, onRetry: pager.refresh));
    }
    if (pager.items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No products yet. Sellers are adding them soon!')),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: productGridDelegate(context),
            delegate: SliverChildBuilderDelegate(
              (_, i) => ProductCard(product: pager.items[i]),
              childCount: pager.items.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: PagerFooter(pager: pager)),
      ],
    );
  }
}
