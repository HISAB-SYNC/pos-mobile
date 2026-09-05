import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../provider/shop_provider.dart';

class CreateShopSheet extends StatefulWidget {
  const CreateShopSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreateShopSheet(),
    );
  }

  @override
  State<CreateShopSheet> createState() => _CreateShopSheetState();
}

class _CreateShopSheetState extends State<CreateShopSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessTypeController = TextEditingController(text: 'Retail');
  final _addressController = TextEditingController();
  final _taxRateController = TextEditingController(text: '0.0');
  String _selectedCurrency = 'ETB';
  bool _isSubmitting = false;

  final List<String> _currencies = ['ETB', 'USD', 'EUR', 'GBP', 'KES'];
  final List<String> _businessTypes = ['Retail', 'Supermarket', 'Boutique', 'Pharmacy', 'Restaurant', 'Electronics', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _businessTypeController.dispose();
    _addressController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final shopProvider = context.read<ShopProvider>();
    final token = auth.token ?? '';

    final taxRate = double.tryParse(_taxRateController.text.trim()) ?? 0.0;

    final success = await shopProvider.createShop(
      token: token,
      name: _nameController.text.trim(),
      businessType: _businessTypeController.text.trim(),
      address: _addressController.text.trim(),
      taxRate: taxRate,
      currency: _selectedCurrency,
      language: 'en',
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shop "${_nameController.text.trim()}" created successfully!'),
          backgroundColor: AppColors.successEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = shopProvider.errorMessage ?? 'Failed to create shop';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.errorRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add New Shop', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('Provision a new store branch for your business', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textMedium),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shop Name
                        _buildFieldLabel('Shop Name *'),
                        TextFormField(
                          controller: _nameController,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter shop name' : null,
                          style: const TextStyle(fontSize: 13.5, color: AppColors.slateDark),
                          decoration: InputDecoration(
                            hintText: 'e.g. Apex Electronics - Bole Branch',
                            prefixIcon: const Icon(Icons.store_mall_directory_outlined, size: 20, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Business Type & Currency in Row
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Business Type'),
                                  DropdownButtonFormField<String>(
                                    value: _businessTypes.contains(_businessTypeController.text) ? _businessTypeController.text : 'Retail',
                                    items: _businessTypes
                                        .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _businessTypeController.text = val);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppColors.inputBackground,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Currency'),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCurrency,
                                    items: _currencies
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedCurrency = val);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppColors.inputBackground,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Store Address
                        _buildFieldLabel('Physical Address *'),
                        TextFormField(
                          controller: _addressController,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter physical address' : null,
                          style: const TextStyle(fontSize: 13.5, color: AppColors.slateDark),
                          decoration: InputDecoration(
                            hintText: 'e.g. Bole Medhanialem, Addis Ababa',
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tax Rate
                        _buildFieldLabel('Tax Rate (%)'),
                        TextFormField(
                          controller: _taxRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 13.5, color: AppColors.slateDark),
                          decoration: InputDecoration(
                            hintText: '0.0',
                            helperText: 'Saved locally on device. Set to 0 to disable tax.',
                            prefixIcon: const Icon(Icons.percent_rounded, size: 18, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandLime,
                              foregroundColor: AppColors.brandLimeDarkText,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandLimeDarkText))
                                : const Text('Create Shop', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
    );
  }
}
