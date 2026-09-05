import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../cart/provider/cart_provider.dart';
import '../../../category/provider/category_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/product.dart';
import '../../provider/product_provider.dart';
import '../widgets/add_product_sheet.dart';
import '../widgets/add_adjustment_sheet.dart';
import '../widgets/add_purchase_sheet.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final user = auth.currentUser;
    final canEdit = user?.isOwner == true || user?.isAdmin == true;

    final currentProduct = productProvider.products.firstWhere(
      (p) => p.id == widget.product.id,
      orElse: () => widget.product,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentProduct.name,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (canEdit) ...[
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                AddProductSheet.show(context, productToEdit: currentProduct);
              },
              icon: const Icon(Icons.edit_outlined, size: 15, color: AppColors.primaryBlue),
              label: const Text('Edit', style: TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderLight),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRose),
              onPressed: () => _confirmDelete(context, currentProduct),
            ),
          ],
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.slateDark,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.slateDark,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Purchases'),
            Tab(text: 'Adjustments'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(product: currentProduct),
          _PurchasesTab(product: currentProduct, canManage: canEdit),
          _AdjustmentsTab(product: currentProduct, canManage: canEdit),
          _HistoryTab(product: currentProduct),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRose, size: 22),
            SizedBox(width: 8),
            Text('Delete Product', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Text('Are you sure you want to delete "${product.name}"?'),
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
              final productProvider = context.read<ProductProvider>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);

              final ok = await productProvider.deleteProduct(
                shopId: shop.selectedShop?.id ?? '',
                token: auth.token,
                productId: product.id,
              );

              if (ok) {
                nav.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Product deleted'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 1. OVERVIEW TAB
// ----------------------------------------------------------------------
class _OverviewTab extends StatelessWidget {
  final Product product;

  const _OverviewTab({required this.product});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    String displayCategory = product.categoryName;
    if ((displayCategory == 'General' || displayCategory.startsWith('{')) && product.categoryId != null) {
      final found = categoryProvider.categories.where((c) => c.id == product.categoryId);
      if (found.isNotEmpty) {
        displayCategory = found.first.name;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary Details Card
          _buildCard(
            title: 'Primary Details',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _infoRow('Product Name', product.name),
                      _infoRow('SKU / Code', product.sku),
                      _infoRow('Category', displayCategory),
                      _infoRow('Expiry Date', product.expiryDate ?? 'N/A'),
                      _infoRow('Selling Price', '${product.price.toStringAsFixed(0)} ETB'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 84,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: product.name.toLowerCase().contains('coca')
                        ? const Icon(Icons.local_drink_rounded, color: AppColors.errorRose, size: 36)
                        : const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Supplier Details Card (Restricted to OWNER and ADMIN)
          if (context.watch<AuthProvider>().currentUser?.isSales != true) ...[
            _buildCard(
              title: 'Supplier Details',
              child: Column(
                children: [
                  _infoRow('Supplier Name', product.supplierName ?? 'Vendor Supplier'),
                  _infoRow('Contact Phone', product.supplierContact ?? '09112 34567'),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Stock Metrics Card
          _buildCard(
            title: 'Stock Metrics',
            child: Column(
              children: [
                _infoRow('Opening Stock', '${product.openingStock} Units'),
                _infoRow('Remaining Stock', '${product.stockQuantity} Units'),
                _infoRow('On the Way', '${product.onTheWay} Units'),
                _infoRow('Low Stock Alert', '${product.lowStockThreshold} Units'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Stock Locations Card
          _buildCard(
            title: 'Stock Locations',
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Store Branch', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      Text('Stock In Hand', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _locationRow(product.location.isNotEmpty ? product.location : 'Main Store', '${product.stockQuantity} Units'),
              ],
            ),
          ),

          // For Sales/Cashier: Add to Cart Action
          if (context.watch<AuthProvider>().currentUser?.isSales == true) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<CartProvider>().addProduct(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to active cart'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                label: const Text(
                  'Add to POS Cart',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandLime,
                  foregroundColor: AppColors.brandLimeDarkText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRow(String name, String stock) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(stock, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 2. PURCHASES TAB
// ----------------------------------------------------------------------
class _PurchasesTab extends StatelessWidget {
  final Product product;
  final bool canManage;

  const _PurchasesTab({required this.product, required this.canManage});

  @override
  Widget build(BuildContext context) {
    final purchases = context.watch<ProductProvider>().purchases;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canManage) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Purchase Orders',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    AddPurchaseSheet.show(
                      context,
                      productId: product.id,
                      productName: product.name,
                      defaultSupplier: product.supplierName,
                      defaultCost: product.buyingPrice,
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('New Purchase', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandLime,
                    foregroundColor: AppColors.brandLimeDarkText,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: purchases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = purchases[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: AppDecorations.cardDecoration,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.purchaseId,
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.status == 'completed' ? AppColors.successBg : AppColors.warningBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: item.status == 'completed' ? AppColors.successEmerald : AppColors.warningAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Supplier: ${item.supplierName}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${item.quantity} Units @ ${item.unitCost.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${item.date}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Total: ${item.totalCost.toStringAsFixed(0)} ETB',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 3. ADJUSTMENTS TAB
// ----------------------------------------------------------------------
class _AdjustmentsTab extends StatelessWidget {
  final Product product;
  final bool canManage;

  const _AdjustmentsTab({required this.product, required this.canManage});

  @override
  Widget build(BuildContext context) {
    final adjustments = context.watch<ProductProvider>().adjustments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canManage) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock Adjustments',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    AddAdjustmentSheet.show(
                      context,
                      productId: product.id,
                      productName: product.name,
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('New Adjustment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandLime,
                    foregroundColor: AppColors.brandLimeDarkText,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: adjustments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = adjustments[index];
              final isNegative = item.quantityChange < 0;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: AppDecorations.cardDecoration,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.adjustmentId, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        Text(
                          '${isNegative ? "" : "+"}${item.quantityChange} Units',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isNegative ? AppColors.errorRose : AppColors.successEmerald,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Reason: ${item.reason}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.storeLocation,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Date: ${item.date}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 4. HISTORY TAB
// ----------------------------------------------------------------------
class _HistoryTab extends StatelessWidget {
  final Product product;

  const _HistoryTab({required this.product});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ProductProvider>().history;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Transaction Audit Trail',
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = history[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: AppDecorations.cardDecoration,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.transactionId, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.type == 'Purchase'
                                ? AppColors.infoBg
                                : item.type == 'Sale'
                                    ? AppColors.successBg
                                    : AppColors.warningBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: item.type == 'Purchase'
                                  ? AppColors.primaryBlue
                                  : item.type == 'Sale'
                                      ? AppColors.successEmerald
                                      : AppColors.warningAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Quantity: ${item.quantity > 0 ? "+" : ""}${item.quantity} Units', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Value: ${item.value.toStringAsFixed(0)} ETB',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Store: ${item.storeLocation} (${item.personName})',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(item.date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
