import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/orders/models/sale_model.dart';
import '../../features/shop/models/shop.dart';

class ReceiptPdfService {
  /// Generates an authentic thermal POS receipt PDF and opens native print / download dialog.
  static Future<void> printOrDownloadReceipt({
    required Sale sale,
    required Shop? shop,
    String? cashierName,
  }) async {
    HapticFeedback.lightImpact();

    final doc = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final shopName = shop?.name.toUpperCase() ?? 'ANDALUS POS';
    final shopAddress = shop?.address ?? '';
    final currency = shop?.currency ?? 'ETB';
    final receiptNumber = sale.id.length > 8 ? sale.id.substring(0, 8).toUpperCase() : sale.id.toUpperCase();
    final saleDate = sale.createdAt.isNotEmpty ? sale.createdAt : DateTime.now().toString().substring(0, 16);

    // Standard 80mm Roll Width format
    final pageFormat = const PdfPageFormat(
      72 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 4 * PdfPageFormat.mm,
    );

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // 1. Store Header
                pw.Text(
                  shopName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: boldFont, fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
                if (shopAddress.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    shopAddress,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
                pw.SizedBox(height: 4),
                pw.Text(
                  '*** SALES RECEIPT ***',
                  style: pw.TextStyle(font: boldFont, fontSize: 8.5),
                ),
                pw.SizedBox(height: 4),
                _dashedLine(),
                pw.SizedBox(height: 4),

                // 2. Receipt Metadata
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('RECEIPT #:', style: pw.TextStyle(font: boldFont, fontSize: 7.5)),
                    pw.Text(receiptNumber, style: pw.TextStyle(font: font, fontSize: 7.5)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('DATE / TIME:', style: pw.TextStyle(font: boldFont, fontSize: 7.5)),
                    pw.Text(saleDate, style: pw.TextStyle(font: font, fontSize: 7.5)),
                  ],
                ),
                if (cashierName != null && cashierName.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('CASHIER:', style: pw.TextStyle(font: boldFont, fontSize: 7.5)),
                      pw.Text(cashierName, style: pw.TextStyle(font: font, fontSize: 7.5)),
                    ],
                  ),
                ],
                pw.SizedBox(height: 4),
                _dashedLine(),
                pw.SizedBox(height: 4),

                // 3. Item List Header
                pw.Row(
                  children: [
                    pw.Expanded(flex: 5, child: pw.Text('ITEM', style: pw.TextStyle(font: boldFont, fontSize: 7.5))),
                    pw.Expanded(flex: 2, child: pw.Text('QTY', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: boldFont, fontSize: 7.5))),
                    pw.Expanded(flex: 3, child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: boldFont, fontSize: 7.5))),
                  ],
                ),
                pw.SizedBox(height: 3),
                _dashedLine(),
                pw.SizedBox(height: 4),

                // 4. Items Rows
                if (sale.items.isEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text('Standard POS Sale', style: pw.TextStyle(font: font, fontSize: 8)),
                  )
                else
                  ...sale.items.map((item) {
                    final itemName = item.name.isNotEmpty ? item.name : 'Item ${item.productId.length > 5 ? item.productId.substring(0, 5) : item.productId}';
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(itemName, style: pw.TextStyle(font: font, fontSize: 8)),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 5,
                                child: pw.Text(
                                  '  @ ${item.unitPrice.toStringAsFixed(2)} $currency',
                                  style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey700),
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text('x${item.quantity}', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 7.5)),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text('${item.subtotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: boldFont, fontSize: 8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                pw.SizedBox(height: 4),
                _dashedLine(),
                pw.SizedBox(height: 5),

                // 5. Totals & Financials
                _receiptRow('SUBTOTAL:', '${sale.subtotal.toStringAsFixed(2)} $currency', font),
                if (sale.taxAmount > 0) ...[
                  pw.SizedBox(height: 2),
                  _receiptRow('TAX (${shop?.taxRate ?? 15}%):', '+${sale.taxAmount.toStringAsFixed(2)} $currency', font),
                ],
                if (sale.discountAmount > 0) ...[
                  pw.SizedBox(height: 2),
                  _receiptRow('DISCOUNT:', '-${sale.discountAmount.toStringAsFixed(2)} $currency', font),
                ],
                pw.SizedBox(height: 4),
                _solidLine(),
                pw.SizedBox(height: 4),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('GRAND TOTAL:', style: pw.TextStyle(font: boldFont, fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${sale.totalAmount.toStringAsFixed(2)} $currency', style: pw.TextStyle(font: boldFont, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 4),
                _solidLine(),
                pw.SizedBox(height: 5),

                // 6. Tender Details
                _receiptRow('PAYMENT METHOD:', sale.paymentMethod, boldFont),
                _receiptRow('STATUS:', sale.status, font),

                pw.SizedBox(height: 10),
                _dashedLine(),
                pw.SizedBox(height: 8),

                // 7. Footer & Barcode
                pw.BarcodeWidget(
                  data: sale.id,
                  barcode: pw.Barcode.code128(),
                  width: 140,
                  height: 28,
                  drawText: false,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'THANK YOU FOR YOUR BUSINESS!',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: boldFont, fontSize: 7.5),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Please keep this receipt for returns or exchanges',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: font, fontSize: 6.5, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Powered by Andalus HISAB-SYNC POS',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: font, fontSize: 6, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Opens printer / download dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Receipt_${receiptNumber}_$currency.pdf',
    );
  }

  static pw.Widget _receiptRow(String label, String value, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 7.5)),
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 8)),
      ],
    );
  }

  static pw.Widget _dashedLine() {
    return pw.Container(
      height: 1,
      child: pw.CustomPaint(
        painter: (canvas, size) {
          double startX = 0;
          const dashWidth = 3.0;
          const dashSpace = 2.0;
          while (startX < size.x) {
            canvas.drawLine(startX, 0, startX + dashWidth, 0);
            startX += dashWidth + dashSpace;
          }
        },
      ),
    );
  }

  static pw.Widget _solidLine() {
    return pw.Container(height: 1, color: PdfColors.black);
  }
}
