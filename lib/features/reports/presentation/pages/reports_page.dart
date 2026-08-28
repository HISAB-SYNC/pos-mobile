import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';
import '../../../dashboard/presentation/widgets/app_header.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/report_models.dart';
import '../../provider/reports_provider.dart';
import '../widgets/profit_revenue_chart.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final shopId = shop.selectedShop?.id ?? 'default-shop';
    final token = auth.token;
    context.read<ReportsProvider>().loadReports(shopId: shopId, token: token);
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();
    final overview = reportsProvider.overview;
    final categories = reportsProvider.categories;
    final chartData = reportsProvider.chartData;
    final products = reportsProvider.products;
    final selectedPeriod = reportsProvider.selectedPeriod;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Reports'),
      drawer: const AppDrawer(currentRoute: '/reports'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page Title Header
                const Text(
                  'Reports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF161B20),
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Overview (ETB) Card
                _buildCard(
                  title: 'Overview (ETB)',
                  child: Row(
                    children: [
                      Expanded(
                        child: _overviewMetric(
                          'Total Profit',
                          overview.totalProfit.toStringAsFixed(0),
                          const Color(0xFF161B20),
                          const Color(0xFF64748B),
                        ),
                      ),
                      Container(height: 36, width: 1, color: const Color(0xFFE2E8F0)),
                      Expanded(
                        child: _overviewMetric(
                          'Revenue',
                          overview.revenue.toStringAsFixed(0),
                          const Color(0xFFD97706),
                          const Color(0xFFD97706),
                        ),
                      ),
                      Container(height: 36, width: 1, color: const Color(0xFFE2E8F0)),
                      Expanded(
                        child: _overviewMetric(
                          'Sales',
                          overview.sales.toStringAsFixed(0),
                          const Color(0xFF8B5CF6),
                          const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Best Selling Category Card
                _buildCard(
                  title: 'Best selling category',
                  headerAction: TextButton(
                    onPressed: () {
                      _showAllCategoriesModal(context, categories);
                    },
                    child: const Text('See All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                  ),
                  child: Column(
                    children: [
                      // Subheader
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Category', style: _tableHeaderStyle)),
                            Expanded(flex: 2, child: Text('Turn Over(ETB)', textAlign: TextAlign.center, style: _tableHeaderStyle)),
                            Expanded(flex: 2, child: Text('Increase By', textAlign: TextAlign.end, style: _tableHeaderStyle)),
                          ],
                        ),
                      ),
                      const Divider(height: 8),

                      // Category items
                      ...categories.take(3).map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.category,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF161B20)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${item.turnover.toStringAsFixed(0)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '+${item.increasePercent.toStringAsFixed(1)}%',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Profit & Revenue Chart Card
                _buildCard(
                  title: 'Profit & Revenue',
                  headerAction: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPeriod,
                        isDense: true,
                        icon: const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        items: const [
                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly ')),
                          DropdownMenuItem(value: 'Weekly', child: Text('Weekly ')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            final auth = context.read<AuthProvider>();
                            final shop = context.read<ShopProvider>();
                            final shopId = shop.selectedShop?.id ?? 'default-shop';
                            reportsProvider.setPeriod(val, shopId: shopId, token: auth.token);
                          }
                        },
                      ),
                    ),
                  ),
                  child: ProfitRevenueChart(
                    points: chartData,
                    selectedIndex: reportsProvider.selectedPointIndex,
                    onPointSelected: (idx) => reportsProvider.selectPoint(idx),
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Best Selling Product Card
                _buildCard(
                  title: 'Best selling product',
                  headerAction: TextButton(
                    onPressed: () {
                      _showAllProductsModal(context, products);
                    },
                    child: const Text('See All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                  ),
                  child: Column(
                    children: [
                      // Subheader
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Product / ID', style: _tableHeaderStyle)),
                            Expanded(flex: 2, child: Text('Category', style: _tableHeaderStyle)),
                            Expanded(flex: 2, child: Text('Stock', textAlign: TextAlign.center, style: _tableHeaderStyle)),
                            Expanded(flex: 2, child: Text('Turn Over', textAlign: TextAlign.end, style: _tableHeaderStyle)),
                          ],
                        ),
                      ),
                      const Divider(height: 8),

                      // Product rows
                      ...products.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'ID: ${item.productId}',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.category,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.remainingQuantity,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.turnover.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                                    ),
                                    Text(
                                      '+${item.increasePercent}%',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
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
            color: Color(0x06000000),
            blurRadius: 6,
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
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _overviewMetric(String label, String value, Color valueColor, Color labelColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: labelColor),
        ),
      ],
    );
  }

  void _showAllCategoriesModal(BuildContext context, List<BestSellingCategoryItem> list) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Best Selling Categories',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            ...list.map((c) => ListTile(
                  title: Text(c.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    '${c.turnover.toStringAsFixed(0)} ETB  (+${c.increasePercent}%)',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showAllProductsModal(BuildContext context, List<BestSellingProductItem> list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Performing Products',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final p = list[i];
                  return ListTile(
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${p.category} • ID: ${p.productId} • Stock: ${p.remainingQuantity}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${p.turnover.toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('+${p.increasePercent}%', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700, fontSize: 11)),
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
}

const TextStyle _tableHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: Color(0xFF94A3B8),
);
