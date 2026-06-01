import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Search suggestions dropdown list that appears as the user types
class SearchSuggestionsWidget extends StatelessWidget {
  const SearchSuggestionsWidget({
    super.key,
    required this.suggestions,
    this.onSuggestionTap,
  });

  /// Expects a list of maps: [{'text': 'iPhone 15', 'type': 'product'}]
  final List<Map<String, dynamic>> suggestions;
  final ValueChanged<String>? onSuggestionTap;

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
          indent:
              50, // Aligns divider with the text, keeping the icon area clean
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          final type = (suggestion['type'] as String?) ?? 'search';
          final text = (suggestion['text'] as String?) ?? '';

          return ListTile(
            dense: true,
            leading: CustomIconWidget(
              iconName: _getIconForType(type),
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              size: 20,
            ),
            title: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
            trailing: CustomIconWidget(
              iconName:
                  'north_west', // The classic "arrow" for search suggestions
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 14,
            ),
            onTap: () => onSuggestionTap?.call(text),
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
      case 'history':
        return 'history';
      default:
        return 'search';
    }
  }
}
