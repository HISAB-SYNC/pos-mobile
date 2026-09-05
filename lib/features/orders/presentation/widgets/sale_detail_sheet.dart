import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/skeleton_loaders.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../data/orders_repository.dart';
import '../../models/order_model.dart';
import '../../models/sale_model.dart';
import '../../../../core/services/receipt_pdf_service.dart';

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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sale #${order.orderId}',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.createdAt.isNotEmpty
                            ? order.createdAt.replaceAll('T', ' ').substring(0, 16)
                            : order.formattedDate,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      children: [
                        ListRowSkeleton(),
                        SizedBox(height: 12),
                        ListRowSkeleton(),
                      ],
                    ),
                  )
                : _errorMessage != null && sale == null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.errorRose, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
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
                          decoration: AppDecorations.softCardDecoration(
                            backgroundColor: AppColors.inputBackground,
                            borderRadius: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Payment Method', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        (sale?.paymentMethod ?? order.category).toLowerCase().contains('card')
                                            ? Icons.credit_card_rounded
                                            : Icons.account_balance_wallet_rounded,
                                        size: 16,
                                        color: AppColors.textDark,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        sale?.paymentMethod ?? order.category,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  sale?.status ?? order.status,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.successEmerald),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Purchased Items List
                        Text(
                          'Purchased Items',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),

                        if (sale != null && sale.items.isNotEmpty)
                          ...sale.items.map((item) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: AppDecorations.cardDecoration,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.inputBackground,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primaryBlue),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name.isNotEmpty ? item.name : 'Product Item',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} ETB',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${item.subtotal.toStringAsFixed(0)} ETB',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                    ),
                                  ],
                                ),
                              ))
                        else
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: AppDecorations.cardDecoration,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                Text(order.quantity, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Financial Summary Card
                        Text(
                          'Payment Breakdown',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppDecorations.cardDecoration,
                          child: Column(
                            children: [
                              if (sale != null && sale.subtotal > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                                    Text('${sale.subtotal.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (sale != null && sale.discountAmount > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Discount', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                                    Text('-${sale.discountAmount.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.errorRose)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (sale != null && sale.taxAmount > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tax', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                                    Text('+${sale.taxAmount.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              const Divider(color: AppColors.borderLight),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Grand Total',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                  ),
                                  Text(
                                    '${(sale?.totalAmount ?? order.price).toStringAsFixed(0)} ETB',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.successEmerald),
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

          // Bottom Sticky Action
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final shop = context.read<ShopProvider>().selectedShop;
                        final currentSale = sale ?? Sale(
                          id: widget.order.id,
                          shopId: shop?.id ?? '',
                          userId: '',
                          customerId: null,
                          totalAmount: widget.order.price,
                          subtotal: widget.order.price,
                          taxAmount: 0,
                          discountAmount: 0,
                          paymentMethod: widget.order.category,
                          status: widget.order.status,
                          items: [
                            SaleProductItem(
                              productId: widget.order.productId,
                              name: widget.order.productName,
                              quantity: int.tryParse(widget.order.quantity.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
                              unitPrice: widget.order.price,
                              subtotal: widget.order.price,
                            ),
                          ],
                          createdAt: widget.order.createdAt,
                        );
                        await ReceiptPdfService.printOrDownloadReceipt(
                          sale: currentSale,
                          shop: shop,
                          cashierName: null,
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('Download Receipt'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.borderMedium),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandLime,
                        foregroundColor: AppColors.brandLimeDarkText,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      child: const Text('Close', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
