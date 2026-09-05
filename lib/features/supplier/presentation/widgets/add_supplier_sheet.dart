import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../category/provider/category_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/supplier.dart';
import '../../provider/supplier_provider.dart';

class AddSupplierSheet extends StatefulWidget {
  final Supplier? supplierToEdit;

  const AddSupplierSheet({super.key, this.supplierToEdit});

  static Future<void> show(BuildContext context, {Supplier? supplierToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddSupplierSheet(supplierToEdit: supplierToEdit),
    );
  }

  @override
  State<AddSupplierSheet> createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends State<AddSupplierSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _productController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String _selectedCategory = 'General';
  String _selectedType = 'Taking Return';

  @override
  void initState() {
    super.initState();
    final s = widget.supplierToEdit;
    _nameController = TextEditingController(text: s?.name ?? '');
    _productController = TextEditingController(text: s?.product ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _selectedCategory = s?.category ?? 'General';
    _selectedType = s?.type ?? 'Taking Return';

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
    _productController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final supplierProvider = context.read<SupplierProvider>();

    final shopId = shop.selectedShop?.id ?? 'default-shop';
    final token = auth.token;

    final supplier = Supplier(
      id: widget.supplierToEdit?.id ?? 'sup-${DateTime.now().millisecondsSinceEpoch}',
      shopId: shopId,
      name: _nameController.text.trim(),
      product: _productController.text.trim().isNotEmpty ? _productController.text.trim() : 'Assorted Goods',
      category: _selectedCategory,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : 'contact@supplier.com',
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '09112 34567',
      type: _selectedType,
      onTheWay: widget.supplierToEdit?.onTheWay ?? 0,
    );

    bool ok;
    if (widget.supplierToEdit != null) {
      ok = await supplierProvider.updateSupplier(
        shopId: shopId,
        token: token,
        supplier: supplier,
      );
    } else {
      ok = await supplierProvider.addSupplier(
        shopId: shopId,
        token: token,
        supplier: supplier,
      );
    }

    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.supplierToEdit != null
                  ? 'Supplier updated successfully'
                  : 'Supplier added successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(supplierProvider.errorMessage ?? 'Failed to save supplier'),
            backgroundColor: AppColors.errorRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplierToEdit != null;
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories.map((c) => c.name).toList();
    if (!categories.contains('General')) categories.insert(0, 'General');
    if (!categories.contains(_selectedCategory)) categories.add(_selectedCategory);

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

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Supplier' : 'New Supplier Vendor',
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

                // Form fields
                Expanded(
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // Supplier Name
                      _buildField(
                        label: 'Supplier / Company Name',
                        hint: 'Enter supplier name (e.g. Fresh Farms)',
                        controller: _nameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter supplier name' : null,
                      ),
                      const SizedBox(height: 14),

                      // Product supplied
                      _buildField(
                        label: 'Product Supplied',
                        hint: 'Enter product name (e.g. Tomato)',
                        controller: _productController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter supplied product' : null,
                      ),
                      const SizedBox(height: 14),

                      // Category Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                            decoration: AppDecorations.inputDecoration(hintText: 'Select Category'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Phone Number
                      _buildField(
                        label: 'Phone Number',
                        hint: 'Enter phone number (e.g. 09112 34567)',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter phone number' : null,
                      ),
                      const SizedBox(height: 14),

                      // Email
                      _buildField(
                        label: 'Email (Optional)',
                        hint: 'Enter email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // Type / Return policy
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Return Policy',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            items: ['Taking Return', 'Not Taking Return'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedType = val);
                            },
                            decoration: AppDecorations.inputDecoration(hintText: 'Select Policy'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Bottom Action Buttons
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
                            backgroundColor: AppColors.brandLime,
                            foregroundColor: AppColors.brandLimeDarkText,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditing ? 'Save Changes' : 'Save Supplier',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
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
