import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../core/providers/auth_provider.dart';
import '../core/providers/cart_provider.dart';
import '../core/providers/saved_items_provider.dart';
import '../theme/app_theme.dart';

/// Shows a premium Twitter-style bottom sheet asking the user to sign in
/// when they attempt a protected action while not authenticated.
///
/// Returns `true` if the user successfully authenticated, `false` otherwise.
Future<bool> requireAuth(BuildContext context, {String? reason}) async {
  final auth = context.read<AuthProvider>();
  if (auth.isLoggedIn) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AuthGateSheet(reason: reason),
  );
  return result == true;
}

class AuthGateSheet extends StatelessWidget {
  final String? reason;
  const AuthGateSheet({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Logo
              SizedBox(
                height: 80,
                child: Image.asset(
                  AppTheme.getLogoPath(context),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 5),
              
              // Brand Name
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'EGY',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 24, // Slightly smaller than login screens
                      ),
                    ),
                    TextSpan(
                      text: 'ZONE',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),

              // Headline
              Text(
                reason ?? 'Sign in to continue',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),

              // Sign In button (primary)
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(context); // close sheet
                    final ok = await Navigator.pushNamed(
                      context,
                      '/login-screen',
                      arguments: {'canGoBack': true},
                    );
                    // Return true to caller if login succeeded
                    if (context.mounted) {
                      Navigator.pop(context, ok == true);
                    }
                  },
                  child: const Text(
                    'Sign in',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),

              // Create account button (outlined)
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final ok = await Navigator.pushNamed(
                      context,
                      '/register-screen',
                      arguments: {'canGoBack': true},
                    );
                    if (context.mounted) {
                      Navigator.pop(context, ok == true);
                    }
                  },
                  child: const Text(
                    'Create account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 1.h),

              // Continue as guest
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Continue browsing as guest',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
              SizedBox(height: 1.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline widget — shows a guest banner inside the profile screen or any
/// screen that needs to react to auth state.
class GuestPromptWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? reason;
  final VoidCallback? onAuthenticated;
  const GuestPromptWidget({
    super.key,
    this.title = 'Sign in to your account',
    this.subtitle = 'Access orders, wishlist and a personalised experience.',
    this.reason,
    this.onAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline_rounded,
                  size: 48, color: cs.primary),
            ),
            SizedBox(height: 2.5.h),
            Text(
              title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () async {
                  final cartProvider = context.read<CartProvider>();
                  final savedProvider = context.read<SavedItemsProvider>();
                  final ok = await requireAuth(context, reason: reason);
                  if (ok) {
                    await cartProvider.refreshFromServer();
                    await savedProvider.refreshFromServer();
                    onAuthenticated?.call();
                  }
                },
                child: const Text(
                  'Sign in',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 1.5.h),
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, '/register-screen',
                        arguments: {'canGoBack': true}),
                child: const Text(
                  'Create account',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
