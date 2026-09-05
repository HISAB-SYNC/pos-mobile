import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/reports/models/analytics_models.dart';
import '../../features/shop/models/shop.dart';

class ReportPdfService {
  /// Generates a PDF Executive Business Report for Daily, Weekly, Monthly, or Custom periods.
  static Future<void> generateAndDownloadReport({
    required Shop? shop,
    required String period,
    required SalesAnalytics? salesAnalytics,
    required ProductAnalytics? productAnalytics,
    required CustomerAnalytics? customerAnalytics,
    required String currency,
  }) async {
    HapticFeedback.lightImpact();

    final doc = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final shopName = shop?.name ?? 'Andalus Business Store';
    final shopAddress = shop?.address ?? '';
    final businessType = shop?.businessType ?? 'Retail Store';
    final generatedAt = DateTime.now().toString().substring(0, 16);

    // Primary Palette
    final primaryNavy = PdfColor.fromHex('#0F172A');
    final accentBlue = PdfColor.fromHex('#2563EB');
    final emeraldGreen = PdfColor.fromHex('#059669');
    final lightGrey = PdfColor.fromHex('#F8FAFC');
    final borderGrey = PdfColor.fromHex('#E2E8F0');
    final textDark = PdfColor.fromHex('#1E293B');
    final textMuted = PdfColor.fromHex('#64748B');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final totalRevenue = salesAnalytics?.totalRevenue ?? 0.0;
          final totalSales = salesAnalytics?.totalSalesCount ?? 0;
          final estimatedProfit = totalRevenue * 0.35;
          final avgOrderValue = salesAnalytics?.averageOrderValue ?? (totalSales > 0 ? (totalRevenue / totalSales) : 0.0);

          return [
            // 1. Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: borderGrey),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shopName,
                        style: pw.TextStyle(font: boldFont, fontSize: 18, color: primaryNavy, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '$businessType • ${shopAddress.isNotEmpty ? shopAddress : "Headquarters"}',
                        style: pw.TextStyle(font: font, fontSize: 9.5, color: textMuted),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Report Generated: $generatedAt',
                        style: pw.TextStyle(font: font, fontSize: 8.5, color: textMuted),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: accentBlue,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Text(
                      '$period Report'.toUpperCase(),
                      style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // 2. Financial Overview KPIs
            pw.Text(
              'EXECUTIVE FINANCIAL SUMMARY',
              style: pw.TextStyle(font: boldFont, fontSize: 12, color: primaryNavy, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            pw.Row(
              children: [
                pw.Expanded(
                  child: _kpiCard(
                    title: 'TOTAL REVENUE',
                    value: '${totalRevenue.toStringAsFixed(2)} $currency',
                    font: font,
                    boldFont: boldFont,
                    accentColor: accentBlue,
                    bgColor: lightGrey,
                    borderColor: borderGrey,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _kpiCard(
                    title: 'ESTIMATED PROFIT',
                    value: '${estimatedProfit.toStringAsFixed(2)} $currency',
                    font: font,
                    boldFont: boldFont,
                    accentColor: emeraldGreen,
                    bgColor: lightGrey,
                    borderColor: borderGrey,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _kpiCard(
                    title: 'TOTAL TRANSACTIONS',
                    value: '$totalSales Orders',
                    font: font,
                    boldFont: boldFont,
                    accentColor: primaryNavy,
                    bgColor: lightGrey,
                    borderColor: borderGrey,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _kpiCard(
                    title: 'AVERAGE BASKET',
                    value: '${avgOrderValue.toStringAsFixed(2)} $currency',
                    font: font,
                    boldFont: boldFont,
                    accentColor: textDark,
                    bgColor: lightGrey,
                    borderColor: borderGrey,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // 3. Payment Method Distribution
            if (salesAnalytics != null) ...[
              pw.Text(
                'PAYMENT & TENDER BREAKDOWN',
                style: pw.TextStyle(font: boldFont, fontSize: 12, color: primaryNavy, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: lightGrey),
                    children: [
                      _thCell('Payment Method', boldFont),
                      _thCell('Transactions', boldFont, align: pw.TextAlign.center),
                      _thCell('Total Amount ($currency)', boldFont, align: pw.TextAlign.right),
                      _thCell('Share %', boldFont, align: pw.TextAlign.right),
                    ],
                  ),
                  _paymentMethodRow('Cash', salesAnalytics.paymentMethodBreakdown.cash, totalRevenue, font, boldFont),
                  _paymentMethodRow('Card', salesAnalytics.paymentMethodBreakdown.card, totalRevenue, font, boldFont),
                  _paymentMethodRow('TeleBirr', salesAnalytics.paymentMethodBreakdown.mobile, totalRevenue, font, boldFont),
                ],
              ),
              pw.SizedBox(height: 24),
            ],

            // 4. Top Performing Products
            if (productAnalytics != null && productAnalytics.topSellingProducts.isNotEmpty) ...[
              pw.Text(
                'TOP SELLING PRODUCTS',
                style: pw.TextStyle(font: boldFont, fontSize: 12, color: primaryNavy, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: lightGrey),
                    children: [
                      _thCell('#', boldFont, width: 24),
                      _thCell('Product Name', boldFont),
                      _thCell('Units Sold', boldFont, align: pw.TextAlign.center),
                      _thCell('Total Revenue ($currency)', boldFont, align: pw.TextAlign.right),
                    ],
                  ),
                  ...productAnalytics.topSellingProducts.take(8).toList().asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        _tdCell('$index', font, align: pw.TextAlign.center),
                        _tdCell(item.name, boldFont),
                        _tdCell('${item.totalQuantitySold}', font, align: pw.TextAlign.center),
                        _tdCell(item.totalRevenue.toStringAsFixed(2), font, align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 24),
            ],

            // 5. Customer & Credit Activity
            if (customerAnalytics != null) ...[
              pw.Text(
                'CUSTOMER & CREDIT HEALTH',
                style: pw.TextStyle(font: boldFont, fontSize: 12, color: primaryNavy, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: borderGrey),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _customerMetric('Total Customers', '${customerAnalytics.totalCustomers}', font, boldFont),
                    _customerMetric('New in Period', '${customerAnalytics.newCustomersInPeriod}', font, boldFont),
                    _customerMetric('Outstanding Debt', '${customerAnalytics.outstandingDebt.totalAmount.toStringAsFixed(0)} $currency', font, boldFont),
                  ],
                ),
              ),
              pw.SizedBox(height: 28),
            ],

            // 6. Signatures & Verification Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 140, height: 1, color: textMuted),
                    pw.SizedBox(height: 4),
                    pw.Text('Store Manager Signature', style: pw.TextStyle(font: font, fontSize: 8, color: textMuted)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(width: 140, height: 1, color: textMuted),
                    pw.SizedBox(height: 4),
                    pw.Text('Accountant Verification', style: pw.TextStyle(font: font, fontSize: 8, color: textMuted)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Divider(color: borderGrey, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Generated automatically by Andalus HISAB-SYNC POS System • Confidential & Proprietary',
                style: pw.TextStyle(font: font, fontSize: 7, color: textMuted),
              ),
            ),
          ];
        },
      ),
    );

    // Opens print / save as PDF on web and mobile
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${shopName.replaceAll(" ", "_")}_${period}_Report.pdf',
    );
  }

  static pw.TableRow _paymentMethodRow(String name, PaymentMethodStat stat, double totalRevenue, pw.Font font, pw.Font boldFont) {
    final share = totalRevenue > 0 ? (stat.totalAmount / totalRevenue * 100).toStringAsFixed(1) : '0';
    return pw.TableRow(
      children: [
        _tdCell(name, font),
        _tdCell('${stat.count}', font, align: pw.TextAlign.center),
        _tdCell(stat.totalAmount.toStringAsFixed(2), boldFont, align: pw.TextAlign.right),
        _tdCell('$share%', font, align: pw.TextAlign.right),
      ],
    );
  }

  static pw.Widget _kpiCard({
    required String title,
    required String value,
    required pw.Font font,
    required pw.Font boldFont,
    required PdfColor accentColor,
    required PdfColor bgColor,
    required PdfColor borderColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 8, color: accentColor, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ],
      ),
    );
  }

  static pw.Widget _customerMetric(String label, String value, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700)),
      ],
    );
  }

  static pw.Widget _thCell(String text, pw.Font boldFont, {pw.TextAlign align = pw.TextAlign.left, double? width}) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: boldFont, fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
      ),
    );
  }

  static pw.Widget _tdCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey900),
      ),
    );
  }
}
