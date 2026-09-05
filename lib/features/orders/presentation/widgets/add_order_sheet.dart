import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../category/provider/category_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/order_model.dart';
import '../../provider/orders_provider.dart';

class AddOrderSheet extends StatefulWidget {
  const AddOrderSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddOrderSheet(),
    );
  }

  @override
  State<AddOrderSheet> createState() => _AddOrderSheetState();
}

class _AddOrderSheetState extends State<AddOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _productIdController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController(text: '25/12/23');
  String _selectedCategory = 'General';
  bool _notifyOnDelivery = true;

  @override
  void initState() {
    super.initState();
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
    _productIdController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = '${picked.day}/${picked.month}/${picked.year.toString().substring(2)}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final ordersProvider = context.read<OrdersProvider>();

    final price = double.tryParse(_priceController.text.trim()) ?? 50.0;
    final randomId = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();

    final order = ShopOrder(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      orderId: randomId,
      productName: _nameController.text.trim(),
      productId: _productIdController.text.trim().isNotEmpty ? _productIdController.text.trim() : 'SKU-$randomId',
      category: _selectedCategory,
      price: price,
      quantity: _quantityController.text.trim(),
      expectedDelivery: _dateController.text.trim(),
      status: 'Confirmed',
      notifyOnDelivery: _notifyOnDelivery,
    );

    final ok = await ordersProvider.createOrder(
      shopId: shop.selectedShop?.id ?? 'default-shop',
      token: auth.token,
      order: order,
    );

    if (mounted && ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories.map((c) => c.name).toList();
    if (!categories.contains('General')) categories.insert(0, 'General');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                        'New Purchase Order',
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
                      // Product Name
                      _buildField(
                        label: 'Product Name',
                        hint: 'Enter product name (e.g. Coca Cola)',
                        controller: _nameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter product name' : null,
                      ),
                      const SizedBox(height: 14),

                      // Product ID
                      _buildField(
                        label: 'Product SKU / Code',
                        hint: 'Enter SKU (e.g. 456567)',
                        controller: _productIdController,
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

                      // Quantity & Price
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Quantity / Pack',
                              hint: 'e.g. 10 Packets',
                              controller: _quantityController,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              label: 'Total Value (ETB)',
                              hint: 'e.g. 250',
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Delivery Date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expected Delivery Date',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _dateController,
                                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                                decoration: AppDecorations.inputDecoration(
                                  hintText: 'Select Delivery Date',
                                  suffixIcon: const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.textMuted),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notify switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: AppDecorations.cardDecoration,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notify on Delivery Arrival',
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Switch(
                              value: _notifyOnDelivery,
                              activeColor: AppColors.primaryBlue,
                              onChanged: (val) => setState(() => _notifyOnDelivery = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Bottom Actions
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
                          child: const Text(
                            'Place Order',
                            style: TextStyle(
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
