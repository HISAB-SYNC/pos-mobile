import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
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
    HapticFeedback.lightImpact();

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
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        final err = productProvider.errorMessage ?? 'Failed to save product';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.errorRose,
            behavior: SnackBarBehavior.floating,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Add Category', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: AppDecorations.inputDecoration(
            hintText: 'Category name (e.g. Beverages)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMedium)),
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
              backgroundColor: AppColors.slateDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderMedium,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Sheet Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Product' : 'New Product Details',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),

                // Form fields list
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
                              Text(
                                'Category',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _showAddCategoryDialog,
                                icon: const Icon(Icons.add_rounded, size: 14),
                                label: const Text('+ Add Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
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
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        if (selected) {
                                          _categoryController.text = cat.name;
                                          _selectedCategoryId = cat.id;
                                        }
                                      });
                                    },
                                    selectedColor: AppColors.slateDark,
                                    labelStyle: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? Colors.white : AppColors.textDark,
                                    ),
                                    backgroundColor: AppColors.inputBackground,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isSelected ? AppColors.slateDark : AppColors.borderLight,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          TextFormField(
                            controller: _categoryController,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Please select or enter category' : null,
                            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                            decoration: AppDecorations.inputDecoration(
                              hintText: 'Select above or enter category name',
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
                    border: Border(top: BorderSide(color: AppColors.borderLight)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Discard',
                            style: TextStyle(
                              color: AppColors.textMedium,
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
                            backgroundColor: AppColors.slateDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          decoration: AppDecorations.inputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
