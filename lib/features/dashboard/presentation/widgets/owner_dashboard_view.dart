import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../category/provider/category_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../../supplier/provider/supplier_provider.dart';
import '../../provider/dashboard_provider.dart';

class OwnerDashboardView extends StatefulWidget {
  const OwnerDashboardView({super.key});

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  String _selectedChartPeriod = 'Weekly';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final supplierProvider = context.watch<SupplierProvider>();

    final metrics = dashboardProvider.metrics;
    final totalProducts = productProvider.products.length;
    final totalCategories = categoryProvider.categories.length;
    final totalSuppliers = supplierProvider.suppliers.length;

    // Calculate in-hand stock quantity
    final inHandStock = productProvider.products.fold<int>(
      0,
      (sum, p) => sum + p.stockQuantity,
    );

    final revenue = metrics.todaysSales.totalAmount;
    final estimatedCost = revenue * 0.65;
    final estimatedProfit = revenue - estimatedCost;

    return RefreshIndicator(
      onRefresh: () async => _loadDashboardData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Sales Overview Card (ALWAYS VISIBLE - NEVER REMOVED)
            _buildSectionCard(
              title: 'Sales Overview',
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.percent,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF3B82F6),
                      value: '${metrics.todaysSales.count}',
                      label: 'Sales',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.trending_up,
                      iconBg: const Color(0xFFF5F3FF),
                      iconColor: const Color(0xFF8B5CF6),
                      value: revenue > 0 ? revenue.toStringAsFixed(0) : '0',
                      label: 'Revenue (ETB)',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.bar_chart,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      value: estimatedProfit > 0 ? estimatedProfit.toStringAsFixed(0) : '0',
                      label: 'Profit (ETB)',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.storefront_outlined,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF10B981),
                      value: estimatedCost > 0 ? estimatedCost.toStringAsFixed(0) : '0',
                      label: 'Cost (ETB)',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Inventory Summary Card (ALWAYS VISIBLE - NEVER REMOVED)
            _buildSectionCard(
              title: 'Inventory Summary',
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.inventory_2_outlined,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      value: inHandStock > 0 ? '$inHandStock' : '$totalProducts',
                      label: 'Quantity in Hand',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.move_to_inbox_outlined,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF3B82F6),
                      value: '0',
                      label: 'To be received',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.warning_amber_rounded,
                      iconBg: const Color(0xFFFEF2F2),
                      iconColor: const Color(0xFFDC2626),
                      value: '${metrics.lowStockCount}',
                      label: 'Low Stock Items',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Purchase Overview Card (ALWAYS VISIBLE - NEVER REMOVED)
            _buildSectionCard(
              title: 'Purchase Overview',
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.shopping_bag_outlined,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      value: '0',
                      label: 'Purchase',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.monetization_on_outlined,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF10B981),
                      value: '0',
                      label: 'Cost (ETB)',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.cancel_outlined,
                      iconBg: const Color(0xFFFDF2F8),
                      iconColor: const Color(0xFFDB2777),
                      value: '0',
                      label: 'Cancel',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.assignment_return_outlined,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      value: '0',
                      label: 'Return',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4. Product & Supplier Summary Card (ALWAYS VISIBLE - NEVER REMOVED)
            _buildSectionCard(
              title: 'Product & Staff Summary',
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.local_shipping_outlined,
                      iconBg: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      value: '$totalSuppliers',
                      label: 'Suppliers',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.category_outlined,
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF9333EA),
                      value: '$totalCategories',
                      label: 'Categories',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.inventory_2_outlined,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF10B981),
                      value: '$totalProducts',
                      label: 'Total Products',
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.people_outline,
                      iconBg: const Color(0xFFFEF2F2),
                      iconColor: const Color(0xFFDC2626),
                      value: '${metrics.outstandingDebts.count}',
                      label: 'Debtors',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 5. Low Stock Alert Card (ALWAYS VISIBLE - NEVER REMOVED)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: metrics.lowStockCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: metrics.lowStockCount > 0 ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    metrics.lowStockCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: metrics.lowStockCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metrics.lowStockCount > 0 ? 'Low Stock Alert' : 'Inventory Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: metrics.lowStockCount > 0 ? const Color(0xFF991B1B) : const Color(0xFF166534),
                          ),
                        ),
                        Text(
                          metrics.lowStockCount > 0
                              ? '${metrics.lowStockCount} items have reached or fallen below minimum thresholds.'
                              : '0 low stock items. All inventory levels are healthy.',
                          style: TextStyle(
                            fontSize: 11,
                            color: metrics.lowStockCount > 0 ? const Color(0xFF7F1D1D) : const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/products'),
                    child: Text(
                      'View',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: metrics.lowStockCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 6. Sales & Activity Chart Card (ALWAYS VISIBLE - NEVER REMOVED)
            _buildSectionCard(
              title: 'Sales & Activity',
              headerAction: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _chartPeriodButton('Weekly'),
                    _chartPeriodButton('Monthly'),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _chartBar('Mon', 0.45, '0'),
                        _chartBar('Tue', 0.65, '0'),
                        _chartBar('Wed', 0.30, '0'),
                        _chartBar('Thu', 0.85, '0'),
                        _chartBar('Fri', 0.70, '0'),
                        _chartBar('Sat', 0.95, revenue > 0 ? '${(revenue / 1000).toStringAsFixed(1)}k' : '0'),
                        _chartBar('Sun', 0.50, '0'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartPeriodButton(String period) {
    final isSelected = _selectedChartPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF161B20) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _chartBar(String label, double fillPercent, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 110 * fillPercent,
          decoration: BoxDecoration(
            color: const Color(0xFF161B20),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    Widget? headerAction,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF161B20),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
