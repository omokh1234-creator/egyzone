import 'package:flutter/material.dart';

/// Navigation item configuration for bottom bar
enum CustomBottomBarItem {
  home(
    route: '/home-screen',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
  ),
  cart(
    route: '/shopping-cart-screen',
    icon: Icons.shopping_bag_outlined,
    activeIcon: Icons.shopping_bag,
    label: 'Cart',
  ),
  chatBot(
    route: '/chat-bot-screen',
    icon: Icons.chat_bubble_outline,
    activeIcon: Icons.chat_bubble,
    label: 'Chat',
  ),
  inventory(
    route: '/seller/inventory',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
    label: 'Inventory',
  ),
  moderation(
    route: '/admin/moderation',
    icon: Icons.gavel_outlined,
    activeIcon: Icons.gavel,
    label: 'Moderate',
  ),
  profile(
    route: '/profile-screen',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
  );

  const CustomBottomBarItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({
    super.key,
    required this.currentRoute,
    this.cartItemCount = 0,
    this.role = 'customer',
    this.onTap,
  });

  final String currentRoute;
  final int cartItemCount;
  final String role;
  final ValueChanged<String>? onTap;

  List<CustomBottomBarItem> get _visibleItems {
    final normalizedRole = role.toLowerCase();
    switch (normalizedRole) {
      case 'seller':
        return [
          CustomBottomBarItem.inventory,
          CustomBottomBarItem.profile,
        ];
      case 'admin':
        return [
          CustomBottomBarItem.moderation,
          CustomBottomBarItem.profile,
        ];
      default:
        return [
          CustomBottomBarItem.home,
          CustomBottomBarItem.cart,
          CustomBottomBarItem.profile,
        ];
    }
  }

  int get _currentIndex {
    final items = _visibleItems;
    for (int i = 0; i < items.length; i++) {
      if (items[i].route == currentRoute) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = _visibleItems;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final index = items.indexOf(item);
              final isSelected = _currentIndex == index;
              final isCart = item == CustomBottomBarItem.cart;
              final showBadge = isCart && cartItemCount > 0;

              return Expanded(
                child: _BottomBarButton(
                  item: item,
                  isSelected: isSelected,
                  showBadge: showBadge,
                  badgeCount: cartItemCount,
                  onTap: () {
                    if (onTap != null) {
                      onTap!(item.route);
                    } else {
                      if (item.route == '/home-screen') {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          item.route,
                          (route) => false,
                        );
                      } else {
                        Navigator.pushNamed(context, item.route);
                      }
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Individual bottom bar button with animation and badge support
class _BottomBarButton extends StatefulWidget {
  const _BottomBarButton({
    required this.item,
    required this.isSelected,
    required this.showBadge,
    required this.badgeCount,
    required this.onTap,
  });

  final CustomBottomBarItem item;
  final bool isSelected;
  final bool showBadge;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  State<_BottomBarButton> createState() => _BottomBarButtonState();
}

class _BottomBarButtonState extends State<_BottomBarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconColor =
        widget.isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    final labelColor =
        widget.isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Icon(
                      widget.isSelected
                          ? widget.item.activeIcon
                          : widget.item.icon,
                      color: iconColor,
                      size: widget.isSelected ? 28 : 24,
                    ),
                  ),
                  if (widget.showBadge)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: _CartBadge(count: widget.badgeCount),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: labelColor,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cart badge indicator showing item count
class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: count > 9 ? 5 : 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.surface,
          width: 1.5,
        ),
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Text(
        displayCount,
        style: theme.textTheme.labelSmall!.copyWith(
          color: colorScheme.onError,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
