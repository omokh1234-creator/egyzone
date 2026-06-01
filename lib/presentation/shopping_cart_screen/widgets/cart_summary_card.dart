import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Cart summary card showing pricing breakdown and checkout button
class CartSummaryCard extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final bool isCartEmpty;
  final VoidCallback onCheckout;
  final VoidCallback onPromoCodeTap;
  final bool hasPromoCode;
  final String? promoCodeDiscount;

  const CartSummaryCard({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.isCartEmpty,
    required this.onCheckout,
    required this.onPromoCodeTap,
    this.hasPromoCode = false,
    this.promoCodeDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Promo Code Section
              InkWell(
                onTap: onPromoCodeTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: hasPromoCode
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: hasPromoCode ? 'check_circle' : 'local_offer',
                        color: hasPromoCode
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          hasPromoCode
                              ? 'Promo code applied'
                              : 'Apply promo code',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: hasPromoCode
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: hasPromoCode
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      CustomIconWidget(
                        iconName: 'chevron_right',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              // Price Breakdown
              _buildPriceRow('Subtotal', subtotal, theme, false),
              SizedBox(height: 1.h),
              _buildPriceRow('Tax', tax, theme, false),
              SizedBox(height: 1.h),
              _buildPriceRow(
                'Shipping',
                shipping == 0 ? 0 : shipping,
                theme,
                false,
                isFree: shipping == 0,
              ),
              hasPromoCode && promoCodeDiscount != null
                  ? Column(
                      children: [
                        SizedBox(height: 1.h),
                        _buildPriceRow(
                          'Promo Discount',
                          double.tryParse(promoCodeDiscount!) ?? 0,
                          theme,
                          false,
                          isDiscount: true,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              SizedBox(height: 1.5.h),
              Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                thickness: 1,
              ),
              SizedBox(height: 1.5.h),
              _buildPriceRow('Total', total, theme, true),
              SizedBox(height: 2.h),
              // Checkout Button
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: isCartEmpty ? null : onCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Proceed to Checkout',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isCartEmpty
                              ? theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.38,
                                )
                              : theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      CustomIconWidget(
                        iconName: 'arrow_forward',
                        color: isCartEmpty
                            ? theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.38,
                              )
                            : theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double value,
    ThemeData theme,
    bool isTotal, {
    bool isDiscount = false,
    bool isFree = false,
  }) {
    String formatPrice(double price) {
      final val = price.toStringAsFixed(2);
      final parts = val.split('.');
      final integer = parts[0].replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
      return '$integer.${parts[1]}';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                )
              : theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
        isFree
            ? Text(
                'FREE',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Row(
                children: [
                  Text(
                    'ج.م ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize:
                          (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.8,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    formatPrice(value),
                    style: isTotal
                        ? theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          )
                        : theme.textTheme.bodyLarge?.copyWith(
                            color: isDiscount
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight:
                                isDiscount ? FontWeight.w600 : FontWeight.w500,
                          ),
                  ),
                ],
              ),
      ],
    );
  }
}
