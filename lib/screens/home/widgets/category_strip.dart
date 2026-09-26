import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/home_data.dart';
import '../../../providers/shell_controller.dart';
import '../../../widgets/net_image.dart';
import '../../routes.dart';

/// Round category shortcuts (website: CategorySection with MUI Avatars).
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = HomeData.categories;

    return SizedBox(
      height: MediaQuery.textScalerOf(context).scale(18) + 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          if (i == categories.length) {
            return _Item(
              label: 'All',
              onTap: () => context.read<ShellController>().goTo(ShellTab.categories),
              child: Container(
                color: scheme.secondaryContainer,
                child: Icon(Icons.grid_view_rounded, color: scheme.onSecondaryContainer, size: 28),
              ),
            );
          }
          final c = categories[i];
          return _Item(
            label: c.name,
            onTap: () => AppRoutes.openCategory(context, category: c.category, title: c.name),
            child: NetImage(c.image, fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.child, required this.onTap});
  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.secondary, width: 2),
              ),
              child: ClipOval(child: child),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
