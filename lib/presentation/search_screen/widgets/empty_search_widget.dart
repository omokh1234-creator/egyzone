import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EmptySearchWidget extends StatelessWidget {
  const EmptySearchWidget({
    super.key,
    this.onCategoryTap,
  });

  final ValueChanged<String>? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = context.watch<CategoryProvider>();

    final categories = categoryProvider.categories;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Start Your Search',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for products, brands, or categories',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (categories.isNotEmpty) ...[
              Text(
                'Suggested Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...categories.map((category) => _buildCategoryCard(context, theme, category)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ThemeData theme, dynamic category) {
    final categoryName = category.name as String;
    final subCategories = category.subCategories as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/search-screen', arguments: {'category': categoryName}),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: _getIconForCategory(categoryName),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (subCategories.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subCategories.map((sub) {
                  final subName = sub.name as String;
                  return InkWell(
                    onTap: () => Navigator.pushNamed(context, '/search-screen', arguments: {'category': categoryName}),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        subName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _getIconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('electr')) return 'devices';
    if (n.contains('fash')) return 'checkroom';
    if (n.contains('home') || n.contains('furn')) return 'home';
    if (n.contains('beauty') || n.contains('care')) return 'face';
    if (n.contains('groc') || n.contains('food')) return 'shopping_basket';
    if (n.contains('health') || n.contains('fit')) return 'fitness_center';
    if (n.contains('book')) return 'menu_book';
    if (n.contains('toy') || n.contains('baby')) return 'child_care';
    if (n.contains('auto') || n.contains('tool')) return 'build';
    if (n.contains('sport')) return 'sports_soccer';
    if (n.contains('digit')) return 'qr_code_2';
    return 'category';
  }
}
