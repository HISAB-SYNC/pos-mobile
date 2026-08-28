import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../category/provider/category_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/product.dart';
import '../../provider/product_provider.dart';

class AddProductSheet extends StatefulWidget {
  final Product? productToEdit;

  const AddProductSheet({super.key, this.productToEdit});

  static Future<void> show(BuildContext context, {Product? productToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddProductSheet(productToEdit: productToEdit),
    );
  }

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _categoryController;
  late final TextEditingController _buyingPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _locationController;
  late final TextEditingController _expiryDateController;
  late final TextEditingController _supplierNameController;
  late final TextEditingController _supplierContactController;
  late final TextEditingController _thresholdController;

  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _categoryController = TextEditingController(text: p?.categoryName ?? '');
    _selectedCategoryId = p?.categoryId;
    _buyingPriceController = TextEditingController(text: p?.buyingPrice != null && p!.buyingPrice > 0 ? p.buyingPrice.toStringAsFixed(0) : '');
    _sellingPriceController = TextEditingController(text: p?.price != null && p!.price > 0 ? p.price.toStringAsFixed(0) : '');
    _quantityController = TextEditingController(text: p?.stockQuantity != null ? p!.stockQuantity.toString() : '');
    _locationController = TextEditingController(text: p?.location ?? 'Main Store');
    _expiryDateController = TextEditingController(text: p?.expiryDate ?? '');
    _supplierNameController = TextEditingController(text: p?.supplierName ?? '');
    _supplierContactController = TextEditingController(text: p?.supplierContact ?? '');
    _thresholdController = TextEditingController(text: p?.lowStockThreshold != null ? p!.lowStockThreshold.toString() : '10');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final shop = context.read<ShopProvider>();
      final shopId = shop.selectedShop?.id ?? '';
      final token = auth.token;
      if (shopId.isNotEmpty && token != null) {
        context.read<CategoryProvider>().loadCategories(shopId: shopId, token: token);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _expiryDateController.dispose();
    _supplierNameController.dispose();
    _supplierContactController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final productProvider = context.read<ProductProvider>();

    final shopId = shop.selectedShop?.id ?? 'default-shop';
    final token = auth.token;

    final buyingPrice = double.tryParse(_buyingPriceController.text.trim()) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final threshold = int.tryParse(_thresholdController.text.trim()) ?? 10;

    final categoryProvider = context.read<CategoryProvider>();
    final categoryName = _categoryController.text.trim().isNotEmpty
        ? _categoryController.text.trim()
        : 'General';

    String? catId = _selectedCategoryId;
    if (catId == null || catId.isEmpty) {
      final match = categoryProvider.categories.where(
        (c) => c.name.trim().toLowerCase() == categoryName.trim().toLowerCase(),
      );
      if (match.isNotEmpty) {
        catId = match.first.id;
      }
    }

    final product = Product(
      id: widget.productToEdit?.id ?? 'prod-${DateTime.now().millisecondsSinceEpoch}',
      shopId: shopId,
      name: _nameController.text.trim(),
      sku: _skuController.text.trim().isNotEmpty
          ? _skuController.text.trim()
          : 'SKU-${DateTime.now().millisecondsSinceEpoch % 1000000}',
      categoryName: categoryName,
      categoryId: catId,
      buyingPrice: buyingPrice,
      price: sellingPrice,
      stockQuantity: quantity,
      openingStock: widget.productToEdit?.openingStock ?? quantity,
      onTheWay: widget.productToEdit?.onTheWay ?? 0,
      lowStockThreshold: threshold,
      unit: 'Units',
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : 'Main Store',
      expiryDate: _expiryDateController.text.trim(),
      supplierName: _supplierNameController.text.trim(),
      supplierContact: _supplierContactController.text.trim(),
      status: quantity <= 0 ? 'Out of Stock' : (quantity <= threshold ? 'Low Stock' : 'Available'),
    );

    bool ok;
    if (widget.productToEdit != null) {
      ok = await productProvider.updateProduct(
        shopId: shopId,
        token: token,
        product: product,
      );
    } else {
      ok = await productProvider.addProduct(
        shopId: shopId,
        token: token,
        product: product,
      );
    }

    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productToEdit != null
                  ? 'Product updated successfully'
                  : 'Product added successfully',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        final err = productProvider.errorMessage ?? 'Failed to save product';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Category name (e.g. Beverages)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogCtx);

              final auth = context.read<AuthProvider>();
              final shop = context.read<ShopProvider>();
              final shopId = shop.selectedShop?.id ?? '';
              final token = auth.token ?? '';

              if (shopId.isNotEmpty && token.isNotEmpty) {
                await context.read<CategoryProvider>().createCategory(
                  shopId: shopId,
                  name: name,
                  token: token,
                );
              }
              setState(() {
                _categoryController.text = name;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF161B20),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Sheet Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Product' : 'New Product',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF161B20),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Form fields list (fully scrollable with keyboard)
                Expanded(
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      _buildField(
                        label: 'Product Name',
                        hint: 'Enter product name (e.g. Coca Cola)',
                        controller: _nameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter product name' : null,
                      ),
                      const SizedBox(height: 14),

                      _buildField(
                        label: 'Product ID / SKU',
                        hint: 'Enter product ID (e.g. 456567)',
                        controller: _skuController,
                      ),
                      const SizedBox(height: 14),

                      // Category Selector & Scrollable Chips Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Category',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _showAddCategoryDialog,
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('+ Add Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF2563EB),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Scrollable categories chips
                          if (categories.isNotEmpty) ...[
                            SizedBox(
                              height: 38,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final cat = categories[index];
                                  final isSelected = _categoryController.text.trim().toLowerCase() == cat.name.trim().toLowerCase();

                                  return ChoiceChip(
                                    label: Text(cat.name),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _categoryController.text = cat.name;
                                          _selectedCategoryId = cat.id;
                                        }
                                      });
                                    },
                                    selectedColor: const Color(0xFF161B20),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : const Color(0xFF475569),
                                    ),
                                    backgroundColor: const Color(0xFFF8FAFC),
                                    side: BorderSide(
                                      color: isSelected ? const Color(0xFF161B20) : const Color(0xFFCBD5E1),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          TextFormField(
                            controller: _categoryController,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Please select or enter category' : null,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF161B20)),
                            decoration: InputDecoration(
                              hintText: 'Select above or enter category name',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Buying Price (ETB)',
                              hint: 'e.g. 50',
                              controller: _buyingPriceController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              label: 'Selling Price (ETB)',
                              hint: 'e.g. 75',
                              controller: _sellingPriceController,
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Quantity (In-Stock)',
                              hint: 'e.g. 24',
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              label: 'Low Stock Alert',
                              hint: 'e.g. 10',
                              controller: _thresholdController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildField(
                        label: 'Store Location',
                        hint: 'Enter Store Location (e.g. Main Store)',
                        controller: _locationController,
                      ),
                      const SizedBox(height: 14),

                      _buildField(
                        label: 'Expiry Date',
                        hint: 'Enter Expiry Date (e.g. 13/08/25)',
                        controller: _expiryDateController,
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Supplier Name',
                              hint: 'e.g. Fresh Farms',
                              controller: _supplierNameController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              label: 'Supplier Contact',
                              hint: 'e.g. 0912345678',
                              controller: _supplierContactController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Discard',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF161B20), // Black button matching design
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditing ? 'Save Changes' : 'Add Product',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF161B20)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }
}
