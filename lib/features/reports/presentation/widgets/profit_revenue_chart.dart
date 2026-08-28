import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/report_models.dart';

class ProfitRevenueChart extends StatefulWidget {
  final List<ProfitRevenuePoint> points;
  final int selectedIndex;
  final ValueChanged<int> onPointSelected;

  const ProfitRevenueChart({
    super.key,
    required this.points,
    required this.selectedIndex,
    required this.onPointSelected,
  });

  @override
  State<ProfitRevenueChart> createState() => _ProfitRevenueChartState();
}

class _ProfitRevenueChartState extends State<ProfitRevenueChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const SizedBox(height: 220, child: Center(child: Text('No chart data available')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chart Area
        SizedBox(
          height: 220,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) => _handleTouch(details.localPosition, constraints.maxWidth),
                onHorizontalDragUpdate: (details) => _handleTouch(details.localPosition, constraints.maxWidth),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 220),
                  painter: _LineChartPainter(
                    points: widget.points,
                    selectedIndex: widget.selectedIndex,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(const Color(0xFF2563EB), 'Revenue'),
            const SizedBox(width: 20),
            _legendItem(const Color(0xFFE5C07B), 'Profit'),
          ],
        ),
      ],
    );
  }

  void _handleTouch(Offset offset, double width) {
    final leftPadding = 48.0;
    final rightPadding = 16.0;
    final availableWidth = width - leftPadding - rightPadding;
    if (availableWidth <= 0 || widget.points.isEmpty) return;

    final dx = (offset.dx - leftPadding).clamp(0.0, availableWidth);
    final step = availableWidth / max(1, widget.points.length - 1);
    final index = (dx / step).round().clamp(0, widget.points.length - 1);

    if (index != widget.selectedIndex) {
      widget.onPointSelected(index);
    }
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<ProfitRevenuePoint> points;
  final int selectedIndex;

  _LineChartPainter({required this.points, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final leftPadding = 48.0;
    final bottomPadding = 26.0;
    final topPadding = 40.0;
    final rightPadding = 16.0;

    final drawWidth = size.width - leftPadding - rightPadding;
    final drawHeight = size.height - topPadding - bottomPadding;

    final maxY = 80000.0;
    final minY = 0.0;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    final axisTextPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw horizontal grid lines & Y labels
    final yValues = [80000, 60000, 40000, 20000];
    for (final val in yValues) {
      final normalized = (val - minY) / (maxY - minY);
      final y = topPadding + drawHeight * (1.0 - normalized);

      canvas.drawLine(Offset(leftPadding, y), Offset(size.width - rightPadding, y), gridPaint);

      axisTextPainter.text = TextSpan(
        text: '${(val / 1000).toInt()},000',
        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(canvas, Offset(leftPadding - axisTextPainter.width - 6, y - 6));
    }

    if (points.isEmpty) return;

    final stepX = drawWidth / max(1, points.length - 1);
    final revenueOffsets = <Offset>[];
    final profitOffsets = <Offset>[];

    // Compute coordinate points
    for (int i = 0; i < points.length; i++) {
      final x = leftPadding + i * stepX;
      final revY = topPadding + drawHeight * (1.0 - (points[i].revenue / maxY).clamp(0.0, 1.0));
      final profY = topPadding + drawHeight * (1.0 - (points[i].profit / maxY).clamp(0.0, 1.0));

      revenueOffsets.add(Offset(x, revY));
      profitOffsets.add(Offset(x, profY));

      // Draw X axis label
      axisTextPainter.text = TextSpan(
        text: points[i].label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w500,
          color: i == selectedIndex ? const Color(0xFF161B20) : const Color(0xFF94A3B8),
        ),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(canvas, Offset(x - axisTextPainter.width / 2, size.height - bottomPadding + 6));
    }

    // Paint Smooth Profit Curve (Gold/Beige)
    _drawSmoothCurve(
      canvas,
      profitOffsets,
      Paint()
        ..color = const Color(0xFFE5C07B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // Paint Smooth Revenue Curve (Blue)
    _drawSmoothCurve(
      canvas,
      revenueOffsets,
      Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    // Draw Selected Point Guide & Tooltip
    if (selectedIndex >= 0 && selectedIndex < revenueOffsets.length) {
      final selRevOffset = revenueOffsets[selectedIndex];

      // Dotted Vertical Guide Line
      final guidePaint = Paint()
        ..color = const Color(0xFF3B82F6)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      double startY = selRevOffset.dy;
      final endY = size.height - bottomPadding;
      while (startY < endY) {
        canvas.drawLine(Offset(selRevOffset.dx, startY), Offset(selRevOffset.dx, min(startY + 4, endY)), guidePaint);
        startY += 7;
      }

      // Highlighted Circle
      canvas.drawCircle(selRevOffset, 5, Paint()..color = const Color(0xFF2563EB));
      canvas.drawCircle(selRevOffset, 3, Paint()..color = Colors.white);

      // Floating Tooltip
      _drawTooltip(canvas, selRevOffset, points[selectedIndex].label);
    }
  }

  void _drawSmoothCurve(Canvas canvas, List<Offset> offsets, Paint paint) {
    if (offsets.length < 2) return;
    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawTooltip(Canvas canvas, Offset target, String label) {
    const tooltipText1 = 'This Month';
    const tooltipText2 = '220,342,123';

    final textPainter1 = TextPainter(
      text: const TextSpan(
        text: tooltipText1,
        style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textPainter2 = TextPainter(
      text: const TextSpan(
        text: tooltipText2,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF161B20)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tooltipWidth = max(textPainter1.width, textPainter2.width) + 16;
    final tooltipHeight = textPainter1.height + textPainter2.height + 10;

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(target.dx.clamp(tooltipWidth / 2 + 10, 400 - tooltipWidth / 2), target.dy - 30),
        width: tooltipWidth,
        height: tooltipHeight,
      ),
      const Radius.circular(8),
    );

    // Tooltip Shadow & Background
    canvas.drawRRect(
      tooltipRect,
      Paint()
        ..color = const Color(0x18000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(tooltipRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      tooltipRect,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    textPainter1.paint(canvas, Offset(tooltipRect.left + 8, tooltipRect.top + 4));
    textPainter2.paint(canvas, Offset(tooltipRect.left + 8, tooltipRect.top + 4 + textPainter1.height + 2));
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.points != points;
  }
}
