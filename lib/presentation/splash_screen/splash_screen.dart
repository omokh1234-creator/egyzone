import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Splash Screen for EGYZONE e-commerce application
/// Provides branded launch experience while initializing app services
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  // ignore: unused_field
  bool _isInitialized = false;
  String _statusMessage = 'Loading...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _statusMessage = 'Loading products...');

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _statusMessage = 'Preparing catalog...');

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _statusMessage = 'Initializing cart...');

      // Check if user already has a saved token
      final token = await AuthService.getToken();

      if (token != null && mounted) {
        try {
          // Initialize user profile if token exists
          await context.read<AuthProvider>().loadProfile();
        } catch (e) {
          debugPrint('Session restoration skipped: $e');
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _isInitialized = true);

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.isLoggedIn) {
          final role = auth.displayRole.toLowerCase();
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin/moderation');
            return;
          } else if (role == 'seller') {
            Navigator.pushReplacementNamed(context, '/seller/inventory');
            return;
          }
        }
        // ALWAYS go to home-screen for customers and guests
        Navigator.pushReplacementNamed(context, '/home-screen');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Connection error. Retrying...');
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _initializeApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [

              // Background decoration
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated logo
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            AppTheme.getLogoPath(context),
                            fit: BoxFit.contain,
                            semanticLabel: 'EGYZONE Logo',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // App name
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'EGY',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'ZONE',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Your Shopping Destination',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),

                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Status message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusMessage,
                        key: ValueKey<String>(_statusMessage),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Version info
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Version 1.0.0',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
