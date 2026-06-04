import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// App bar style variants for different screen contexts
enum CustomAppBarStyle {
  standard,
  search,
  transparent,
  minimal,
}

/// Custom app bar for EGYZONE e-commerce app
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.style = CustomAppBarStyle.standard,
    this.showBackButton = false,
    this.showSearchButton = true,
    this.showCartButton = true,
    this.showChatBotButton = false,
    this.cartItemCount = 0,
    this.onSearchTap,
    this.onCartTap,
    this.onChatBotTap,
    this.onBackButtonPressed,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.actions,
  });

  final String? title;
  final CustomAppBarStyle style;
  final bool showBackButton;
  final bool showSearchButton;
  final bool showCartButton;
  final bool showChatBotButton;
  final int cartItemCount;
  final VoidCallback? onSearchTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onChatBotTap;
  final VoidCallback? onBackButtonPressed;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = _getBackgroundColor(colorScheme);
    final foregroundColor = _getForegroundColor(colorScheme);

    final overlayStyle = style == CustomAppBarStyle.transparent
        ? SystemUiOverlayStyle.light
        : theme.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light;

    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      systemOverlayStyle: overlayStyle,
      centerTitle: false,
      leading: showBackButton && Navigator.canPop(context)
          ? _buildBackButton(context)
          : null,
      title: _buildTitle(context),
      actions: _buildActions(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12), // slight curvature at bottom ends
        ),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (style) {
      case CustomAppBarStyle.transparent:
        return Colors.transparent;
      default:
        return colorScheme.surface;
    }
  }

  Color _getForegroundColor(ColorScheme colorScheme) {
    switch (style) {
      case CustomAppBarStyle.transparent:
        return Colors.white;
      default:
        return colorScheme.onSurface;
    }
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: onBackButtonPressed ?? () => Navigator.of(context).pop(),
    );
  }

  /// 🔹 TITLE WITH LOGO + EGYZONE
  Widget? _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (style) {
      case CustomAppBarStyle.search:
        return _SearchField(
          controller: searchController,
          onChanged: onSearchChanged,
          onSubmitted: onSearchSubmitted,
        );

      case CustomAppBarStyle.minimal:
      case CustomAppBarStyle.transparent:
        return null;

      case CustomAppBarStyle.standard:
        if (title == null) return null;

        if (title!.toUpperCase() == 'EGYZONE') {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// 🖼 LOGO IMAGE
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  height: 45,
                  child: Image.asset(
                    AppTheme.getLogoPath(context),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 7),

              /// 📝 TEXT
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'EGY',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: (theme.textTheme.titleLarge?.fontSize ?? 22) * 0.95,
                        ),
                      ),
                      TextSpan(
                        text: 'ZONE',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: style == CustomAppBarStyle.transparent
                              ? Colors.white
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: (theme.textTheme.titleLarge?.fontSize ?? 22) * 0.95,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Text(title!, style: theme.textTheme.titleLarge);
    }
  }

  List<Widget>? _buildActions(BuildContext context) {
    final actionsList = <Widget>[];

    if (showSearchButton && style != CustomAppBarStyle.search) {
      actionsList.add(
        _CompactIconButton(
          icon: const Icon(Icons.search, size: 24),
          onPressed: onSearchTap ??
              () => Navigator.pushNamed(context, '/search-screen'),
        ),
      );
    }

    if (showCartButton) {
      actionsList.add(
        _CompactCartButton(
          itemCount: cartItemCount,
          onTap: onCartTap ??
              () => Navigator.pushNamed(context, '/shopping-cart-screen'),
        ),
      );
    }

    if (actions != null) {
      actionsList.addAll(actions!);
    }

    // Chatbot always on the rightmost position
    if (showChatBotButton) {
      actionsList.add(
        _ChatBotButton(
          onTap: onChatBotTap ??
              () => Navigator.pushNamed(context, '/chat-bot-screen'),
        ),
      );
    }

    return actionsList.isNotEmpty ? actionsList : null;
  }
}

/// 🔍 Search field widget
class _SearchField extends StatelessWidget {
  const _SearchField({this.controller, this.onChanged, this.onSubmitted});

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, size: 20),
          hintText: 'Search products...',
        ),
      ),
    );
  }
}

/// Chat button with primary color
class _ChatBotButton extends StatelessWidget {
  const _ChatBotButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _CompactIconButton(
      icon: Icon(
        Icons.smart_toy_outlined,
        color: colorScheme.primary,
        size: 24,
      ),
      onPressed: onTap,
      tooltip: 'Chat',
    );
  }
}

/// Compact icon button with reduced padding to fix spacing issues
class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}

/// Compact cart button with reduced padding
class _CompactCartButton extends StatelessWidget {
  const _CompactCartButton({required this.itemCount, required this.onTap});

  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 24),
            if (itemCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    itemCount > 99 ? '99+' : itemCount.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onError,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
