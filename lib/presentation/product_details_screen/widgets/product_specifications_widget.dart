import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Product Specifications Widget
/// Displays product specifications in a clean list format
class ProductSpecificationsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> specifications;

  const ProductSpecificationsWidget({super.key, required this.specifications});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Hide section entirely if no specs
    if (specifications.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Specifications',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 2.h),

          // Specifications List
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: specifications.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                final spec = specifications[index];

                // Handle both key names: 'name' (remapped) and 'label' (raw API)
                final label = spec['name'] as String? ??
                    spec['label'] as String? ??
                    '';
                final value = spec['value'] as String? ?? '';

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label
                      Expanded(
                        flex: 2,
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      SizedBox(width: 4.w),

                      // Value
                      Expanded(
                        flex: 3,
                        child: Text(
                          value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
