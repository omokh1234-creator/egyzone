import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/saved_items_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.login(email, password);

      if (!mounted) return;
      // Load user profile into AuthProvider
      await context.read<AuthProvider>().loadProfile();

      if (!mounted) return;
      // Refresh cart and wishlist from server now that we have a token
      await context.read<CartProvider>().refreshFromServer();
      if (!mounted) return;
      await context.read<SavedItemsProvider>().refreshFromServer();

      if (!mounted) return;
      
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final bool canGoBack = args?['canGoBack'] == true;

      if (canGoBack) {
        // Opened from within the app — just pop and signal success
        Navigator.pop(context, true);
      } else {
        final auth = context.read<AuthProvider>();
        final role = auth.displayRole.toLowerCase();
        String initialRoute = '/home-screen';
        if (role == 'admin') {
          initialRoute = '/admin/moderation';
        } else if (role == 'seller') {
          initialRoute = '/seller/inventory';
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          initialRoute,
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      String message = e.toString().split(':').last.trim();
      if (message.contains('401')) {
        message = 'Invalid email or password';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool canGoBack = args?['canGoBack'] == true;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: canGoBack
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              ),
            )
          : CustomAppBar(
              style: CustomAppBarStyle.minimal,
              showSearchButton: false,
              showCartButton: false,
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = MediaQuery.of(context).size.height;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
            child: Transform.translate(
              offset: Offset(0, -screenHeight * 0.05),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 120,
                    child: Image.asset(
                      AppTheme.getLogoPath(context),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'EGY',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: 'ZONE',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/forgot-password-screen'),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register-screen'),
                    child: const Text("Don't have an account? Sign Up"),
                  ),
                  if (!canGoBack) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home-screen',
                        (route) => false,
                      ),
                      child: Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
