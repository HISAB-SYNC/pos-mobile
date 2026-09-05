import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/cart/provider/cart_provider.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/provider/dashboard_provider.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/orders/provider/orders_provider.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/shop/provider/shop_provider.dart';
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final user = context.read<AuthProvider>().currentUser;
      if (user?.isSales == true && widget.initialIndex == 0) {
        _currentIndex = 1; // Direct to POS Terminal for Sales
      }
    }
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
      // Sales / Cashier View: Alternative 4-Item Layout with centered POS Hero button
      pages = const [
        CartPage(),
        CatalogPage(),
        OrdersPage(),
      ];
      navItems = [
        _NavItemData(icon: Icons.shopping_cart_rounded, label: 'Cart', badgeCount: cartCount),
        const _NavItemData(icon: Icons.point_of_sale_rounded, label: 'POS Terminal', isHero: true),
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
        const _NavItemData(icon: Icons.home_rounded, label: 'Home'),
        const _NavItemData(icon: Icons.insights_rounded, label: 'Analytics'),
        const _NavItemData(icon: Icons.point_of_sale_rounded, label: 'POS', isHero: true),
        const _NavItemData(icon: Icons.receipt_long_rounded, label: 'Orders'),
        const _NavItemData(icon: Icons.grid_view_rounded, label: 'More', isAction: true),
      ];
    } else {
      // Admin / Manager View: Operations + Inventory + Orders with centered POS Hero button
      pages = const [
        DashboardPage(),
        OrdersPage(),
        CatalogPage(),
        CartPage(),
      ];
      navItems = [
        const _NavItemData(icon: Icons.home_rounded, label: 'Home'),
        const _NavItemData(icon: Icons.receipt_long_rounded, label: 'Orders'),
        const _NavItemData(icon: Icons.point_of_sale_rounded, label: 'POS', isHero: true),
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
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 18,
                offset: Offset(0, 5),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 6,
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

              if (item.isHero) {
                return _buildHeroNavButton(
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
              }

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
                    // Proactively refresh dashboard metrics & transactions when returning to Overview / Home tab
                    if (index == 0 && !isSales) {
                      final auth = context.read<AuthProvider>();
                      final shop = context.read<ShopProvider>();
                      final shopId = shop.selectedShop?.id ?? '';
                      final token = auth.token;
                      if (shopId.isNotEmpty && token != null) {
                        context.read<DashboardProvider>().loadDashboardMetrics(
                              shopId: shopId,
                              token: token,
                              isSalesRole: false,
                            );
                        context.read<OrdersProvider>().loadOrders(shopId: shopId, token: token);
                      }
                    }
                  }
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroNavButton({
    required _NavItemData item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Elevated popped-up hero container
              Transform.translate(
                offset: const Offset(0, -7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? [AppColors.brandLime, AppColors.brandLimeDark]
                          : [AppColors.brandLime.withValues(alpha: 0.9), AppColors.brandLimeDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandLime.withValues(alpha: isSelected ? 0.65 : 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: isSelected ? 1 : 0,
                      ),
                    ],
                    border: Border.all(
                      color: isSelected ? Colors.white : AppColors.brandLimeDark,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.point_of_sale_rounded,
                      size: 22,
                      color: AppColors.brandLimeDarkText,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -5),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.brandLimeDeep : AppColors.textMedium,
                  ),
                ),
              ),
            ],
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
    const activeColor = AppColors.brandLimeDeep;
    const activeBgColor = AppColors.brandLimeBg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with soft tinted rounded container when active
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? activeBgColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: isSelected ? activeColor : AppColors.textMuted,
                    ),
                    if (item.badgeCount > 0)
                      Positioned(
                        top: -4,
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
              ),
              const SizedBox(height: 1),

              // Label
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),

              // Circular Dot indicator under active menu item
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 4 : 0,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
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
  final bool isHero;

  const _NavItemData({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    this.isAction = false,
    this.isHero = false,
  });
}
