import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../models/customer_model.dart';
import '../../models/debt_model.dart';
import '../../provider/customer_provider.dart';

class RecordPaymentSheet extends StatefulWidget {
  final Customer customer;
  final Debt? specificDebt;

  const RecordPaymentSheet({super.key, required this.customer, this.specificDebt});

  static Future<void> show(
    BuildContext context, {
    required Customer customer,
    Debt? specificDebt,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordPaymentSheet(customer: customer, specificDebt: specificDebt),
    );
  }

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _amountController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final defaultAmt = widget.specificDebt != null
        ? widget.specificDebt!.remainingAmount
        : widget.customer.totalDebt;
    _amountController.text = defaultAmt > 0 ? defaultAmt.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();
    final customerProvider = context.read<CustomerProvider>();

    final shopId = shop.selectedShop?.id ?? '';
    final token = auth.token;

    if (shopId.isEmpty || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    if (widget.specificDebt != null) {
      final res = await customerProvider.recordDebtPayment(
        shopId: shopId,
        token: token,
        debtId: widget.specificDebt!.id,
        customerId: widget.customer.id,
        amount: amount,
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        if (res['success'] == true) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Debt payment of ${amount.toStringAsFixed(2)} ETB recorded successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error']?.toString() ?? 'Failed to record debt payment')),
          );
        }
      }
    } else {
      final ok = await customerProvider.recordPayment(
        shopId: shopId,
        token: token,
        customerId: widget.customer.id,
        amount: amount,
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        if (ok) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment of ${amount.toStringAsFixed(2)} ETB recorded successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to record payment')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final debtAmount = widget.specificDebt != null
        ? widget.specificDebt!.remainingAmount
        : widget.customer.totalDebt;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.specificDebt != null ? 'Pay Debt Record' : 'Record Payment',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                      ),
                      Text(
                        widget.customer.name,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current Outstanding Debt info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Outstanding Balance:', style: TextStyle(fontSize: 13, color: Color(0xFF991B1B))),
                    Text(
                      '${debtAmount.toStringAsFixed(2)} ETB',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Payment Amount (ETB)*',
                  hintText: 'Enter amount paid',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF161B20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
