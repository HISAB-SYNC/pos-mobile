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
import '../../models/supplier.dart';
import '../../provider/supplier_provider.dart';
import '../widgets/add_supplier_sheet.dart';

class SuppliersListPage extends StatefulWidget {
  const SuppliersListPage({super.key});

  @override
  State<SuppliersListPage> createState() => _SuppliersListPageState();
}

class _SuppliersListPageState extends State<SuppliersListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSuppliers();
    });
  }

  void _loadSuppliers() {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final shopId = shop.selectedShop?.id ?? 'default-shop';
    final token = auth.token;
    context.read<SupplierProvider>().loadSuppliers(shopId: shopId, token: token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final supplierProvider = context.watch<SupplierProvider>();
    final user = auth.currentUser;
    final canManage = user?.isOwner == true || user?.isAdmin == true;
    final suppliers = supplierProvider.suppliers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Suppliers Directory'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadSuppliers(),
          child: Column(
            children: [
              // Top Action Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Suppliers (${suppliers.length})',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Suppliers list exported to CSV'),
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
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              AddSupplierSheet.show(context);
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text(
                              'Add Supplier',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.slateDark,
                              foregroundColor: Colors.white,
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

                    // Filter Pills
                    PosPillToggle<String>(
                      values: const ['All', 'Taking Return', 'Not Taking Return'],
                      selectedValue: supplierProvider.selectedTypeFilter,
                      labelBuilder: (v) => v,
                      isDense: true,
                      onSelected: (val) => supplierProvider.setTypeFilter(val),
                    ),
                    const SizedBox(height: 12),

                    // Search Supplier Input
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => supplierProvider.setSearchQuery(val),
                      decoration: AppDecorations.inputDecoration(
                        hintText: 'Search supplier by name, product or phone...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  supplierProvider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

              // Suppliers List
              Expanded(
                child: supplierProvider.isLoading
                    ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, __) => const ListRowSkeleton(),
                      )
                    : suppliers.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.store_outlined,
                            title: supplierProvider.searchQuery.isNotEmpty
                                ? 'No suppliers matching "${supplierProvider.searchQuery}"'
                                : 'No suppliers registered yet',
                            description: 'Add suppliers to track inventory vendors, purchase receipts, and contacts.',
                            actionLabel: canManage ? '+ Add Supplier' : null,
                            onAction: canManage ? () => AddSupplierSheet.show(context) : null,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: suppliers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final supplier = suppliers[index];
                              return _SupplierCard(
                                supplier: supplier,
                                canManage: canManage,
                                onEdit: () => AddSupplierSheet.show(context, supplierToEdit: supplier),
                                onDelete: () => _confirmDelete(context, supplier),
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

  void _confirmDelete(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRose, size: 22),
            SizedBox(width: 8),
            Text('Remove Supplier', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Text('Are you sure you want to remove "${supplier.name}"?'),
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
              final supplierProvider = context.read<SupplierProvider>();

              final ok = await supplierProvider.deleteSupplier(
                shopId: shop.selectedShop?.id ?? '',
                token: auth.token,
                supplierId: supplier.id,
              );

              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${supplier.name} removed successfully'),
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

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isTakingReturn = supplier.isTakingReturn;
    final productText = supplier.product ?? 'Assorted Products';
    final categoryText = supplier.category ?? 'General';
    final phoneText = supplier.phone ?? 'No phone';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name, Avatar, Product Tag, and Menu
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.infoBg,
                child: Text(
                  supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
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
                      supplier.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            productText,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textMedium),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('• $categoryText', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isTakingReturn ? AppColors.successBg : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isTakingReturn ? 'Taking Return' : 'No Return',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isTakingReturn ? AppColors.successEmerald : AppColors.textMuted,
                  ),
                ),
              ),
              if (canManage) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMedium),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onEdit();
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.errorRose),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDelete();
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 6),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 10),

          // Row 2: Contact, Phone & Address
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    phoneText,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    supplier.contactInfo.isNotEmpty ? supplier.contactInfo : 'Main Warehouse',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
