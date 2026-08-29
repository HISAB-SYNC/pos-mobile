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
        const _NavItemData(icon: Icons.grid_view_rounded, label: 'More', isAction: true),
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
        const _NavItemData(icon: Icons.grid_view_rounded, label: 'More', isAction: true),
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
        const _NavItemData(icon: Icons.grid_view_rounded, label: 'More', isAction: true),
      ];
    }

    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x180F172A),
                blurRadius: 24,
                offset: Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(color: AppColors.borderLight, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = !item.isAction && safeIndex == index;

              return _buildNavButton(
                item: item,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
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
    );
  }

  Widget _buildNavButton({
    required _NavItemData item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.slateDark : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x22161B20),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active Top Dot Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 12 : 0,
              height: 2.5,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  size: 19,
                  color: isSelected ? Colors.white : AppColors.textMedium,
                ),
                if (item.badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -9,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.errorRose,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: Text(
                        item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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
