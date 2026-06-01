import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Empty search state with suggestions matched to your Home Screen categories
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

    // Dynamic categories from provider
    final categories = categoryProvider.categories.map((c) => {
      'name': c.name,
      'icon': _getIconForCategory(c.name),
    }).toList();

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
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: categories.map((category) {
                  return InkWell(
                    onTap: () => onCategoryTap?.call(category['name'] as String),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: category['icon'] as String,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category['name'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
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
    return 'category'; // default
  }
}
