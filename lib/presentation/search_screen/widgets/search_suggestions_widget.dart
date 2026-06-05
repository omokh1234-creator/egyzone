import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class SearchSuggestionsWidget extends StatelessWidget {
  const SearchSuggestionsWidget({
    super.key,
    required this.suggestions,
    this.onSuggestionTap,
  });

  final List<Map<String, dynamic>> suggestions;
  final Function(String suggestion, String type)? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 60,
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          final type = (suggestion['type'] as String?) ?? 'search';
          final text = (suggestion['text'] as String?) ?? '';
          final imageUrl = suggestion['imageUrl'] as String?;
          final price = suggestion['price'] as double?;
          final subCategories = suggestion['subCategories'] as List<String>?;

          return InkWell(
            onTap: () => onSuggestionTap?.call(text, type),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (type == 'product' &&
                          imageUrl != null &&
                          imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomImageWidget(
                            imageUrl: imageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        CustomIconWidget(
                          iconName: _getIconForType(type),
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                          size: 20,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (type == 'product' && price != null)
                              Text(
                                'ج.م ${_formatPrice(price)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      CustomIconWidget(
                        iconName: 'north_west',
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                        size: 14,
                      ),
                    ],
                  ),
                  if (type == 'category' &&
                      subCategories != null &&
                      subCategories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 64, top: 4),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: subCategories.take(3).map((sub) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sub,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getIconForType(String type) {
    switch (type) {
      case 'product':
        return 'shopping_bag';
      case 'category':
        return 'category';
      default:
        return 'search';
    }
  }

  String _formatPrice(double value) {
    final val = value.toStringAsFixed(2);
    final parts = val.split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    // Only show decimal part if it's not .00
    if (parts[1] == '00') {
      return integer;
    }
    return '$integer.${parts[1]}';
  }
}
