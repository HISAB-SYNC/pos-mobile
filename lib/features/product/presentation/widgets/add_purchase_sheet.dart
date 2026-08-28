import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/product_provider.dart';

class AddPurchaseSheet extends StatefulWidget {
  final String productId;
  final String productName;
  final String? defaultSupplier;
  final double defaultCost;

  const AddPurchaseSheet({
    super.key,
    required this.productId,
    required this.productName,
    this.defaultSupplier,
    this.defaultCost = 0.0,
  });

  static Future<void> show(
    BuildContext context, {
    required String productId,
    required String productName,
    String? defaultSupplier,
    double defaultCost = 0.0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddPurchaseSheet(
        productId: productId,
        productName: productName,
        defaultSupplier: defaultSupplier,
        defaultCost: defaultCost,
      ),
    );
  }

  @override
  State<AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends State<AddPurchaseSheet> {
  late final TextEditingController _supplierController;
  late final TextEditingController _qtyController;
  late final TextEditingController _unitCostController;

  @override
  void initState() {
    super.initState();
    _supplierController = TextEditingController(text: widget.defaultSupplier ?? 'Mr. X');
    _qtyController = TextEditingController(text: '50');
    _unitCostController = TextEditingController(
      text: widget.defaultCost > 0 ? widget.defaultCost.toStringAsFixed(0) : '75',
    );
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _qtyController.dispose();
    _unitCostController.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final unitCost = double.tryParse(_unitCostController.text.trim()) ?? 0.0;

    if (qty <= 0 || unitCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid quantity and unit cost')),
      );
      return;
    }

    context.read<ProductProvider>().addPurchase(
      productId: widget.productId,
      supplierName: _supplierController.text.trim(),
      quantity: qty,
      unitCost: unitCost,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchase recorded and stock updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
                    const Text(
                      'New Product Purchase',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF161B20)),
                    ),
                    Text(
                      widget.productName,
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

            TextField(
              controller: _supplierController,
              decoration: InputDecoration(
                labelText: 'Supplier Name',
                hintText: 'e.g. Mr. X',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity (Units)',
                      hintText: 'e.g. 50',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unitCostController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Unit Cost (ETB)',
                      hintText: 'e.g. 75',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF161B20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add Purchase', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
