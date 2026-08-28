import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

      return matchesSearch && matchesCategory;
    }).toList();
  }

  bool isLowStock(Product product) {
    return product.stockQuantity <= product.lowStockThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final products = _getFilteredProducts(productProvider.allProducts);

    final catSet = <String>{'All'};
    for (final c in categoryProvider.categories) {
      if (c.name.trim().isNotEmpty) catSet.add(c.name.trim());
    }
    for (final p in productProvider.allProducts) {
      if (p.categoryName.trim().isNotEmpty) catSet.add(p.categoryName.trim());
    }
    final categories = catSet.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF20252B),
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              // Cart will be implemented next.
            },
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFF20252B),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              12,
            ),
            child: TextField(
              controller: _searchController,

              onChanged: (_) {
                setState(() {});
              },

              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),

                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF64748B),
                ),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Categories
          SizedBox(
            height: 45,

            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              scrollDirection: Axis.horizontal,

              itemCount: categories.length,

              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),

              itemBuilder: (context, index) {
                final category = categories[index];

                final isSelected =
                    selectedCategory == category;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF20252B)
                          : Colors.white,

                      borderRadius: BorderRadius.circular(20),

                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF20252B)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),

                    child: Text(
                      category,

                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Product list
          Expanded(
            child: products.isEmpty
                ? const Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      30,
                    ),

                    itemCount: products.length,

                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),

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

      // Cart button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            15,
          ),

          child: SizedBox(
            height: 52,

            child: ElevatedButton.icon(
              onPressed: () {
  Navigator.pushNamed(context, '/cart');
},

              icon: const Icon(
                Icons.shopping_cart_outlined,
                size: 20,
              ),

              label: const Text(
                'View Cart',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20252B),
                foregroundColor: Colors.white,

                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),

      child: Row(
        children: [
          // Product image placeholder
          Container(
            width: 62,
            height: 62,

            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),

            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF64748B),
              size: 28,
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

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF20252B),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'SKU: ${product.sku}',

                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(0)} ETB',

                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF20252B),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Text(
                      'Stock: ${product.stockQuantity}',

                      style: TextStyle(
                        fontSize: 11,
                        color: isLowStock
                            ? const Color(0xFFD97706)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                if (isLowStock) ...[
                  const SizedBox(height: 5),

                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Color(0xFFD97706),
                      ),

                      SizedBox(width: 4),

                      Text(
                        'Low stock',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Add button
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: const Color(0xFF20252B),
              borderRadius: BorderRadius.circular(10),
            ),

            child: IconButton(
              padding: EdgeInsets.zero,

              onPressed: () {
  context.read<CartProvider>().addProduct(product);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${product.name} added to cart',
      ),
      duration: const Duration(seconds: 1),
    ),
  );
},

              icon: const Icon(
                Icons.add,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}