import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../customer/provider/customer_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../../settings/models/app_notification.dart';
import '../../../settings/provider/settings_provider.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationsSheet(),
    );
  }

  static List<AppNotification> getActiveNotifications(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    final settings = settingsProvider.settings;
    final productProvider = context.read<ProductProvider>();
    final customerProvider = context.read<CustomerProvider>();

    final list = <AppNotification>[];

    // 1. Low Stock Alerts
    if (settings.lowStockAlert) {
      final lowStockProducts = productProvider.allProducts.where(
        (p) => p.stockQuantity <= settings.stockThreshold,
      ).toList();

      for (final p in lowStockProducts) {
        list.add(
          AppNotification(
            id: 'low-stock-${p.id}',
            title: 'Low Stock Alert',
            message: '${p.name} has only ${p.stockQuantity} units left (Threshold: ${settings.stockThreshold})',
            type: NotificationType.lowStock,
            timestamp: DateTime.now(),
            route: '/products',
          ),
        );
      }
    }

    // 2. Debt Due Alerts
    if (settings.debtDueAlert) {
      final debtCustomers = customerProvider.customers.where(
        (c) => c.totalDebt > 0,
      ).toList();

      for (final c in debtCustomers) {
        list.add(
          AppNotification(
            id: 'debt-due-${c.id}',
            title: 'Debt Due Alert',
            message: '${c.name} has an outstanding debt of ${c.totalDebt.toStringAsFixed(2)} ETB',
            type: NotificationType.debtDue,
            timestamp: DateTime.now(),
            route: '/customers',
          ),
        );
      }
    }

    // 3. Product Expiry Alert
    if (settings.productExpireAlert) {
      final now = DateTime.now();
      final expiringProducts = productProvider.allProducts.where((p) {
        if (p.expiryDate == null || p.expiryDate!.isEmpty) return false;
        try {
          final exp = DateTime.tryParse(p.expiryDate!);
          if (exp != null) {
            final diff = exp.difference(now).inDays;
            return diff >= 0 && diff <= settings.expireAlertDays;
          }
        } catch (_) {}
        return false;
      }).toList();

      for (final p in expiringProducts) {
        list.add(
          AppNotification(
            id: 'expire-${p.id}',
            title: 'Product Expiring Soon',
            message: '${p.name} is expiring soon (${p.expiryDate})',
            type: NotificationType.productExpire,
            timestamp: DateTime.now(),
            route: '/products',
          ),
        );
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = getActiveNotifications(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Color(0xFF161B20), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Notifications (${notifications.length})',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF161B20),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content List
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_none,
                                size: 32,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No Active Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF161B20),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Turn on alert options in Settings to receive low stock, debt, and product expiry updates.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(context, '/settings');
                              },
                              icon: const Icon(Icons.settings_outlined, size: 16),
                              label: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF161B20),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        return _buildNotificationCard(context, n);
                      },
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                    icon: const Icon(Icons.tune, size: 16, color: Color(0xFF64748B)),
                    label: const Text('Configure Alerts', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF161B20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification n) {
    Color badgeColor;
    Color iconColor;
    IconData icon;

    switch (n.type) {
      case NotificationType.lowStock:
        badgeColor = const Color(0xFFFEF2F2);
        iconColor = const Color(0xFFEF4444);
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationType.debtDue:
        badgeColor = const Color(0xFFEFF6FF);
        iconColor = const Color(0xFF2563EB);
        icon = Icons.account_balance_wallet_outlined;
        break;
      case NotificationType.productExpire:
        badgeColor = const Color(0xFFFFFBEB);
        iconColor = const Color(0xFFD97706);
        icon = Icons.hourglass_bottom_outlined;
        break;
      case NotificationType.general:
        badgeColor = const Color(0xFFF1F5F9);
        iconColor = const Color(0xFF64748B);
        icon = Icons.info_outline;
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (n.route != null) {
          Navigator.pushNamed(context, n.route!);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        n.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF161B20),
                        ),
                      ),
                      const Text(
                        'Just now',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
