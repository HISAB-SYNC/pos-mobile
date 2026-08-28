import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../data/orders_repository.dart';
import '../../models/order_model.dart';
import '../../models/sale_model.dart';

class SaleDetailSheet extends StatefulWidget {
  final ShopOrder order;

  const SaleDetailSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, {required ShopOrder order}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SaleDetailSheet(order: order),
    );
  }

  @override
  State<SaleDetailSheet> createState() => _SaleDetailSheetState();
}

class _SaleDetailSheetState extends State<SaleDetailSheet> {
  final OrdersRepository _repository = OrdersRepository();
  bool _isLoading = true;
  Sale? _saleDetail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final shopId = shop.selectedShop?.id ?? '';
    final token = auth.token;

    if (shopId.isEmpty || token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Session expired';
      });
      return;
    }

    final result = await _repository.getSaleDetail(
      shopId: shopId,
      token: token,
      saleId: widget.order.id,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] is Sale) {
          _saleDetail = result['data'] as Sale;
        } else {
          _errorMessage = result['error']?.toString() ?? 'Failed to load details';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final sale = _saleDetail;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppColors.navy, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sale #${order.orderId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF161B20),
                        ),
                      ),
                      Text(
                        order.createdAt.isNotEmpty
                            ? order.createdAt.replaceAll('T', ' ').substring(0, 16)
                            : order.expectedDelivery,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
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

          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.navy, strokeWidth: 2),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status & Payment Method Banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Payment Method', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        (sale?.paymentMethod ?? order.category).toLowerCase().contains('card')
                                            ? Icons.credit_card
                                            : Icons.payments,
                                        size: 16,
                                        color: const Color(0xFF161B20),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        sale?.paymentMethod ?? order.category,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sale?.status ?? order.status,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Purchased Items List
                        const Text(
                          'Purchased Items',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                        ),
                        const SizedBox(height: 10),

                        if (sale != null && sale.items.isNotEmpty)
                          ...sale.items.map((item) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF2563EB)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name.isNotEmpty ? item.name : 'Product Item',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} ETB',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${item.subtotal.toStringAsFixed(2)} ETB',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                                    ),
                                  ],
                                ),
                              ))
                        else
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(order.quantity, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Financial Summary Card
                        const Text(
                          'Payment Breakdown',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              if (sale != null && sale.subtotal > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                    Text('${sale.subtotal.toStringAsFixed(2)} ETB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (sale != null && sale.discountAmount > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Discount', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                    Text('-${sale.discountAmount.toStringAsFixed(2)} ETB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (sale != null && sale.taxAmount > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tax', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                    Text('+${sale.taxAmount.toStringAsFixed(2)} ETB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              const Divider(color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Grand Total',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                                  ),
                                  Text(
                                    '${(sale?.totalAmount ?? order.price).toStringAsFixed(2)} ETB',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Bottom Action
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF161B20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
