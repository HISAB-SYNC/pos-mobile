import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../cart/provider/cart_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../../auth/presentation/widgets/provision_owner_dialog.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    this.currentRoute = '/dashboard',
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shopProvider = context.watch<ShopProvider>();
    final user = auth.currentUser;
    final selectedShop = shopProvider.selectedShop;

    final isOwner = user?.isOwner ?? false;
    final isAdmin = user?.isAdmin ?? false;
    final isSales = user?.isSales ?? false;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/andalus11.png',
                        height: 38,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.storefront,
                          size: 32,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Andalus',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF161B20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.navy,
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF161B20),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isOwner
                                    ? const Color(0xFFEFF6FF)
                                    : isAdmin
                                        ? const Color(0xFFF0FDF4)
                                        : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user?.role ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isOwner
                                      ? const Color(0xFF1D4ED8)
                                      : isAdmin
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (selectedShop != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            selectedShop.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Navigation List Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: isSales ? 'My Shift Dashboard' : 'Dashboard',
                    isActive: currentRoute == '/dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/dashboard') {
                        Navigator.pushReplacementNamed(context, '/dashboard');
                      }
                    },
                  ),
                  // _DrawerItem(
                  //   icon: Icons.point_of_sale_outlined,
                  //   label: 'POS Terminal',
                  //   isActive: currentRoute == '/catalog',
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     Navigator.pushNamed(context, '/catalog');
                  //   },
                  // ),
              
                  _DrawerItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Products',
                    isActive: currentRoute == '/products',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/products') {
                        Navigator.pushNamed(context, '/products');
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.label_outline,
                    label: 'Categories',
                    isActive: currentRoute == '/categories',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/categories') {
                        Navigator.pushNamed(context, '/categories');
                      }
                    },
                  ),
                  if (isOwner || isAdmin) ...[
                    _DrawerItem(
                      icon: Icons.assessment_outlined,
                      label: 'Reports',
                      isActive: currentRoute == '/reports',
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != '/reports') {
                          Navigator.pushNamed(context, '/reports');
                        }
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.people_outline,
                      label: 'Suppliers',
                      isActive: currentRoute == '/suppliers',
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != '/suppliers') {
                          Navigator.pushNamed(context, '/suppliers');
                        }
                      },
                    ),
                  ],
                  _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    label: isSales ? 'My Sales History' : 'Orders',
                    isActive: currentRoute == '/orders',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/orders') {
                        Navigator.pushNamed(context, '/orders');
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.groups_outlined,
                    label: 'Customers',
                    isActive: currentRoute == '/customers',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/customers') {
                        Navigator.pushNamed(context, '/customers');
                      }
                    },
                  ),
                  if (isOwner || isAdmin) ...[
                    _DrawerItem(
                      icon: Icons.credit_card_outlined,
                      label: 'Expenses',
                      isActive: currentRoute == '/expenses',
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != '/expenses') {
                          Navigator.pushNamed(context, '/expenses');
                        }
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Manage Staff',
                      isActive: currentRoute == '/staff',
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != '/staff') {
                          Navigator.pushNamed(context, '/staff');
                        }
                      },
                    ),
                  ],
                  if (isOwner)
                    _DrawerItem(
                      icon: Icons.store_outlined,
                      label: 'My Shops',
                      isActive: currentRoute == '/shops',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/shops');
                      },
                    ),
                  if (user?.isSuperAdmin == true)
                    _DrawerItem(
                      icon: Icons.person_add_alt_outlined,
                      label: 'Provision Owner',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        ProvisionOwnerDialog.show(context);
                      },
                    ),
                ],
              ),
            ),

            // Bottom Settings and Logout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isActive: currentRoute == '/settings',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/settings') {
                        Navigator.pushNamed(context, '/settings');
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.logout,
                    label: 'Log Out',
                    textColor: Colors.redAccent,
                    iconColor: Colors.redAccent,
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final cart = context.read<CartProvider>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of HISAB-SYNC?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await auth.logout();
              await shop.clear();
              cart.clearCart();
              nav.pushNamedAndRemoveUntil('/login', (route) => false);
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF161B20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? textColor;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive ? AppColors.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? Colors.white
                      : (iconColor ?? const Color(0xFF475569)),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : (textColor ?? const Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
