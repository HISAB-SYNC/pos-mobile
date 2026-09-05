import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/pos_floating_cart_bar.dart';
import '../../../../core/widgets/skeleton_loaders.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../../cart/provider/cart_provider.dart';
import '../../../category/provider/category_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../../product/models/product.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'All';
  bool _isGridView = false;
  bool _onlyInStock = false;
  bool _onlyLowStock = false;

  String? _lastLoadedShopId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCatalog();
    });
  }

  void _loadCatalog() {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final shopId = shop.selectedShop?.id ?? '';
    _lastLoadedShopId = shopId;
    final token = auth.token;
    if (shopId.isNotEmpty) {
      context.read<ProductProvider>().loadProducts(shopId: shopId, token: token);
      if (token != null) {
        context.read<CategoryProvider>().loadCategories(shopId: shopId, token: token);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    final search = _searchController.text.toLowerCase().trim();

    return allProducts.where((product) {
      final matchesSearch = search.isEmpty ||
          product.name.toLowerCase().contains(search) ||
          product.sku.toLowerCase().contains(search);

      final matchesCategory = selectedCategory == 'All' ||
          product.categoryName.toLowerCase() == selectedCategory.toLowerCase();

      final matchesInStock = !_onlyInStock || product.stockQuantity > 0;
      final matchesLowStock = !_onlyLowStock || isLowStock(product);

      return matchesSearch && matchesCategory && matchesInStock && matchesLowStock;
    }).toList();
  }

  int _getCategoryCount(String categoryName, List<Product> allProducts) {
    if (categoryName == 'All') return allProducts.length;
    return allProducts.where((p) => p.categoryName.toLowerCase() == categoryName.toLowerCase()).length;
  }

  bool isLowStock(Product product) {
    return product.stockQuantity <= product.lowStockThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final currentShopId = context.watch<ShopProvider>().selectedShop?.id;
    if (_lastLoadedShopId != null && _lastLoadedShopId != currentShopId && currentShopId != null && currentShopId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCatalog();
      });
    }

    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final cart = context.watch<CartProvider>();
    final allProducts = productProvider.allProducts;
    final products = _getFilteredProducts(allProducts);

    final catSet = <String>{'All'};
    for (final c in categoryProvider.categories) {
      if (c.name.trim().isNotEmpty) catSet.add(c.name.trim());
    }
    for (final p in allProducts) {
      if (p.categoryName.trim().isNotEmpty) catSet.add(p.categoryName.trim());
    }
    final categories = catSet.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'POS Terminal',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: AppColors.slateDark,
              size: 22,
            ),
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isGridView = !_isGridView);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: AppDecorations.inputDecoration(
                    hintText: 'Search items by name or SKU...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Categories Horizontal Selector with Live Item Counts
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory.toLowerCase() == category.toLowerCase();
                    final count = _getCategoryCount(category, allProducts);

                    return ChoiceChip(
                      label: Text('$category ($count)'),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? AppColors.brandLimeDarkText : AppColors.textDark,
                      ),
                      selectedColor: AppColors.brandLime,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.brandLimeDark : AppColors.borderLight,
                        ),
                      ),
                      onSelected: (_) {
                        HapticFeedback.lightImpact();
                        setState(() => selectedCategory = category);
                      },
                    );
                  },
                ),
              ),

              // Quick Filter Toggles
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('In Stock Only', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      selected: _onlyInStock,
                      selectedColor: AppColors.successBg,
                      checkmarkColor: AppColors.successEmerald,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _onlyInStock ? AppColors.successEmerald : AppColors.borderLight,
                        ),
                      ),
                      onSelected: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _onlyInStock = val);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Low Stock Alerts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      selected: _onlyLowStock,
                      selectedColor: AppColors.warningBg,
                      checkmarkColor: AppColors.warningAmber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _onlyLowStock ? AppColors.warningAmber : AppColors.borderLight,
                        ),
                      ),
                      onSelected: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _onlyLowStock = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Product List / Grid Content
              Expanded(
                child: productProvider.isLoading
                    ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, __) => const ListRowSkeleton(),
                      )
                    : products.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.inventory_2_outlined,
                            title: 'No products found',
                            description: 'Try adjusting your search terms or selecting another category.',
                          )
                        : _isGridView
                            ? GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.82,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  return _ProductGridCard(
                                    product: product,
                                    isLowStock: isLowStock(product),
                                  );
                                },
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                                itemCount: products.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  return _ProductCard(
                                    product: product,
                                    isLowStock: isLowStock(product),
                                  );
                                },
                              ),
              ),
            ],
          ),

          // Floating Quick Cart Bar docked above floating bottom navbar
          if (cart.itemCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 82,
              child: PosFloatingCartBar(
                itemCount: cart.itemCount,
                formattedTotal: '${cart.subtotal.toStringAsFixed(0)} ETB',
                label: 'View Cart & Charge',
                onTap: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isLowStock;

  const _ProductCard({
    required this.product,
    required this.isLowStock,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartItemIndex = cart.items.indexWhere((i) => i.product.id == product.id);
    final inCartQty = cartItemIndex >= 0 ? cart.items[cartItemIndex].quantity : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardDecoration,
      child: Row(
        children: [
          // Product avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.textMedium,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Product information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'SKU: ${product.sku}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${product.price.toStringAsFixed(0)} ETB',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slateDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLowStock ? AppColors.warningBg : AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Stock: ${product.stockQuantity}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isLowStock ? AppColors.warningAmber : AppColors.textMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Interactive Add / Stepper button with Live Feedback
          if (inCartQty > 0)
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<CartProvider>().decreaseProduct(product);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.remove_rounded, size: 16, color: AppColors.textDark),
                    ),
                  ),
                  Text(
                    '$inCartQty',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                  ),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<CartProvider>().addProduct(product);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.add_rounded, size: 16, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<CartProvider>().addProduct(product);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${product.name} added to cart')),
                        ],
                      ),
                      duration: const Duration(milliseconds: 700),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 85),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.brandLime,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.brandLimeGlow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 22,
                    color: AppColors.brandLimeDarkText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final bool isLowStock;

  const _ProductGridCard({
    required this.product,
    required this.isLowStock,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartItemIndex = cart.items.indexWhere((i) => i.product.id == product.id);
    final inCartQty = cartItemIndex >= 0 ? cart.items[cartItemIndex].quantity : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 42,
                      color: AppColors.textMuted.withOpacity(0.6),
                    ),
                  ),
                  if (isLowStock)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.warningAmber.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'LOW STOCK',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warningAmber,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${product.price.toStringAsFixed(0)} ETB',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slateDark,
                        ),
                      ),
                    ),
                    Text(
                      'Stock: ${product.stockQuantity}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isLowStock ? AppColors.warningAmber : AppColors.textMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (inCartQty > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandLimeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.brandLimeBorder),
                  ),
                  child: Text(
                    '$inCartQty in cart',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.brandLimeDeep),
                  ),
                )
              else
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<CartProvider>().addProduct(product);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text('${product.name} added to cart')),
                            ],
                          ),
                          duration: const Duration(milliseconds: 700),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 85),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.brandLime,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.brandLimeGlow,
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, size: 20, color: AppColors.brandLimeDarkText),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}