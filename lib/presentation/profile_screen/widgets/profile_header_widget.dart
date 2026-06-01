import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic>? userProfile;

  const ProfileHeaderWidget({super.key, this.userProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool isGuest = userProfile == null;
    final String name = userProfile?['fullName'] ?? 'Guest';
    final String email = userProfile?['email'] ?? 'Sign in to unlock full features';
    final String phone = userProfile?['phoneNumber'] ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'person',
                size: 10.w,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isGuest && phone.isNotEmpty) ...[
            SizedBox(height: 0.2.h),
            Text(
              phone,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          
          if (isGuest) ...[
            SizedBox(height: 2.h),
            SizedBox(
              height: 5.h,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login-screen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text('Login / Sign Up'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
