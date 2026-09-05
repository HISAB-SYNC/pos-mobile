import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../cart/provider/cart_provider.dart';
import '../../../customer/models/customer_model.dart';
import '../../../customer/provider/customer_provider.dart';
import '../../../orders/models/sale_model.dart';
import '../../../orders/provider/orders_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../../../core/services/receipt_pdf_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String selectedPaymentMethod = 'CASH';
  Customer? selectedCustomer;
  bool isCredit = false;
  final TextEditingController _discountController = TextEditingController(text: '0');
  late final TextEditingController _taxRateController;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'CASH',
      'label': 'Cash',
      'icon': Icons.payments_rounded,
      'color': AppColors.successEmerald,
    },
    {
      'id': 'CARD',
      'label': 'Card',
      'icon': Icons.credit_card_rounded,
      'color': AppColors.primaryBlue,
    },
    {
      'id': 'MOBILE',
      'label': 'TeleBirr',
      'icon': Icons.phone_android_rounded,
      'color': const Color(0xFF7C3AED),
    },
  ];

  @override
  void initState() {
    super.initState();
    final shopTax = context.read<ShopProvider>().selectedShop?.taxRate ?? 0.0;
    _taxRateController = TextEditingController(text: shopTax > 0 ? shopTax.toStringAsFixed(1) : '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final shop = context.read<ShopProvider>();
      final shopId = shop.selectedShop?.id ?? '';
      final token = auth.token;
      if (shopId.isNotEmpty) {
        context.read<CustomerProvider>().loadCustomers(shopId: shopId, token: token);
      }
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  double get discountAmount => double.tryParse(_discountController.text.trim()) ?? 0.0;
  double get taxRate => double.tryParse(_taxRateController.text.trim()) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final effectiveTaxRate = taxRate;

    final subtotal = cart.subtotal;
    final discount = discountAmount;
    final discountedSubtotal = (subtotal - discount).clamp(0.0, double.infinity);
    final taxAmount = (discountedSubtotal * (effectiveTaxRate / 100));
    final totalAmount = (discountedSubtotal + taxAmount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Charge & Checkout',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Text(
                'Your cart is empty',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Hero Total Amount Due Card (Inspiration Card)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.brandLimeBg, Color(0xFFFCFEF8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.brandLimeBorder,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1AC0E763),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount Due',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandLimeDeep,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.brandLimeBorder.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      '${cart.itemCount} Items',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brandLimeDeep,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${totalAmount.toStringAsFixed(2)} ETB',
                                style: AppTypography.displayMedium.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (discount > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Includes ${discount.toStringAsFixed(0)} ETB discount',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. Customer Selection (Optional / Required for Credit)
                        Text(
                          'Customer Details',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: AppDecorations.cardDecoration,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Customer?>(
                              isExpanded: true,
                              value: selectedCustomer,
                              hint: const Text('Walk-in Customer (None)', style: TextStyle(fontSize: 13.5)),
                              items: [
                                const DropdownMenuItem<Customer?>(
                                  value: null,
                                  child: Text('Walk-in Customer (None)'),
                                ),
                                ...customerProvider.allCustomers.map((c) => DropdownMenuItem<Customer?>(
                                      value: c,
                                      child: Text('${c.name} (${c.phone})'),
                                    )),
                              ],
                              onChanged: (c) {
                                setState(() {
                                  selectedCustomer = c;
                                  if (c == null) isCredit = false;
                                });
                              },
                            ),
                          ),
                        ),

                        if (selectedCustomer != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: isCredit,
                                activeColor: AppColors.slateDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setState(() {
                                    isCredit = val ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Credit Sale (Record to Customer Debt)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),

                        // 3. Order Breakdown Card
                        Text(
                          'Order Breakdown',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppDecorations.cardDecoration,
                          child: Column(
                            children: [
                              ...cart.items.map(
                                (item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.name,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              Text(
                                                '${item.quantity} × ${item.product.price.toStringAsFixed(0)} ETB',
                                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${item.total.toStringAsFixed(0)} ETB',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1, color: AppColors.borderLight),
                              const SizedBox(height: 10),

                              // Subtotal
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                                  Text('${subtotal.toStringAsFixed(2)} ETB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Discount Field
                              Row(
                                children: [
                                  const Text('Discount (ETB)', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                                  const Spacer(),
                                  SizedBox(
                                    width: 100,
                                    height: 36,
                                    child: TextField(
                                      controller: _discountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        filled: true,
                                        fillColor: AppColors.inputBackground,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Tax (%) Input
                              Row(
                                children: [
                                  const Text('Tax (%)', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                                  const Spacer(),
                                  SizedBox(
                                    width: 100,
                                    height: 36,
                                    child: TextField(
                                      controller: _taxRateController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      decoration: InputDecoration(
                                        hintText: '0.0',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        filled: true,
                                        fillColor: AppColors.inputBackground,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),

                              if (effectiveTaxRate > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Tax Amount (${effectiveTaxRate.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                                    Text('+${taxAmount.toStringAsFixed(2)} ETB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 4. Payment Method Selection (Inspiration cards)
                        Text(
                          'Select Payment Method',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),

                        ...paymentMethods.map((method) {
                          final isSelected = selectedPaymentMethod == method['id'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => selectedPaymentMethod = method['id']);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.brandLimeBg : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppColors.brandLimeDark : AppColors.borderLight,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x1CC0E763),
                                              blurRadius: 10,
                                              offset: Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: (method['color'] as Color).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          method['icon'] as IconData,
                                          color: method['color'] as Color,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          method['label'] as String,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.brandLimeDeep,
                                          size: 22,
                                        )
                                      else
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.borderMedium, width: 1.5),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Bottom CTA Button
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: AppColors.borderLight.withOpacity(0.8)),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : () => _executeSale(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandLime,
                          foregroundColor: AppColors.brandLimeDarkText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          shadowColor: AppColors.brandLime,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: AppColors.brandLimeDarkText, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Complete Charge (${totalAmount.toStringAsFixed(0)} ETB)',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _executeSale(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final cart = context.read<CartProvider>();
    final ordersProvider = context.read<OrdersProvider>();
    final productProvider = context.read<ProductProvider>();

    final shopId = shop.selectedShop?.id ?? '';
    final token = auth.token;

    if (shopId.isEmpty || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No active shop or auth token found')),
      );
      return;
    }

    if (isCredit && selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer for credit sales')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final items = cart.items
        .map((i) => {
              'productId': i.product.id,
              'quantity': i.quantity,
            })
        .toList();

    final backendPaymentMethod = selectedPaymentMethod;

    final result = await ordersProvider.processSale(
      shopId: shopId,
      token: token,
      customerId: selectedCustomer?.id,
      items: items,
      discountAmount: discountAmount,
      paymentMethod: backendPaymentMethod,
      isCredit: isCredit,
    );

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (result['success'] == true && result['data'] is Sale) {
      final sale = result['data'] as Sale;
      cart.clearCart();
      productProvider.loadProducts(shopId: shopId, token: token);

      _showReceiptDialog(context, sale);
    } else {
      final errorMsg = result['error']?.toString() ?? 'Failed to complete sale';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.errorRose),
              SizedBox(width: 8),
              Text('Sale Failed'),
            ],
          ),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showReceiptDialog(BuildContext context, Sale sale) {
    final shop = context.read<ShopProvider>().selectedShop;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Inspiration Payment Success Icon Hero
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successEmerald.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.successEmerald.withOpacity(0.25),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: AppColors.successEmerald,
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Success!',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Payment successfully processed and receipt recorded.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 20),

              // Thermal Receipt Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.softCardDecoration(
                  backgroundColor: AppColors.inputBackground,
                  borderRadius: 16,
                ),
                child: Column(
                  children: [
                    Text(
                      shop?.name.toUpperCase() ?? 'ANDALUS POS',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.slateDark),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Receipt #${sale.id.length > 8 ? sale.id.substring(0, 8) : sale.id}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderMedium),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount Paid', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
                        Text('${sale.totalAmount.toStringAsFixed(2)} ETB', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.successEmerald)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Method', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(sale.paymentMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      ],
                    ),
                    if (sale.discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount Applied', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text('-${sale.discountAmount.toStringAsFixed(2)} ETB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warningAmber)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final auth = context.read<AuthProvider>();
                        await ReceiptPdfService.printOrDownloadReceipt(
                          sale: sale,
                          shop: shop,
                          cashierName: auth.currentUser?.name,
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('Download / Print'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.borderMedium),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(sheetCtx); // Close modal
                        Navigator.pop(context); // Back to POS
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandLime,
                        foregroundColor: AppColors.brandLimeDarkText,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('New Sale', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}