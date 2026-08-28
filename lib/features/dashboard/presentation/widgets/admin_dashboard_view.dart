import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../category/provider/category_provider.dart';
import '../../../orders/provider/orders_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../../supplier/provider/supplier_provider.dart';
import '../../provider/dashboard_provider.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
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
    final token = auth.token;
    final user = auth.currentUser;

    if (shopId.isNotEmpty && token != null) {
      context.read<DashboardProvider>().loadDashboardMetrics(
            shopId: shopId,
            token: token,
            isSalesRole: user?.isSales == true,
          );
      context.read<ProductProvider>().loadProducts(shopId: shopId, token: token);
      context.read<CategoryProvider>().loadCategories(shopId: shopId, token: token);
      context.read<SupplierProvider>().loadSuppliers(shopId: shopId, token: token);
      context.read<OrdersProvider>().loadOrders(shopId: shopId, token: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final supplierProvider = context.watch<SupplierProvider>();
    final ordersProvider = context.watch<OrdersProvider>();

    final metrics = dashboardProvider.metrics;
    final inHandStock = productProvider.products.fold<int>(0, (sum, p) => sum + p.stockQuantity);
    final lowStockProducts = productProvider.products.where((p) => p.isLowStock).toList();
    final topProducts = productProvider.products.take(3).toList();

    return RefreshIndicator(
      onRefresh: () async => _loadDashboardData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Operational KPIs (ALWAYS VISIBLE - NEVER REMOVED)
            const Text(
              'Operational KPIs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF161B20),
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildKpiCard(
                  'Daily Sales',
                  '${metrics.todaysSales.count} (${metrics.todaysSales.totalAmount.toStringAsFixed(0)} ETB)',
                  Icons.trending_up,
                  const Color(0xFF3B82F6),
                ),
                _buildKpiCard(
                  'In-Hand Stock',
                  inHandStock > 0 ? '$inHandStock' : '${productProvider.products.length}',
                  Icons.inventory_2_outlined,
                  const Color(0xFF10B981),
                ),
                _buildKpiCard(
                  'Categories',
                  '${categoryProvider.categories.length}',
                  Icons.category_outlined,
                  const Color(0xFF8B5CF6),
                ),
                _buildKpiCard(
                  'Suppliers',
                  '${supplierProvider.suppliers.length}',
                  Icons.people_outline,
                  const Color(0xFFF59E0B),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 2. Quick Actions (ALWAYS VISIBLE - NEVER REMOVED)
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF161B20),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.add_circle_outline,
                    label: '+ Add Product',
                    onTap: () => Navigator.pushNamed(context, '/products'),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    icon: Icons.category_outlined,
                    label: 'Categories',
                    onTap: () => Navigator.pushNamed(context, '/categories'),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    icon: Icons.people_outline,
                    label: 'Customers',
                    onTap: () => Navigator.pushNamed(context, '/customers'),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Log Expense',
                    onTap: () => Navigator.pushNamed(context, '/expenses'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 3. Order Status Card (ALWAYS VISIBLE - NEVER REMOVED)
            _buildCard(
              title: 'Order Status',
              child: Row(
                children: [
                  Expanded(
                    child: _orderStatusItem(
                      'Pending',
                      '${ordersProvider.orders.where((o) => o.status.toLowerCase() == 'pending').length}',
                      const Color(0xFFEF4444),
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: _orderStatusItem(
                      'Processing',
                      '${ordersProvider.orders.where((o) => o.status.toLowerCase() == 'processing').length}',
                      const Color(0xFFF59E0B),
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: _orderStatusItem(
                      'Completed',
                      '${ordersProvider.orders.where((o) => o.status.toLowerCase() == 'completed').length}',
                      const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. Urgent Low Stock (ALWAYS VISIBLE - NEVER REMOVED)
            _buildCard(
              title: 'Urgent Low Stock',
              headerAction: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/products'),
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
              child: lowStockProducts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          '0 low stock alerts. All inventory is healthy!',
                          style: TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  : Column(
                      children: lowStockProducts.take(3).map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.inventory_2_outlined, color: Colors.redAccent, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF161B20)),
                                    ),
                                    Text(
                                      '${p.stockQuantity} remaining (Threshold: ${p.lowStockThreshold})',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${p.price.toStringAsFixed(0)} ETB',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 18),

            // 5. Top Moving Stock (ALWAYS VISIBLE - NEVER REMOVED)
            _buildCard(
              title: 'Top Moving Stock',
              child: topProducts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text('0 products in inventory', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ),
                    )
                  : Column(
                      children: topProducts.map((p) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF161B20)),
                                  ),
                                  Text(
                                    '${p.stockQuantity} units in stock',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              Text(
                                '${p.price.toStringAsFixed(0)} ETB',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF161B20),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: AppColors.navy),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    Widget? headerAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF161B20),
                ),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _orderStatusItem(String status, String count, Color color) {
    return Column(
      children: [
        Text(
          status,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
