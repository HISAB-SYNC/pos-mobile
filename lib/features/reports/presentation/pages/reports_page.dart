import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pos_pill_toggle.dart';
import '../../../auth/provider/auth_provider.dart';
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
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Sales Report'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Segment Toggle: Period Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Analytics & Performance',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PosPillToggle<String>(
                      values: const ['Weekly', 'Monthly'],
                      selectedValue: selectedPeriod,
                      labelBuilder: (v) => v,
                      isDense: true,
                      onSelected: (val) {
                        final auth = context.read<AuthProvider>();
                        final shop = context.read<ShopProvider>();
                        final shopId = shop.selectedShop?.id ?? 'default-shop';
                        reportsProvider.setPeriod(val, shopId: shopId, token: auth.token);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Four Soft-Tinted KPI Metric Tiles (Inspiration Grid)
                Row(
                  children: [
                    Expanded(
                      child: _buildSoftStatCard(
                        label: 'Net Sales',
                        value: '${overview.sales.toStringAsFixed(0)} ETB',
                        icon: Icons.attach_money_rounded,
                        accentColor: AppColors.successEmerald,
                        bgColor: AppColors.successBg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSoftStatCard(
                        label: 'Total Revenue',
                        value: '${overview.revenue.toStringAsFixed(0)} ETB',
                        icon: Icons.trending_up_rounded,
                        accentColor: AppColors.primaryBlue,
                        bgColor: AppColors.infoBg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSoftStatCard(
                        label: 'Net Profit',
                        value: '${overview.totalProfit.toStringAsFixed(0)} ETB',
                        icon: Icons.account_balance_wallet_rounded,
                        accentColor: const Color(0xFF7C3AED),
                        bgColor: const Color(0xFFF5F3FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSoftStatCard(
                        label: 'Margin Est.',
                        value: '35%',
                        icon: Icons.percent_rounded,
                        accentColor: AppColors.warningAmber,
                        bgColor: AppColors.warningBg,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. Interactive Chart Card
                _buildCard(
                  title: 'Revenue & Profit Trends',
                  child: ProfitRevenueChart(
                    points: chartData,
                    selectedIndex: reportsProvider.selectedPointIndex,
                    onPointSelected: (idx) => reportsProvider.selectPoint(idx),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Best Selling Category Card
                _buildCard(
                  title: 'Top Performing Categories',
                  headerAction: TextButton(
                    onPressed: () => _showAllCategoriesModal(context, categories),
                    child: const Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  child: Column(
                    children: [
                      // Subheader
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Category', style: _tableHeaderStyle)),
                            Expanded(flex: 2, child: Text('Turnover (ETB)', textAlign: TextAlign.center, style: _tableHeaderStyle)),
                            Expanded(flex: 2, child: Text('Growth', textAlign: TextAlign.end, style: _tableHeaderStyle)),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),

                      // Category items
                      ...categories.take(3).map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.category,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.turnover.toStringAsFixed(0),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textMedium, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '+${item.increasePercent.toStringAsFixed(1)}%',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.successEmerald),
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

                // 4. Best Selling Products Card
                _buildCard(
                  title: 'Best Selling Products',
                  headerAction: TextButton(
                    onPressed: () => _showAllProductsModal(context, products),
                    child: const Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Product', style: _tableHeaderStyle)),
                            Expanded(flex: 2, child: Text('Category', style: _tableHeaderStyle)),
                            Expanded(flex: 2, child: Text('Stock', textAlign: TextAlign.center, style: _tableHeaderStyle)),
                            Expanded(flex: 2, child: Text('Turnover', textAlign: TextAlign.end, style: _tableHeaderStyle)),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      ...products.take(4).map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'ID: ${item.productId}',
                                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.category,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.remainingQuantity,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      item.turnover.toStringAsFixed(0),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                    ),
                                    Text(
                                      '+${item.increasePercent}%',
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.successEmerald),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoftStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.softCardDecoration(
        backgroundColor: bgColor,
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
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

  static const TextStyle _tableHeaderStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
  );

  void _showAllCategoriesModal(BuildContext context, List<BestSellingCategoryItem> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('All Categories', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                      itemBuilder: (context, index) {
                        final item = categories[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text('Growth: +${item.increasePercent}%', style: const TextStyle(color: AppColors.successEmerald, fontSize: 12)),
                          trailing: Text('${item.turnover.toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAllProductsModal(BuildContext context, List<BestSellingProductItem> products) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('All Best Selling Products', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                      itemBuilder: (context, index) {
                        final item = products[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text('${item.category} • Stock: ${item.remainingQuantity}', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                          trailing: Text('${item.turnover.toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
