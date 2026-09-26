import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/category_node.dart';
import '../../models/home_data.dart';
import '../../services/product_service.dart';
import '../../widgets/inline_error.dart';
import '../../widgets/net_image.dart';
import '../../widgets/skeletons.dart';
import '../routes.dart';

/// Category browser. Data: GET /products/category/tree
/// (website: redux-store/Categories → Sidebar filters).
///
/// Tapping a category opens `GET /products/page/category/main?category=<name>`.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<CategoryNode>? _tree;
  ApiException? _error;
  bool _loading = true;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tree = await ProductService().getCategoryTree();
      if (!mounted) return;
      setState(() {
        _tree = tree;
        _selected = 0;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => AppRoutes.openSearch(context),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
    );
  }

  Widget _body() {
    if (_loading && _tree == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          6,
          (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: ShimmerBox(height: 56, radius: 12)),
        ),
      );
    }
    final tree = _tree ?? const [];
    if (tree.isEmpty) {
      // Backend unreachable or no categories yet: show the website's
      // featured categories so the screen is still useful.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_error != null) InlineError(error: _error!, onRetry: _load),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Featured categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const _FeaturedGrid(),
        ],
      );
    }

    final selected = tree[_selected.clamp(0, tree.length - 1)];
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left rail: top-level categories
        Container(
          width: 104,
          color: scheme.surfaceContainerLow,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: tree.length,
            itemBuilder: (_, i) {
              final active = i == _selected;
              return InkWell(
                onTap: () => setState(() => _selected = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: active ? scheme.surface : Colors.transparent,
                    border: Border(
                      left: BorderSide(color: active ? scheme.secondary : Colors.transparent, width: 4),
                    ),
                  ),
                  child: Column(
                    children: [
                      _Initial(name: tree[i].name, active: active),
                      const SizedBox(height: 6),
                      Text(
                        prettyCategory(tree[i].name),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Right: sub-categories of the selected one
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text('All ${prettyCategory(selected.name)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Browse every product'),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () => AppRoutes.openCategory(context, category: selected.name),
                ),
              ),
              const SizedBox(height: 16),
              if (!selected.hasChildren)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text('No sub-categories', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              for (final child in selected.children) _SubCategory(node: child),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubCategory extends StatelessWidget {
  const _SubCategory({required this.node});
  final CategoryNode node;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => AppRoutes.openCategory(context, category: node.name),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(prettyCategory(node.name), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ),
          if (node.hasChildren) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final leaf in node.children)
                  ActionChip(
                    label: Text(prettyCategory(leaf.name)),
                    onPressed: () => AppRoutes.openCategory(context, category: leaf.name),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.name, required this.active});
  final String name;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 20,
      backgroundColor: active ? scheme.secondary : scheme.surfaceContainerHigh,
      foregroundColor: active ? scheme.onSecondary : scheme.onSurfaceVariant,
      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _FeaturedGrid extends StatelessWidget {
  const _FeaturedGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: HomeData.categories.length,
      itemBuilder: (context, i) {
        final c = HomeData.categories[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => AppRoutes.openCategory(context, category: c.category, title: c.name),
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetImage(c.image),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 10,
                  right: 12,
                  child: Text(
                    c.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
