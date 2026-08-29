import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/customer_model.dart';
import '../../provider/customer_provider.dart';

class AddCustomerSheet extends StatefulWidget {
  final Customer? customerToEdit;

  const AddCustomerSheet({super.key, this.customerToEdit});

  static Future<void> show(BuildContext context, {Customer? customerToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddCustomerSheet(customerToEdit: customerToEdit),
    );
  }

  @override
  State<AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _creditLimitController;

  @override
  void initState() {
    super.initState();
    final c = widget.customerToEdit;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _creditLimitController = TextEditingController(text: c != null ? c.creditLimit.toStringAsFixed(0) : '5000');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final customerProvider = context.read<CustomerProvider>();

    final isEditing = widget.customerToEdit != null;
    final limit = double.tryParse(_creditLimitController.text.trim()) ?? 5000.0;
    final randomCode = 'Cust - ${(100 + DateTime.now().millisecondsSinceEpoch % 900)}';

    final customer = Customer(
      id: widget.customerToEdit?.id ?? 'cust-${DateTime.now().millisecondsSinceEpoch}',
      customerCode: widget.customerToEdit?.customerCode ?? randomCode,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : 'Addis Ababa',
      totalDebt: widget.customerToEdit?.totalDebt ?? 0.0,
      creditLimit: limit,
      daysOverdue: widget.customerToEdit?.daysOverdue ?? 0,
      registeredDate: widget.customerToEdit?.registeredDate ?? '18/07/2025',
      status: widget.customerToEdit?.status ?? 'Active',
      transactions: widget.customerToEdit?.transactions ?? const [],
      sales: widget.customerToEdit?.sales ?? const [],
      debts: widget.customerToEdit?.debts ?? const [],
    );

    bool ok;
    if (isEditing) {
      ok = await customerProvider.updateCustomer(
        shopId: shop.selectedShop?.id ?? 'default-shop',
        token: auth.token,
        customer: customer,
      );
    } else {
      ok = await customerProvider.createCustomer(
        shopId: shop.selectedShop?.id ?? 'default-shop',
        token: auth.token,
        customer: customer,
      );
    }

    if (mounted && ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Customer profile updated' : 'Customer created successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customerToEdit != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                        isEditing ? 'Edit Customer' : 'New Customer Account',
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
                      _buildField(
                        label: 'Customer Name',
                        hint: 'Enter customer name (e.g. Ahmed Hassen)',
                        controller: _nameController,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter customer name' : null,
                      ),
                      const SizedBox(height: 14),

                      _buildField(
                        label: 'Phone Number',
                        hint: 'Enter phone number (e.g. +251912345678)',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter phone number' : null,
                      ),
                      const SizedBox(height: 14),

                      _buildField(
                        label: 'Email (Optional)',
                        hint: 'Enter email (e.g. john@example.com)',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      _buildField(
                        label: 'Address / Location',
                        hint: 'Enter address (e.g. Bole, Addis Ababa)',
                        controller: _addressController,
                      ),
                      const SizedBox(height: 14),

                      _buildField(
                        label: 'Credit Limit (ETB)',
                        hint: 'Enter credit limit (e.g. 5000)',
                        controller: _creditLimitController,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter credit limit' : null,
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
                            backgroundColor: AppColors.slateDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditing ? 'Save Changes' : 'Create Customer',
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
