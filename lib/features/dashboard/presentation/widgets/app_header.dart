import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../customer/provider/customer_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../../settings/provider/settings_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import 'notifications_sheet.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;

  const AppHeader({
    super.key,
    this.title = 'Dashboard',
    this.showSearch = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shopProvider = context.watch<ShopProvider>();
    final user = auth.currentUser;
    final selectedShop = shopProvider.selectedShop;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.menu,
          color: Color(0xFF161B20),
          size: 26,
        ),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  selectedShop?.name ?? (user?.isOwner == true ? 'Select Shop' : 'Andalus POS'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF161B20),
                  ),
                ),
              ),
              if (user?.isOwner == true && shopProvider.shops.length > 1) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ],
            ],
          ),
          if (user != null)
            Text(
              user.role,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: user.isOwner
                    ? AppColors.navy
                    : user.isAdmin
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF059669),
                letterSpacing: 0.4,
              ),
            ),
        ],
      ),
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Color(0xFF161B20),
              size: 22,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/products');
            },
          ),
        Builder(
          builder: (context) {
            context.watch<SettingsProvider>();
            context.watch<ProductProvider>();
            context.watch<CustomerProvider>();
            final activeNotifications = NotificationsSheet.getActiveNotifications(context);
            final count = activeNotifications.length;

            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF161B20),
                    size: 22,
                  ),
                  onPressed: () {
                    NotificationsSheet.show(context);
                  },
                ),
                if (count > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
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
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 4),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 40),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.navy,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _confirmHeaderLogout(context);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF161B20),
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmHeaderLogout(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();

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
              nav.pushNamedAndRemoveUntil('/', (route) => false);
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF161B20), // Black button
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
