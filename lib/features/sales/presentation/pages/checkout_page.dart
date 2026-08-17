import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../cart/provider/cart_provider.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String selectedPaymentMethod = 'Cash';

  final List<String> paymentMethods = [
    'Cash',
    'Card',
    'Mobile Money',
  ];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

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
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
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
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20252B),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),

                          child: Column(
                            children: [
                              ...cart.items.map(
                                (item) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(
                                      bottom: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.name,
                                                style:
                                                    const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: Color(
                                                    0xFF20252B,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              Text(
                                                '${item.quantity} × ${item.product.price.toStringAsFixed(0)} ETB',
                                                style:
                                                    const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(
                                                    0xFF64748B,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Text(
                                          '${item.total.toStringAsFixed(0)} ETB',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: Color(
                                              0xFF20252B,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const Divider(
                                color: Color(0xFFE2E8F0),
                              ),

                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: Color(
                                        0xFF20252B,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    '${cart.subtotal.toStringAsFixed(0)} ETB',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: Color(
                                        0xFF20252B,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20252B),
                          ),
                        ),

                        const SizedBox(height: 14),

                        ...paymentMethods.map(
                          (method) {
                            final isSelected =
                                selectedPaymentMethod ==
                                    method;

                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 10,
                              ),
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(14),
                                onTap: () {
                                  setState(() {
                                    selectedPaymentMethod =
                                        method;
                                  });
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(
                                      14,
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(
                                              0xFF20252B,
                                            )
                                          : const Color(
                                              0xFFE2E8F0,
                                            ),
                                      width:
                                          isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        method == 'Cash'
                                            ? Icons
                                                .payments_outlined
                                            : method == 'Card'
                                                ? Icons
                                                    .credit_card_outlined
                                                : Icons
                                                    .phone_android_outlined,
                                        color: isSelected
                                            ? const Color(
                                                0xFF20252B,
                                              )
                                            : const Color(
                                                0xFF64748B,
                                              ),
                                      ),

                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Text(
                                          method,
                                          style:
                                              const TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: Color(
                                              0xFF20252B,
                                            ),
                                          ),
                                        ),
                                      ),

                                      Radio<String>(
                                        value: method,
                                        groupValue:
                                            selectedPaymentMethod,
                                        onChanged: (value) {
                                          if (value == null) {
                                            return;
                                          }

                                          setState(() {
                                            selectedPaymentMethod =
                                                value;
                                          });
                                        },
                                        activeColor:
                                            const Color(
                                          0xFF20252B,
                                        ),
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

                // Confirm sale
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      16,
                    ),
                    color: Colors.white,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          _confirmSale(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF20252B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm Sale',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmSale(BuildContext context) {
    final cart = context.read<CartProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Sale'),
          content: Text(
            'Complete this sale using $selectedPaymentMethod?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                cart.clearCart();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sale completed successfully',
                    ),
                  ),
                );

                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}