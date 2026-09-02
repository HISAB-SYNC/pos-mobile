import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/navigation/more_features_sheet.dart';
import '../../../../core/navigation/store_switcher_sheet.dart';
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
  Size get preferredSize => const Size.fromHeight(66);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shopProvider = context.watch<ShopProvider>();
    final user = auth.currentUser;
    final selectedShop = shopProvider.selectedShop;

    final isOwner = user?.isOwner == true;
    final isAdmin = user?.isAdmin == true;

    final roleLabel = isOwner
        ? 'OWNER'
        : isAdmin
            ? 'MANAGER'
            : 'CASHIER';

    final roleColor = isOwner
        ? const Color(0xFF4F46E5)
        : isAdmin
            ? const Color(0xFF2563EB)
            : const Color(0xFF059669);

    final roleBg = isOwner
        ? const Color(0xFFEEF2FF)
        : isAdmin
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFECFDF5);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Greeting + Name + Role Pill Badge
          Row(
            children: [
              Flexible(
                child: Text(
                  '${_getGreeting()}, ${user?.name.split(' ').first ?? 'User'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: roleColor.withOpacity(0.2)),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: roleColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Row 2: Active Shop Pill Trigger
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (isOwner && shopProvider.shops.length > 1) {
                StoreSwitcherSheet.show(context);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_rounded,
                  size: 13,
                  color: isOwner ? AppColors.primaryBlue : AppColors.textMedium,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    selectedShop?.name ?? (isOwner ? 'Select Active Shop' : 'Andalus POS'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOwner ? AppColors.primaryBlue : AppColors.textMedium,
                    ),
                  ),
                ),
                if (isOwner && shopProvider.shops.length > 1) ...[
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 15,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.slateDark,
              size: 22,
            ),
            tooltip: 'Search Inventory',
            onPressed: () {
              HapticFeedback.lightImpact();
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
                    Icons.notifications_none_rounded,
                    color: AppColors.slateDark,
                    size: 22,
                  ),
                  tooltip: 'Notifications',
                  onPressed: () {
                    HapticFeedback.lightImpact();
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
                        color: AppColors.errorRose,
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
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              MoreFeaturesSheet.show(context);
            },
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.slateDark,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
