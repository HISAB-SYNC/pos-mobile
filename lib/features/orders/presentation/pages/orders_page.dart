import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../dashboard/presentation/widgets/app_header.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/order_model.dart';
import '../../provider/orders_provider.dart';
import '../widgets/add_order_sheet.dart';
import '../widgets/sale_detail_sheet.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final TextEditingController _searchController = TextEditingController();

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
    context.read<OrdersProvider>().loadOrders(shopId: shopId, token: token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ordersProvider = context.watch<OrdersProvider>();
    final user = auth.currentUser;
    final canManage = user?.isOwner == true || user?.isAdmin == true;
    final summary = ordersProvider.summary;
    final orders = ordersProvider.orders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Orders & Transactions'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: Column(
            children: [
              // Top Section: Overall Metrics & Search
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Transactions Summary',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Orders exported to PDF/Excel'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.file_download_outlined, size: 16),
                          label: const Text('Export', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textDark,
                            side: const BorderSide(color: AppColors.borderLight),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 34),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => AddOrderSheet.show(context),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('New Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.slateDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 34),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 4-Card Soft Tinted KPI Summary Grid
                    Row(
                      children: [
                        Expanded(
                          child: _kpiBox(
                            title: 'Total Orders',
                            value: '${summary.totalOrders}',
                            subtitle: 'Last 7 days',
                            color: AppColors.primaryBlue,
                            bgColor: AppColors.infoBg,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _kpiBox(
                            title: 'Total Received',
                            value: '${summary.totalReceived}',
                            subtitle: '${summary.receivedRevenue.toStringAsFixed(0)} ETB',
                            color: AppColors.successEmerald,
                            bgColor: AppColors.successBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _kpiBox(
                            title: 'Total Returned',
                            value: '${summary.totalReturned}',
                            subtitle: '${summary.returnedCost.toStringAsFixed(0)} ETB',
                            color: const Color(0xFF7C3AED),
                            bgColor: const Color(0xFFF5F3FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _kpiBox(
                            title: 'In Delivery',
                            value: '${summary.onTheWay}',
                            subtitle: '${summary.onTheWayCost.toStringAsFixed(0)} ETB',
                            color: AppColors.warningAmber,
                            bgColor: AppColors.warningBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => ordersProvider.setSearchQuery(val),
                      decoration: AppDecorations.inputDecoration(
                        hintText: 'Search order ID, product name...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  ordersProvider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips Horizontal Bar
              Container(
                height: 48,
                color: Colors.white,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('All', ordersProvider.selectedStatusFilter, ordersProvider),
                    const SizedBox(width: 8),
                    _buildFilterChip('Confirmed', ordersProvider.selectedStatusFilter, ordersProvider),
                    const SizedBox(width: 8),
                    _buildFilterChip('Out for delivery', ordersProvider.selectedStatusFilter, ordersProvider),
                    const SizedBox(width: 8),
                    _buildFilterChip('Delayed', ordersProvider.selectedStatusFilter, ordersProvider),
                    const SizedBox(width: 8),
                    _buildFilterChip('Returned', ordersProvider.selectedStatusFilter, ordersProvider),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

              // Orders List
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 10),
                            Text(
                              'No transactions found',
                              style: AppTypography.titleSmall.copyWith(color: AppColors.textMedium),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _OrderCard(order: order);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiBox({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppDecorations.softCardDecoration(
        backgroundColor: bgColor,
        borderRadius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              Text(subtitle, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String current, OrdersProvider provider) {
    final isSelected = label.toLowerCase() == current.toLowerCase();
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.lightImpact();
        provider.setStatusFilter(label);
      },
      selectedColor: AppColors.slateDark,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textDark,
      ),
      backgroundColor: AppColors.inputBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.slateDark : AppColors.borderLight,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ShopOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeTextColor;

    if (order.isDelayed) {
      badgeBg = AppColors.warningBg;
      badgeTextColor = AppColors.warningAmber;
    } else if (order.isConfirmed) {
      badgeBg = AppColors.infoBg;
      badgeTextColor = AppColors.primaryBlue;
    } else if (order.isOutForDelivery) {
      badgeBg = AppColors.successBg;
      badgeTextColor = AppColors.successEmerald;
    } else {
      badgeBg = AppColors.inputBackground;
      badgeTextColor = AppColors.textMedium;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => SaleDetailSheet.show(context, order: order),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Product Name, Order ID, and Status Badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productName,
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order #${order.orderId} • ${order.category}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeTextColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 10),

              // Row 2: Price, Qty, and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Qty: ${order.quantity}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        order.formattedDate,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  Text(
                    '${order.price.toStringAsFixed(0)} ETB',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.slateDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
