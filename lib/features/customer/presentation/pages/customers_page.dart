import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/pos_pill_toggle.dart';
import '../../../../core/widgets/skeleton_loaders.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../dashboard/presentation/widgets/app_header.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/customer_model.dart';
import '../../provider/customer_provider.dart';
import '../widgets/add_customer_sheet.dart';
import 'customer_detail_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();
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
    if (shopId.isNotEmpty) {
      context.read<CustomerProvider>().loadCustomers(shopId: shopId, token: token);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentShopId = context.watch<ShopProvider>().selectedShop?.id;
    if (_lastLoadedShopId != null && _lastLoadedShopId != currentShopId && currentShopId != null && currentShopId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }

    final auth = context.watch<AuthProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final user = auth.currentUser;
    final canManage = user?.isOwner == true || user?.isAdmin == true || user?.isSales == true;
    final customers = customerProvider.customers;
    final currentTab = customerProvider.selectedDebtFilter;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Customers Directory'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: Column(
            children: [
              // Top Segment & Actions Area
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Customers (${customers.length})',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Customer list exported to CSV'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.file_download_outlined, size: 20),
                          tooltip: 'Export CSV',
                          color: AppColors.textDark,
                        ),
                        if (canManage) ...[
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              AddCustomerSheet.show(context);
                            },
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandLime,
                              foregroundColor: AppColors.brandLimeDarkText,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: const Size(0, 34),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Debt Status Pill Toggle
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: PosPillToggle<String>(
                        values: const ['All Customers', 'With debt', 'No debt'],
                        selectedValue: currentTab,
                        labelBuilder: (v) => v,
                        isDense: true,
                        onSelected: (val) => customerProvider.setDebtFilter(val),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => customerProvider.setSearchQuery(val),
                      decoration: AppDecorations.inputDecoration(
                        hintText: 'Search customer by name or phone...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  customerProvider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

              // Customer List
              Expanded(
                child: customerProvider.isLoading
                    ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, __) => const ListRowSkeleton(),
                      )
                    : customers.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.groups_outlined,
                            title: customerProvider.searchQuery.isNotEmpty
                                ? 'No customer found'
                                : 'No customers listed yet',
                            description: customerProvider.searchQuery.isNotEmpty
                                ? 'No customer matches "${customerProvider.searchQuery}"'
                                : 'Register customers to track credit sales, debts, and purchase history.',
                            actionLabel: canManage ? '+ Add Customer' : null,
                            onAction: canManage ? () => AddCustomerSheet.show(context) : null,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: customers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final customer = customers[index];
                              return _CustomerCard(
                                customer: customer,
                                canManage: canManage,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  customerProvider.selectCustomer(customer);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CustomerDetailPage(customer: customer),
                                    ),
                                  );
                                },
                                onEdit: () => AddCustomerSheet.show(context, customerToEdit: customer),
                                onDelete: () => _confirmDelete(context, customer),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRose, size: 22),
            SizedBox(width: 8),
            Text('Remove Customer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Text('Are you sure you want to remove "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              Navigator.pop(dialogCtx);
              final auth = context.read<AuthProvider>();
              final shop = context.read<ShopProvider>();
              final provider = context.read<CustomerProvider>();

              final ok = await provider.deleteCustomer(
                shopId: shop.selectedShop?.id ?? '',
                token: auth.token,
                customerId: customer.id,
              );

              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${customer.name} removed'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasDebt = customer.hasDebt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Avatar, Name, Code & Debt Badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: hasDebt ? AppColors.errorBg : AppColors.infoBg,
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: hasDebt ? AppColors.errorRose : AppColors.primaryBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${customer.customerCode} • ${customer.address}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: customer.isOverdue
                          ? AppColors.errorBg
                          : (hasDebt ? AppColors.warningBg : AppColors.successBg),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      customer.status,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: customer.isOverdue
                            ? AppColors.errorRose
                            : (hasDebt ? AppColors.warningAmber : AppColors.successEmerald),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 10),

              // Row 2: Phone, Balance & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            customer.phone.isNotEmpty ? customer.phone : 'No phone',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      if (hasDebt) ...[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Debt: ${customer.totalDebt.toStringAsFixed(0)} ETB',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.errorRose,
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          '0.00 ETB',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                    ],
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
