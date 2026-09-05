import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/cart/provider/cart_provider.dart';
import '../../features/shop/provider/shop_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_typography.dart';

class MoreFeaturesSheet extends StatelessWidget {
  const MoreFeaturesSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MoreFeaturesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shop = context.watch<ShopProvider>();
    final user = auth.currentUser;
    final selectedShop = shop.selectedShop;
    final isOwner = user?.isOwner == true;
    final isAdmin = user?.isAdmin == true;
    final isSales = user?.isSales == true;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // User & Shop Profile Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: AppDecorations.softCardDecoration(
                backgroundColor: AppColors.inputBackground,
                borderRadius: 16,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.brandLime,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.brandLimeDarkText,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedShop?.name ?? (isOwner ? 'Master Owner' : 'My Store'),
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textMedium,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOwner
                          ? const Color(0xFFEFF6FF)
                          : isAdmin
                              ? const Color(0xFFF1F5F9)
                              : AppColors.brandLimeBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOwner
                            ? const Color(0xFF3B82F6).withOpacity(0.3)
                            : isAdmin
                                ? const Color(0xFF64748B).withOpacity(0.3)
                                : AppColors.brandLimeBorder,
                      ),
                    ),
                    child: Text(
                      isOwner
                          ? 'OWNER'
                          : isAdmin
                              ? 'ADMIN'
                              : 'SALES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isOwner
                            ? const Color(0xFF1D4ED8)
                            : isAdmin
                                ? AppColors.slateDark
                                : AppColors.brandLimeDeep,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.borderLight),

          // Features Grid based on User Role
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                if (isSales) ...[
                  _buildSectionHeader('MY CASHIER WORKSPACE'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.point_of_sale_rounded,
                          title: 'POS Terminal',
                          subtitle: 'Direct Checkout',
                          route: '/catalog',
                          color: AppColors.brandLimeDeep,
                          bgColor: AppColors.brandLimeBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.receipt_long_rounded,
                          title: 'My Sales',
                          subtitle: 'Shift Orders History',
                          route: '/orders',
                          color: AppColors.successEmerald,
                          bgColor: AppColors.successBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.inventory_2_rounded,
                          title: 'Products',
                          subtitle: 'Price & Stock Lookup',
                          route: '/products',
                          color: const Color(0xFF0284C7),
                          bgColor: const Color(0xFFF0F9FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.category_rounded,
                          title: 'Categories',
                          subtitle: 'Catalog Sections',
                          route: '/categories',
                          color: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFF5F3FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.people_alt_rounded,
                          title: 'Customers',
                          subtitle: 'Debt & Directory',
                          route: '/customers',
                          color: AppColors.warningAmber,
                          bgColor: AppColors.warningBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          subtitle: 'Profile & Security',
                          route: '/settings',
                          color: AppColors.slateDark,
                          bgColor: AppColors.inputBackground,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildSectionHeader('INVENTORY & SALES'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.insights_rounded,
                          title: 'Reports',
                          subtitle: 'Analytics & Sales',
                          route: '/reports',
                          color: AppColors.primaryBlue,
                          bgColor: AppColors.infoBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.inventory_2_rounded,
                          title: 'Products',
                          subtitle: 'Stock Inventory',
                          route: '/products',
                          color: AppColors.successEmerald,
                          bgColor: AppColors.successBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.category_rounded,
                          title: 'Categories',
                          subtitle: 'Product Types',
                          route: '/categories',
                          color: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFF5F3FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.local_shipping_rounded,
                          title: 'Suppliers',
                          subtitle: 'Vendor Directory',
                          route: '/suppliers',
                          color: AppColors.warningAmber,
                          bgColor: AppColors.warningBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildSectionHeader('FINANCE & OPERATIONS'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.people_alt_rounded,
                          title: 'Customers',
                          subtitle: 'Debt & History',
                          route: '/customers',
                          color: const Color(0xFF0284C7),
                          bgColor: const Color(0xFFF0F9FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.receipt_long_rounded,
                          title: 'Expenses',
                          subtitle: 'Shop Costs',
                          route: '/expenses',
                          color: AppColors.errorRose,
                          bgColor: AppColors.errorBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.badge_rounded,
                          title: 'Staff',
                          subtitle: 'Team Accounts',
                          route: '/staff',
                          color: const Color(0xFF4F46E5),
                          bgColor: const Color(0xFFEEF2FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTile(
                          context,
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          subtitle: 'App & Hardware',
                          route: '/settings',
                          color: AppColors.slateDark,
                          bgColor: AppColors.inputBackground,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Logout Button
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _confirmLogout(context);
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.errorRose, size: 18),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.errorRose, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
    required Color bgColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final cart = context.read<CartProvider>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.errorRose, size: 22),
            SizedBox(width: 8),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: const Text('Are you sure you want to sign out of your POS session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
              await auth.logout();
              await shop.clear();
              cart.clearCart();
              nav.pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
