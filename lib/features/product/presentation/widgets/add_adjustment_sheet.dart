import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/product_provider.dart';

class AddAdjustmentSheet extends StatefulWidget {
  final String productId;
  final String productName;

  const AddAdjustmentSheet({
    super.key,
    required this.productId,
    required this.productName,
  });

  static Future<void> show(BuildContext context, {required String productId, required String productName}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddAdjustmentSheet(productId: productId, productName: productName),
    );
  }

  @override
  State<AddAdjustmentSheet> createState() => _AddAdjustmentSheetState();
}

class _AddAdjustmentSheetState extends State<AddAdjustmentSheet> {
  final _qtyController = TextEditingController();
  final _locationController = TextEditingController(text: 'Kolfe Branch');
  String _selectedReason = 'Damaged';
  bool _isReduction = true;

  final List<String> _reasons = [
    'Damaged',
    'Expired',
    'Found stock',
    'Theft',
    'Inventory Count',
    'Return to Supplier',
  ];

  @override
  void dispose() {
    _qtyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    final change = _isReduction ? -qty : qty;
    context.read<ProductProvider>().addAdjustment(
      productId: widget.productId,
      quantityChange: change,
      reason: _selectedReason,
      storeLocation: _locationController.text.trim(),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adjustment recorded successfully')),
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
                      'New Stock Adjustment',
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

            // Adjustment Type (+ Increase or - Decrease)
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Reduce Stock (-)'),
                    selected: _isReduction,
                    onSelected: (v) => setState(() => _isReduction = true),
                    selectedColor: const Color(0xFFFEE2E2),
                    labelStyle: TextStyle(
                      color: _isReduction ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Increase Stock (+)'),
                    selected: !_isReduction,
                    onSelected: (v) => setState(() => _isReduction = false),
                    selectedColor: const Color(0xFFDCFCE7),
                    labelStyle: TextStyle(
                      color: !_isReduction ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Quantity
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                hintText: 'e.g. 5',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),

            // Reason
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedReason = v);
              },
            ),
            const SizedBox(height: 12),

            // Store Location
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Store Branch / Location',
                hintText: 'e.g. Kolfe Branch',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
              child: const Text('Add Adjustment', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
