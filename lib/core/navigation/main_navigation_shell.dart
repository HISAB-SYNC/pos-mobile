import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/cart/provider/cart_provider.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../theme/app_colors.dart';
import 'more_features_sheet.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cart = context.watch<CartProvider>();
    final cartCount = cart.itemCount;

    final isSales = user?.isSales == true;
    final isOwner = user?.isOwner == true;

    // Dynamically build Pages & Navigation Items based on User Role
    final List<Widget> pages;
    final List<_NavItemData> navItems;

    if (isSales) {
      // Sales / Cashier View: Direct POS speed
      pages = const [
        CatalogPage(),
        CartPage(),
        OrdersPage(),
      ];
      navItems = [
        const _NavItemData(icon: Icons.point_of_sale_rounded, label: 'POS Terminal'),
        _NavItemData(icon: Icons.shopping_cart_rounded, label: 'Cart', badgeCount: cartCount),
        const _NavItemData(icon: Icons.receipt_long_rounded, label: 'My Sales'),
        const _NavItemData(icon: Icons.more_horiz_rounded, label: 'More', isAction: true),
      ];
    } else if (isOwner) {
      // Owner View: Executive oversight + Analytics + POS
      pages = const [
        DashboardPage(),
        ReportsPage(),
        CatalogPage(),
        OrdersPage(),
      ];
      navItems = [
        const _NavItemData(icon: Icons.dashboard_rounded, label: 'Overview'),
        const _NavItemData(icon: Icons.insights_rounded, label: 'Analytics'),
        const _NavItemData(icon: Icons.point_of_sale_rounded, label: 'POS'),
        const _NavItemData(icon: Icons.receipt_long_rounded, label: 'Orders'),
        const _NavItemData(icon: Icons.more_horiz_rounded, label: 'More', isAction: true),
      ];
    } else {
      // Admin / Manager View: Operations + Inventory + Orders
      pages = const [
        DashboardPage(),
        CatalogPage(),
        OrdersPage(),
        CartPage(),
      ];
      navItems = [
        const _NavItemData(icon: Icons.dashboard_rounded, label: 'Home'),
        const _NavItemData(icon: Icons.point_of_sale_rounded, label: 'POS'),
        const _NavItemData(icon: Icons.receipt_long_rounded, label: 'Orders'),
        _NavItemData(icon: Icons.shopping_cart_rounded, label: 'Cart', badgeCount: cartCount),
        const _NavItemData(icon: Icons.more_horiz_rounded, label: 'More', isAction: true),
      ];
    }

    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0E0F172A),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = !item.isAction && safeIndex == index;

                return _buildNavButton(
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (item.isAction) {
                      MoreFeaturesSheet.show(context);
                    } else {
                      setState(() {
                        _currentIndex = index;
                      });
                    }
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required _NavItemData item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.slateDark : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.textMedium,
                ),
                if (item.badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.errorRose,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final int badgeCount;
  final bool isAction;

  const _NavItemData({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    this.isAction = false,
  });
}
