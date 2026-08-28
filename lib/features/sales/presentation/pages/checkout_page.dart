import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../cart/provider/cart_provider.dart';
import '../../../customer/models/customer_model.dart';
import '../../../customer/provider/customer_provider.dart';
import '../../../orders/models/sale_model.dart';
import '../../../orders/provider/orders_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../../shop/provider/shop_provider.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String selectedPaymentMethod = 'Cash';
  Customer? selectedCustomer;
  bool isCredit = false;
  final TextEditingController _discountController = TextEditingController(text: '0');
  bool _isProcessing = false;

  final List<String> paymentMethods = [
    'Cash',
    'Card',
    'Mobile Money',
  ];

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  double get discountAmount => double.tryParse(_discountController.text.trim()) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final shop = context.watch<ShopProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final taxRate = shop.selectedShop?.taxRate ?? 0.0;

    final subtotal = cart.subtotal;
    final discount = discountAmount;
    final discountedSubtotal = (subtotal - discount).clamp(0.0, double.infinity);
    final taxAmount = (discountedSubtotal * (taxRate / 100));
    final totalAmount = (discountedSubtotal + taxAmount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF20252B),
          ),
        ),
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Selection (Optional / Required for Credit)
                        const Text(
                          'Customer (Optional)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20252B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Customer?>(
                              isExpanded: true,
                              value: selectedCustomer,
                              hint: const Text('Walk-in Customer (None)', style: TextStyle(fontSize: 14)),
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
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Checkbox(
                                value: isCredit,
                                activeColor: const Color(0xFF20252B),
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

                        // Order Items Summary
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20252B),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              ...cart.items.map(
                                (item) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF20252B),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${item.quantity} × ${item.product.price.toStringAsFixed(0)} ETB',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${item.total.toStringAsFixed(0)} ETB',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF20252B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const Divider(color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 6),

                              // Subtotal
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                  Text('${subtotal.toStringAsFixed(2)} ETB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Discount Field
                              Row(
                                children: [
                                  const Text('Discount (ETB): ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                  const Spacer(),
                                  SizedBox(
                                    width: 90,
                                    height: 32,
                                    child: TextField(
                                      controller: _discountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Tax Rate
                              if (taxRate > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Tax (${taxRate.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                    Text('${taxAmount.toStringAsFixed(2)} ETB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],

                              const Divider(color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 6),

                              // Total
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF20252B),
                                    ),
                                  ),
                                  Text(
                                    '${totalAmount.toStringAsFixed(2)} ETB',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Payment Methods
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20252B),
                          ),
                        ),
                        const SizedBox(height: 10),

                        ...paymentMethods.map(
                          (method) {
                            final isSelected = selectedPaymentMethod == method;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(() => selectedPaymentMethod = method),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF20252B) : const Color(0xFFE2E8F0),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        method == 'Cash'
                                            ? Icons.payments_outlined
                                            : method == 'Card'
                                                ? Icons.credit_card_outlined
                                                : Icons.phone_android_outlined,
                                        color: isSelected ? const Color(0xFF20252B) : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          method,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF20252B),
                                          ),
                                        ),
                                      ),
                                      Radio<String>(
                                        value: method,
                                        groupValue: selectedPaymentMethod,
                                        onChanged: (v) {
                                          if (v != null) setState(() => selectedPaymentMethod = v);
                                        },
                                        activeColor: const Color(0xFF20252B),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom CTA Button
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    color: Colors.white,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : () => _executeSale(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF20252B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Complete Sale (${totalAmount.toStringAsFixed(0)} ETB)',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

    final backendPaymentMethod = selectedPaymentMethod == 'Cash'
        ? 'CASH'
        : (selectedPaymentMethod == 'Card' ? 'CARD' : 'MOBILE_MONEY');

    final result = await ordersProvider.processSale(
      shopId: shopId,
      token: token,
      customerId: selectedCustomer?.id,
      items: items,
      discountAmount: discountAmount,
      paymentMethod: backendPaymentMethod,
      isCredit: isCredit,
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

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
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Column(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 48),
              SizedBox(height: 10),
              Text(
                'Sale Completed!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Receipt #${sale.id.length > 8 ? sale.id.substring(0, 8) : sale.id}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Paid:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${sale.totalAmount.toStringAsFixed(2)} ETB', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Method:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(sale.paymentMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (sale.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          Text('-${sale.discountAmount.toStringAsFixed(2)} ETB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20252B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}