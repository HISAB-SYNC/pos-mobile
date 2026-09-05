import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/skeleton_loaders.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../dashboard/presentation/widgets/app_header.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/analytics_models.dart';
import '../../provider/reports_provider.dart';
import '../../../orders/provider/orders_provider.dart';
import '../widgets/profit_revenue_chart.dart';
import '../../../../core/services/report_pdf_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String? _lastLoadedShopId;

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
    final shopId = shop.selectedShop?.id ?? '';
    _lastLoadedShopId = shopId;
    final token = auth.token;

    if (auth.currentUser?.isSales == true) {
      if (shopId.isNotEmpty && token != null) {
        context.read<OrdersProvider>().loadOrders(shopId: shopId, token: token);
      }
      return;
    }

    if (shopId.isNotEmpty) {
      context.read<ReportsProvider>().loadReports(shopId: shopId, token: token);
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 14)),
      end: now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.slateDark,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final auth = context.read<AuthProvider>();
      final shop = context.read<ShopProvider>();
      final shopId = shop.selectedShop?.id ?? '';
      context.read<ReportsProvider>().setPeriod(
            'custom',
            shopId: shopId,
            token: auth.token,
            startDate: picked.start,
            endDate: picked.end,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.currentUser?.isSales == true) {
      return _buildSalesShiftSummary(context);
    }

    final currentShopId = context.watch<ShopProvider>().selectedShop?.id;
    if (_lastLoadedShopId != null && _lastLoadedShopId != currentShopId && currentShopId != null && currentShopId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }

    final reportsProvider = context.watch<ReportsProvider>();
    final analytics = reportsProvider.analytics;
    final sales = reportsProvider.salesAnalytics;
    final products = reportsProvider.productAnalytics;
    final customers = reportsProvider.customerAnalytics;
    final chartData = reportsProvider.chartData;
    final selectedPeriod = reportsProvider.selectedPeriod;
    final isLoading = reportsProvider.isLoading;
    final shop = context.watch<ShopProvider>().selectedShop;
    final currency = shop?.currency ?? 'ETB';

    // Computed totals for stats
    final totalRevenue = sales?.totalRevenue ?? reportsProvider.overview.revenue;
    final totalSalesCount = sales?.totalSalesCount ?? reportsProvider.overview.sales.toInt();
    final avgOrderValue = sales?.averageOrderValue ?? (totalSalesCount > 0 ? totalRevenue / totalSalesCount : 0.0);
    final debtAmount = customers?.outstandingDebt.totalAmount ?? 0.0;
    final debtCount = customers?.outstandingDebt.count ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Sales & Analytics'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row & Period Toggle Controls
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Performance Analytics',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (selectedPeriod == 'custom' && reportsProvider.customStartDate != null)
                            Text(
                              '${_formatShortDate(reportsProvider.customStartDate!)} - ${_formatShortDate(reportsProvider.customEndDate ?? DateTime.now())}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Period Selector Horizontal Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            _buildPeriodTab('daily', 'Daily', selectedPeriod),
                            _buildPeriodTab('weekly', 'Weekly', selectedPeriod),
                            _buildPeriodTab('monthly', 'Monthly', selectedPeriod),
                            _buildCustomPeriodButton(selectedPeriod),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Download / Export Report Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedPeriod.toUpperCase()} SUMMARY',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.5),
                    ),
                    InkWell(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final shop = context.read<ShopProvider>().selectedShop;
                        await ReportPdfService.generateAndDownloadReport(
                          shop: shop,
                          period: selectedPeriod,
                          salesAnalytics: sales,
                          productAnalytics: products,
                          customerAnalytics: customers,
                          currency: currency,
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.brandLimeBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.brandLimeBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.brandLimeDeep),
                            const SizedBox(width: 6),
                            Text(
                              'Download ${selectedPeriod.toUpperCase()} Report',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandLimeDeep),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (isLoading && analytics == null)
                  const Column(
                    children: [
                      ListRowSkeleton(),
                      SizedBox(height: 12),
                      ListRowSkeleton(),
                      SizedBox(height: 12),
                      ListRowSkeleton(),
                    ],
                  )
                else ...[
                  // 1. Four Soft-Tinted KPI Metric Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildSoftStatCard(
                          label: 'Total Revenue',
                          value: '${totalRevenue.toStringAsFixed(0)} ETB',
                          icon: Icons.payments_outlined,
                          accentColor: AppColors.brandLimeDeep,
                          bgColor: AppColors.brandLimeBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSoftStatCard(
                          label: 'Sales Count',
                          value: '$totalSalesCount Orders',
                          icon: Icons.receipt_long_outlined,
                          accentColor: AppColors.successEmerald,
                          bgColor: AppColors.successBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSoftStatCard(
                          label: 'Avg Order Value',
                          value: '${avgOrderValue.toStringAsFixed(0)} ETB',
                          icon: Icons.shopping_bag_outlined,
                          accentColor: const Color(0xFF7C3AED),
                          bgColor: const Color(0xFFF5F3FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSoftStatCard(
                          label: 'Outstanding Debt',
                          value: '${debtAmount.toStringAsFixed(0)} ETB',
                          subtitle: '$debtCount open debts',
                          icon: Icons.warning_amber_rounded,
                          accentColor: debtAmount > 0 ? AppColors.warningAmber : AppColors.textMuted,
                          bgColor: debtAmount > 0 ? AppColors.warningBg : AppColors.inputBackground,
                        ),
                      ),
                    ],
                  ),

                  // Discount Sub-banner
                  if (sales != null && sales.totalDiscountsGiven > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_offer_outlined, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Discounts Given: ${sales.totalDiscountsGiven.toStringAsFixed(0)} ETB',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 2. Interactive Revenue & Sales Trend Chart
                  _buildCard(
                    title: 'Revenue & Sales Trend',
                    subtitle: 'Chronological sales progression for selected period',
                    child: ProfitRevenueChart(
                      points: chartData,
                      selectedIndex: reportsProvider.selectedPointIndex,
                      onPointSelected: (idx) => reportsProvider.selectPoint(idx),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Payment Method Distribution Breakdown
                  if (sales != null) ...[
                    _buildPaymentMethodCard(sales.paymentMethodBreakdown),
                    const SizedBox(height: 20),
                  ],

                  // 4. Top Selling Products Leaderboard
                  _buildTopProductsCard(products?.topSellingProducts ?? []),

                  const SizedBox(height: 20),

                  // 5. Customer Insights & Top Spenders Leaderboard
                  if (customers != null) ...[
                    _buildCustomerAnalyticsCard(customers),
                    const SizedBox(height: 20),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String key, String label, String selectedPeriod) {
    final isSelected = selectedPeriod.toLowerCase() == key;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        final auth = context.read<AuthProvider>();
        final shop = context.read<ShopProvider>();
        final shopId = shop.selectedShop?.id ?? '';
        context.read<ReportsProvider>().setPeriod(key, shopId: shopId, token: auth.token);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.slateDark : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPeriodButton(String selectedPeriod) {
    final isSelected = selectedPeriod.toLowerCase() == 'custom';
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _pickCustomDateRange();
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.slateDark : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range_rounded, size: 14, color: isSelected ? Colors.white : AppColors.textMedium),
            const SizedBox(width: 4),
            Text(
              'Custom',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoftStatCard({
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.slateDark),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodBreakdown pmb) {
    final grandTotal = pmb.grandTotal > 0 ? pmb.grandTotal : 1.0;
    final cashPct = ((pmb.cash.totalAmount / grandTotal) * 100).clamp(0.0, 100.0);
    final cardPct = ((pmb.card.totalAmount / grandTotal) * 100).clamp(0.0, 100.0);
    final mobilePct = ((pmb.mobile.totalAmount / grandTotal) * 100).clamp(0.0, 100.0);

    return _buildCard(
      title: 'Payment Methods Breakdown',
      subtitle: 'Revenue split across tender types',
      child: Column(
        children: [
          // Visual Multi-segment Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (cashPct > 0)
                    Expanded(flex: cashPct.toInt().clamp(1, 100), child: Container(color: AppColors.successEmerald)),
                  if (cardPct > 0)
                    Expanded(flex: cardPct.toInt().clamp(1, 100), child: Container(color: AppColors.primaryBlue)),
                  if (mobilePct > 0)
                    Expanded(flex: mobilePct.toInt().clamp(1, 100), child: Container(color: const Color(0xFF7C3AED))),
                  if (pmb.grandTotal <= 0)
                    Expanded(child: Container(color: AppColors.borderMedium)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3 Method Rows
          _paymentRow(
            icon: Icons.payments_rounded,
            label: 'Cash Tender',
            amount: pmb.cash.totalAmount,
            count: pmb.cash.count,
            percent: cashPct,
            color: AppColors.successEmerald,
          ),
          const Divider(height: 16, color: AppColors.borderLight),
          _paymentRow(
            icon: Icons.credit_card_rounded,
            label: 'Card Payments',
            amount: pmb.card.totalAmount,
            count: pmb.card.count,
            percent: cardPct,
            color: AppColors.primaryBlue,
          ),
          const Divider(height: 16, color: AppColors.borderLight),
          _paymentRow(
            icon: Icons.phone_android_rounded,
            label: 'TeleBirr',
            amount: pmb.mobile.totalAmount,
            count: pmb.mobile.count,
            percent: mobilePct,
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow({
    required IconData icon,
    required String label,
    required double amount,
    required int count,
    required double percent,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              Text(
                '$count transactions • ${percent.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} ETB',
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.slateDark),
        ),
      ],
    );
  }

  Widget _buildTopProductsCard(List<TopSellingProduct> topProducts) {
    return _buildCard(
      title: 'Top Selling Products',
      subtitle: 'Highest volume & revenue generating inventory',
      child: topProducts.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No product sales recorded in this period', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            )
          : Column(
              children: [
                ...topProducts.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final p = entry.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Rank Badge
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: rank == 1
                                ? const Color(0xFFFEF3C7)
                                : rank == 2
                                    ? const Color(0xFFF1F5F9)
                                    : rank == 3
                                        ? const Color(0xFFFFEDD5)
                                        : AppColors.inputBackground,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: rank == 1
                                  ? const Color(0xFFD97706)
                                  : rank == 2
                                      ? AppColors.textDark
                                      : rank == 3
                                          ? const Color(0xFFEA580C)
                                          : AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                              ),
                              Text(
                                'SKU: ${p.sku} • ${p.totalQuantitySold} units sold',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),

                        // Turnover Revenue
                        Text(
                          '${p.totalRevenue.toStringAsFixed(0)} ETB',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.slateDark),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildCustomerAnalyticsCard(CustomerAnalytics ca) {
    return _buildCard(
      title: 'Customer Analytics',
      subtitle: 'Customer growth & top spenders directory',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2 Stats in row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Customers', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${ca.totalCustomers}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.slateDark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('New in Period', style: TextStyle(fontSize: 11, color: AppColors.successEmerald, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('+${ca.newCustomersInPeriod}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.successEmerald)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (ca.topCustomers.isNotEmpty) ...[
            const Text(
              'Top Spender Customers',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slateDark),
            ),
            const SizedBox(height: 8),
            ...ca.topCustomers.map((c) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.infoBg,
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                          Text(
                            c.phone ?? c.email ?? '${c.salesCount} purchases',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${c.totalSpent.toStringAsFixed(0)} ETB',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    String? subtitle,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ],
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

  String _formatShortDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Widget _buildSalesShiftSummary(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();
    final sales = ordersProvider.sales;
    final isLoading = ordersProvider.isLoading;
    final user = context.watch<AuthProvider>().currentUser;
    final shop = context.watch<ShopProvider>().selectedShop;
    final currency = shop?.currency ?? 'ETB';

    // Calculate shift metrics
    final totalRevenue = sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
    final totalOrders = sales.length;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    double cashAmount = 0.0;
    int cashCount = 0;
    double cardAmount = 0.0;
    int cardCount = 0;
    double mobileAmount = 0.0;
    int mobileCount = 0;

    for (final s in sales) {
      final method = s.paymentMethod.toUpperCase();
      if (method.contains('CARD')) {
        cardAmount += s.totalAmount;
        cardCount++;
      } else if (method.contains('MOBILE') || method.contains('TELEBIRR')) {
        mobileAmount += s.totalAmount;
        mobileCount++;
      } else {
        cashAmount += s.totalAmount;
        cashCount++;
      }
    }

    final grandTotal = totalRevenue > 0 ? totalRevenue : 1.0;
    final cashPct = ((cashAmount / grandTotal) * 100).clamp(0.0, 100.0);
    final cardPct = ((cardAmount / grandTotal) * 100).clamp(0.0, 100.0);
    final mobilePct = ((mobileAmount / grandTotal) * 100).clamp(0.0, 100.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Cashier Shift Summary'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Shift Status Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A0F172A),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.badge_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user?.name ?? 'Cashier Shift',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.successEmerald.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.successEmerald, width: 1),
                                  ),
                                  child: const Text(
                                    'ACTIVE SHIFT',
                                    style: TextStyle(
                                      color: AppColors.successEmerald,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${shop?.name ?? "Main Store"} • Today, ${_formatShortDate(DateTime.now())}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (isLoading && sales.isEmpty)
                  const Column(
                    children: [
                      ListRowSkeleton(),
                      SizedBox(height: 12),
                      ListRowSkeleton(),
                    ],
                  )
                else ...[
                  // 3 Shift KPI Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSoftStatCard(
                          label: 'Shift Revenue',
                          value: '${totalRevenue.toStringAsFixed(0)} $currency',
                          icon: Icons.payments_rounded,
                          accentColor: AppColors.successEmerald,
                          bgColor: AppColors.successBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSoftStatCard(
                          label: 'Completed Sales',
                          value: '$totalOrders Receipts',
                          icon: Icons.receipt_long_rounded,
                          accentColor: AppColors.primaryBlue,
                          bgColor: AppColors.infoBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildSoftStatCard(
                    label: 'Average Ticket Value',
                    value: '${avgOrderValue.toStringAsFixed(0)} $currency per sale',
                    subtitle: 'Shift performance rate',
                    icon: Icons.shopping_bag_outlined,
                    accentColor: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFF5F3FF),
                  ),
                  const SizedBox(height: 18),

                  // Register Tender Breakdown
                  _buildCard(
                    title: 'Register Tender Breakdown',
                    subtitle: 'Cash drawer balancing and digital terminal totals',
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 10,
                            child: Row(
                              children: [
                                if (cashPct > 0)
                                  Expanded(flex: cashPct.toInt().clamp(1, 100), child: Container(color: AppColors.successEmerald)),
                                if (cardPct > 0)
                                  Expanded(flex: cardPct.toInt().clamp(1, 100), child: Container(color: AppColors.primaryBlue)),
                                if (mobilePct > 0)
                                  Expanded(flex: mobilePct.toInt().clamp(1, 100), child: Container(color: const Color(0xFF7C3AED))),
                                if (totalRevenue <= 0)
                                  Expanded(child: Container(color: AppColors.borderMedium)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _paymentRow(
                          icon: Icons.payments_rounded,
                          label: 'Cash Tender',
                          amount: cashAmount,
                          count: cashCount,
                          percent: cashPct,
                          color: AppColors.successEmerald,
                        ),
                        const Divider(height: 16, color: AppColors.borderLight),
                        _paymentRow(
                          icon: Icons.credit_card_rounded,
                          label: 'Card Payments',
                          amount: cardAmount,
                          count: cardCount,
                          percent: cardPct,
                          color: AppColors.primaryBlue,
                        ),
                        const Divider(height: 16, color: AppColors.borderLight),
                        _paymentRow(
                          icon: Icons.phone_android_rounded,
                          label: 'TeleBirr',
                          amount: mobileAmount,
                          count: mobileCount,
                          percent: mobilePct,
                          color: const Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Quick Action Links
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamed(context, '/orders');
                          },
                          icon: const Icon(Icons.receipt_long_rounded, size: 16),
                          label: const Text('My Sales History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textDark,
                            side: const BorderSide(color: AppColors.borderMedium),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamed(context, '/catalog');
                          },
                          icon: const Icon(Icons.point_of_sale_rounded, size: 16),
                          label: const Text('New POS Sale', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandLime,
                            foregroundColor: AppColors.brandLimeDarkText,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
