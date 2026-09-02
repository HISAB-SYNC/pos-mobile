import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/skeleton_loaders.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../cart/provider/cart_provider.dart';
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

    final categorySet = <String>{'All'};
    for (final c in categoryProvider.categories) {
      if (c.name.trim().isNotEmpty) categorySet.add(c.name.trim());
    }
    for (final p in productProvider.allProducts) {
      if (p.categoryName.trim().isNotEmpty) categorySet.add(p.categoryName.trim());
    }
    final categories = categorySet.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Products Inventory'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadProducts(),
          child: Column(
            children: [
              // Top Action & Search Area
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Products List (${products.length})',
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
                                content: Text('Product list exported to CSV'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.file_download_outlined, size: 20),
                          tooltip: 'Export CSV',
                          color: AppColors.textDark,
                        ),
                        if (canManageProducts) ...[
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              AddProductSheet.show(context);
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text(
                              'Add',
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

                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => productProvider.setSearchQuery(val),
                      decoration: AppDecorations.inputDecoration(
                        hintText: 'Search product by name or SKU...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  productProvider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Pills
              Container(
                height: 48,
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
                        HapticFeedback.lightImpact();
                        if (selected) productProvider.setCategoryFilter(cat);
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
                  },
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),

              // Product Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.inputBackground,
                child: const Row(
                  children: [
                    SizedBox(width: 44, child: Text('Image', style: _headerStyle)),
                    SizedBox(width: 12),
                    Expanded(flex: 3, child: Text('Name / Category', style: _headerStyle)),
                    Expanded(flex: 2, child: Text('In-stock', textAlign: TextAlign.center, style: _headerStyle)),
                    Expanded(flex: 2, child: Text('Price (ETB)', textAlign: TextAlign.end, style: _headerStyle)),
                    SizedBox(width: 28),
                  ],
                ),
              ),

              // Product List
              Expanded(
                child: productProvider.isLoading
                    ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, __) => const ListRowSkeleton(),
                      )
                    : products.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.inventory_2_outlined,
                            title: productProvider.searchQuery.isNotEmpty
                                ? 'No products found'
                                : 'No products available',
                            description: productProvider.searchQuery.isNotEmpty
                                ? 'No product matches "${productProvider.searchQuery}"'
                                : 'Add your first product to manage stock and sell via POS.',
                            actionLabel: canManageProducts ? '+ Add Product' : null,
                            onAction: canManageProducts ? () => AddProductSheet.show(context) : null,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: products.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: AppColors.borderLight,
                            ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return _ProductRowItem(
                                product: product,
                                onTap: () {
                                  HapticFeedback.lightImpact();
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
}

const TextStyle _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: AppColors.textMuted,
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

    Color badgeBg;
    Color badgeColor;
    if (product.isOutOfStock) {
      badgeBg = AppColors.errorBg;
      badgeColor = AppColors.errorRose;
    } else if (product.isLowStock) {
      badgeBg = AppColors.warningBg;
      badgeColor = AppColors.warningAmber;
    } else {
      badgeBg = AppColors.successBg;
      badgeColor = AppColors.successEmerald;
    }

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Product Thumbnail
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(10),
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
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayCategory,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
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
                        fontWeight: FontWeight.w800,
                        color: product.isOutOfStock
                            ? AppColors.errorRose
                            : product.isLowStock
                                ? AppColors.warningAmber
                                : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.status,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Price in ETB
              Expanded(
                flex: 2,
                child: Text(
                  '${product.price.toStringAsFixed(0)} ETB',
                  textAlign: TextAlign.end,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.slateDark,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Trailing action
              if (isSales)
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 20, color: AppColors.primaryBlue),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.read<CartProvider>().addProduct(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart'),
                        duration: const Duration(milliseconds: 800),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                )
              else
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String name) {
    if (name.toLowerCase().contains('coca') || name.toLowerCase().contains('drink')) {
      return const Icon(Icons.local_drink_rounded, color: AppColors.errorRose, size: 20);
    } else if (name.toLowerCase().contains('juice') || name.toLowerCase().contains('orange') || name.toLowerCase().contains('food')) {
      return const Icon(Icons.restaurant_rounded, color: AppColors.warningAmber, size: 20);
    } else if (name.toLowerCase().contains('tv') || name.toLowerCase().contains('phone') || name.toLowerCase().contains('laptop')) {
      return const Icon(Icons.devices_rounded, color: AppColors.primaryBlue, size: 20);
    }
    return const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 20);
  }
}
