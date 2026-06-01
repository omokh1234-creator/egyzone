import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Quantity Selector Widget
/// Displays quantity selector with increment/decrement buttons
class QuantitySelectorWidget extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantitySelectorWidget({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 6.h,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement Button
          SizedBox(
            width: 10.w,
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'remove',
                color: quantity > 1
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 20,
              ),
              onPressed: quantity > 1 ? onDecrement : null,
              tooltip: 'Decrease quantity',
            ),
          ),

          // Quantity Display
          Container(
            width: 12.w,
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          // Increment Button
          SizedBox(
            width: 10.w,
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'add',
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              onPressed: onIncrement,
              tooltip: 'Increase quantity',
            ),
          ),
        ],
      ),
    );
  }
}
