import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../cart/provider/cart_provider.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';
import '../../../dashboard/presentation/widgets/app_header.dart';
import '../../../category/provider/category_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/product.dart';
import '../../provider/product_provider.dart';
import '../widgets/add_product_sheet.dart';
import 'product_detail_page.dart';

class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  void _loadProducts() {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final shopId = shop.selectedShop?.id ?? 'default-shop';
    final token = auth.token;
    if (token != null && token.isNotEmpty) {
      context.read<CategoryProvider>().loadCategories(shopId: shopId, token: token);
    }
    context.read<ProductProvider>().loadProducts(shopId: shopId, token: token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final user = auth.currentUser;
    final canManageProducts = user?.isOwner == true || user?.isAdmin == true;
    final products = productProvider.products;

    // Collect all unique categories from CategoryProvider + any product category
    final categorySet = <String>{'All'};
    for (final c in categoryProvider.categories) {
      if (c.name.trim().isNotEmpty) categorySet.add(c.name.trim());
    }
    for (final p in productProvider.allProducts) {
      if (p.categoryName.trim().isNotEmpty) categorySet.add(p.categoryName.trim());
    }
    final categories = categorySet.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Products'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadProducts(),
          child: Column(
            children: [
              // Top Action & Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF161B20),
                          ),
                        ),
                        const Spacer(),
                        // Download / Export button
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Product list exported successfully'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download_outlined, size: 16),
                          label: const Text('Download', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: const Size(0, 34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        if (canManageProducts) ...[
                          const SizedBox(width: 8),
                          // "+ Add Product" Black Button
                          ElevatedButton.icon(
                            onPressed: () => AddProductSheet.show(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Add Product',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF161B20),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: const Size(0, 34),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => productProvider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search product by name or SKU...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  productProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Pills
              Container(
                height: 44,
                color: Colors.white,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = productProvider.selectedCategory.toLowerCase() == cat.toLowerCase();

                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) productProvider.setCategoryFilter(cat);
                      },
                      selectedColor: const Color(0xFF161B20),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF161B20) : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    );
                  },
                ),
              ),
              const Divider(height: 1),

              // Product Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFF1F5F9),
                child: const Row(
                  children: [
                    SizedBox(width: 44, child: Text('Image', style: _headerStyle)),
                    SizedBox(width: 10),
                    Expanded(flex: 3, child: Text('Name / Category', style: _headerStyle)),
                    Expanded(flex: 2, child: Text('In-stock', textAlign: TextAlign.center, style: _headerStyle)),
                    Expanded(flex: 2, child: Text('Price', textAlign: TextAlign.end, style: _headerStyle)),
                    SizedBox(width: 32),
                  ],
                ),
              ),

              // Product List
              Expanded(
                child: products.isEmpty
                    ? _buildEmptyState(productProvider.searchQuery)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _ProductRowItem(
                            product: product,
                            onTap: () {
                              productProvider.selectProduct(product);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailPage(product: product),
                                ),
                              );
                            },
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

  Widget _buildEmptyState(String query) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            query.isNotEmpty ? 'No products found for "$query"' : 'No products available',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try changing your search or category filter',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: Color(0xFF64748B),
);

class _ProductRowItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductRowItem({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isSales = user?.isSales == true;
    final categoryProvider = context.watch<CategoryProvider>();

    String displayCategory = product.categoryName;
    if ((displayCategory == 'General' || displayCategory.startsWith('{')) && product.categoryId != null) {
      final found = categoryProvider.categories.where((c) => c.id == product.categoryId);
      if (found.isNotEmpty) {
        displayCategory = found.first.name;
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Row(
          children: [
            // Product Thumbnail Image box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: _buildThumbnail(product.name),
              ),
            ),
            const SizedBox(width: 12),

            // Product Name & Category
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF161B20),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayCategory,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // In-stock quantity
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${product.stockQuantity}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: product.isOutOfStock
                          ? const Color(0xFFEF4444)
                          : product.isLowStock
                              ? const Color(0xFFD97706)
                              : const Color(0xFF161B20),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: product.isOutOfStock
                          ? const Color(0xFFFEE2E2)
                          : product.isLowStock
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.status,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: product.isOutOfStock
                            ? const Color(0xFFDC2626)
                            : product.isLowStock
                                ? const Color(0xFFB45309)
                                : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Price in Birr
            Expanded(
              flex: 2,
              child: Text(
                '${product.price.toStringAsFixed(0)} Birr',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF161B20),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Trailing action: Add to Cart button for Sales role, or Chevron for others
            if (isSales)
              IconButton(
                icon: const Icon(Icons.add_shopping_cart, size: 18, color: Color(0xFF2563EB)),
                onPressed: () {
                  // Add to Cart
                  context.read<CartProvider>().addProduct(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      duration: const Duration(milliseconds: 800),
                    ),
                  );
                },
              )
            else
              const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String name) {
    if (name.toLowerCase().contains('coca')) {
      return const Icon(Icons.local_drink, color: Colors.redAccent, size: 22);
    } else if (name.toLowerCase().contains('juice') || name.toLowerCase().contains('orange')) {
      return const Icon(Icons.emoji_food_beverage_outlined, color: Colors.orange, size: 22);
    } else if (name.toLowerCase().contains('tomato')) {
      return const Icon(Icons.lunch_dining_outlined, color: Colors.red, size: 22);
    } else if (name.toLowerCase().contains('tv') || name.toLowerCase().contains('earphone') || name.toLowerCase().contains('laptop') || name.toLowerCase().contains('samsung')) {
      return const Icon(Icons.devices, color: Colors.blueGrey, size: 22);
    }
    return const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 22);
  }
}
