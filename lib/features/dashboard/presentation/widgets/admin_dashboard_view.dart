import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/animated_count_text.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../orders/provider/orders_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../provider/dashboard_provider.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  String? _lastLoadedShopId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final shopId = shop.selectedShop?.id ?? '';
    _lastLoadedShopId = shopId;
    final token = auth.token;

    if (shopId.isNotEmpty && token != null) {
      context.read<DashboardProvider>().loadDashboardMetrics(
            shopId: shopId,
            token: token,
            isSalesRole: false,
          );
      context.read<ProductProvider>().loadProducts(shopId: shopId, token: token);
      context.read<OrdersProvider>().loadOrders(shopId: shopId, token: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentShopId = context.watch<ShopProvider>().selectedShop?.id;
    if (currentShopId != null && currentShopId.isNotEmpty && (_lastLoadedShopId == null || _lastLoadedShopId != currentShopId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDashboardData();
      });
    }

    final dashboardProvider = context.watch<DashboardProvider>();
    final productProvider = context.watch<ProductProvider>();
    final ordersProvider = context.watch<OrdersProvider>();

    final metrics = dashboardProvider.metrics;
    final orders = ordersProvider.orders;
    final inHandStock = productProvider.products.fold<int>(0, (sum, p) => sum + p.stockQuantity);
    final lowStockProducts = productProvider.products.where((p) => p.isLowStock).toList();

    // Fail-safe calculation: compute totals from real orders in the shop
    final ordersRevenue = orders.fold<double>(0.0, (sum, o) => sum + o.price);
    final ordersCount = orders.length;

    // If today's sales from server are positive, use them; otherwise fall back to store transactions
    final revenue = metrics.todaysSales.totalAmount > 0
        ? metrics.todaysSales.totalAmount
        : (ordersRevenue > 0 ? ordersRevenue : 0.0);
    final salesCount = metrics.todaysSales.count > 0
        ? metrics.todaysSales.count
        : (ordersCount > 0 ? ordersCount : 0);

    return RefreshIndicator(
      onRefresh: () async => _loadDashboardData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Low Stock Warning Banner if any items low
            if (lowStockProducts.isNotEmpty) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/products');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: AppDecorations.softCardDecoration(
                      backgroundColor: AppColors.warningBg,
                      borderColor: const Color(0xFFFDE68A),
                      borderRadius: 16,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${lowStockProducts.length} item(s) are running low on stock',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.warningAmber, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Section 1: KPI Tiles (Soft Tinted Grid)
            Row(
              children: [
                Expanded(
                  child: _buildSoftMetricCard(
                    title: "Today's Sales",
                    numericValue: revenue,
                    suffix: ' ETB',
                    subtitle: '$salesCount transactions',
                    icon: Icons.trending_up_rounded,
                    accentColor: AppColors.brandLimeDeep,
                    bgColor: AppColors.brandLimeBg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSoftMetricCard(
                    title: 'Total In-Stock',
                    numericValue: inHandStock.toDouble(),
                    suffix: ' units',
                    subtitle: '${productProvider.products.length} products',
                    icon: Icons.inventory_2_rounded,
                    accentColor: AppColors.successEmerald,
                    bgColor: AppColors.successBg,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section 2: Quick Action Shortcuts
            const Text(
              'OPERATIONS SHORTCUTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.point_of_sale_rounded,
                    label: 'POS Sale',
                    color: AppColors.brandLimeDeep,
                    onTap: () => Navigator.pushNamed(context, '/catalog'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.add_box_rounded,
                    label: 'Add Product',
                    color: AppColors.successEmerald,
                    onTap: () => Navigator.pushNamed(context, '/products'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Expenses',
                    color: AppColors.errorRose,
                    onTap: () => Navigator.pushNamed(context, '/expenses'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.groups_rounded,
                    label: 'Staff Team',
                    color: const Color(0xFF7C3AED),
                    onTap: () => Navigator.pushNamed(context, '/staff'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Section 3: Recent Activity Snapshot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT TRANSACTIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/orders');
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (orders.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: AppDecorations.outlineCardDecoration,
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 36, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text(
                        'No recent transactions yet',
                        style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: AppDecorations.cardDecoration,
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length.clamp(0, 4),
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderLight.withOpacity(0.6),
                  ),
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 18,
                              color: AppColors.slateDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Order #${o.orderId} • Qty: ${o.quantity}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${o.price.toStringAsFixed(0)} ETB',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoftMetricCard({
    required String title,
    required double numericValue,
    required String suffix,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.softCardDecoration(
        backgroundColor: bgColor,
        borderRadius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedCountText(
            value: numericValue,
            suffix: suffix,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
