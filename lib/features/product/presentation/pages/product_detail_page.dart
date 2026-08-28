import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../cart/provider/cart_provider.dart';
import '../../../category/provider/category_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/product.dart';
import '../../models/product_purchase.dart';
import '../../models/product_adjustment.dart';
import '../../models/product_history.dart';
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

    final categoryProvider = context.watch<CategoryProvider>();
    String displayCategory = currentProduct.categoryName;
    if ((displayCategory == 'General' || displayCategory.startsWith('{')) && currentProduct.categoryId != null) {
      final found = categoryProvider.categories.where((c) => c.id == currentProduct.categoryId);
      if (found.isNotEmpty) {
        displayCategory = found.first.name;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF161B20)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentProduct.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF161B20),
          ),
        ),
        actions: [
          if (canEdit) ...[
            // Edit button
            OutlinedButton.icon(
              onPressed: () => AddProductSheet.show(context, productToEdit: currentProduct),
              icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF2563EB)),
              label: const Text('Edit', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 8),

            // Delete menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
              onSelected: (val) {
                if (val == 'delete') {
                  _confirmDelete(context, currentProduct);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Delete Product', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final auth = context.read<AuthProvider>();
              final shop = context.read<ShopProvider>();
              final productProvider = context.read<ProductProvider>();

              final ok = await productProvider.deleteProduct(
                shopId: shop.selectedShop?.id ?? '',
                token: auth.token,
                productId: product.id,
              );

              if (mounted && ok) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 1. OVERVIEW TAB (Matching Image 2 Left)
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
                      _infoRow('Product name', product.name),
                      _infoRow('Product ID', product.sku),
                      _infoRow('Product category', displayCategory),
                      _infoRow('Expiry Date', product.expiryDate ?? 'N/A'),
                      _infoRow('Price', '${product.price.toStringAsFixed(0)} Birr'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Product Image Box
                Container(
                  width: 84,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Center(
                    child: product.name.toLowerCase().contains('coca')
                        ? const Icon(Icons.local_drink, color: Colors.redAccent, size: 40)
                        : const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 36),
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
                  _infoRow('Supplier name', product.supplierName ?? 'Mr. X'),
                  _infoRow('Contact Number', product.supplierContact ?? '09789 88757'),
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
                _infoRow('Opening Stock', '${product.openingStock}'),
                _infoRow('Remaining Stock', '${product.stockQuantity}'),
                _infoRow('On the way', '${product.onTheWay}'),
                _infoRow('Threshold value', '${product.lowStockThreshold}'),
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
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  color: const Color(0xFFF1F5F9),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Store Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      Text('Stock in hand', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _locationRow('Kolfe Branch', '15'),
                const Divider(height: 12),
                _locationRow('Merkato Branch', '19'),
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
                  context.read<CartProvider>().addProduct(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to active cart'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: const Text(
                  'Add to POS Cart',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF161B20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
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
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF161B20))),
        ],
      ),
    );
  }

  Widget _locationRow(String name, String stock) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 13, color: Color(0xFF161B20))),
          Text(stock, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 2. PURCHASES TAB (Matching Image 2 Right)
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
                const Text(
                  'Purchase Orders',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                ),
                ElevatedButton.icon(
                  onPressed: () => AddPurchaseSheet.show(
                    context,
                    productId: product.id,
                    productName: product.name,
                    defaultSupplier: product.supplierName,
                    defaultCost: product.buyingPrice,
                  ),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('New Purchase', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF161B20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.purchaseId,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.status == 'completed' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: item.status == 'completed' ? const Color(0xFF15803D) : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Supplier: ${item.supplierName}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text('${item.quantity} Units @ ${item.unitCost.toStringAsFixed(0)} Birr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${item.date}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        Text(
                          'Total: ${item.totalCost.toStringAsFixed(0)} Birr',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
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
// 3. ADJUSTMENTS TAB (Matching Image 3 Left)
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
                const Text(
                  'Stock Adjustments',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                ),
                ElevatedButton.icon(
                  onPressed: () => AddAdjustmentSheet.show(
                    context,
                    productId: product.id,
                    productName: product.name,
                  ),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('New Adjustment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF161B20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.adjustmentId, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF161B20))),
                        Text(
                          '${isNegative ? "" : "+"}${item.quantityChange} Units',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isNegative ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reason: ${item.reason}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(item.storeLocation, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Date: ${item.date}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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
// 4. HISTORY TAB (Matching Image 3 Right)
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
          const Text(
            'Transaction Audit Trail',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.transactionId, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.type == 'Purchase'
                                ? const Color(0xFFEFF6FF)
                                : item.type == 'Sale'
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: item.type == 'Purchase'
                                  ? const Color(0xFF1D4ED8)
                                  : item.type == 'Sale'
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB45309),
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
                        Text('Value: ${item.value.toStringAsFixed(0)} Birr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF161B20))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Store: ${item.storeLocation} (by ${item.personName})', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text(item.date, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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
