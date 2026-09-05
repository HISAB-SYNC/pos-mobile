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
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No sales trend points recorded for this period', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        ),
      );
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
            _legendItem(const Color(0xFFE5C07B), 'Gross Margin Est.'),
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

    if (points.isEmpty) return;

    // Dynamically compute maximum value with margin
    double maxDataVal = 0.0;
    for (final p in points) {
      if (p.revenue > maxDataVal) maxDataVal = p.revenue;
      if (p.profit > maxDataVal) maxDataVal = p.profit;
    }
    final maxY = maxDataVal > 0 ? (maxDataVal * 1.25) : 5000.0;
    const minY = 0.0;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    final axisTextPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw 4 horizontal grid lines & Y labels
    final yInterval = maxY / 4;
    for (int i = 4; i >= 1; i--) {
      final val = yInterval * i;
      final normalized = (val - minY) / (maxY - minY);
      final y = topPadding + drawHeight * (1.0 - normalized);

      canvas.drawLine(Offset(leftPadding, y), Offset(size.width - rightPadding, y), gridPaint);

      final labelText = val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : val.toStringAsFixed(0);
      axisTextPainter.text = TextSpan(
        text: labelText,
        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(canvas, Offset(leftPadding - axisTextPainter.width - 6, y - 6));
    }

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
          fontSize: 10.5,
          fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w500,
          color: i == selectedIndex ? const Color(0xFF161B20) : const Color(0xFF94A3B8),
        ),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(canvas, Offset(x - axisTextPainter.width / 2, size.height - bottomPadding + 6));
    }

    // Paint Smooth Margin Curve (Gold/Beige)
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
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // Draw active point tooltip and vertical guide line
    if (selectedIndex >= 0 && selectedIndex < points.length) {
      final activePoint = points[selectedIndex];
      final activeX = leftPadding + selectedIndex * stepX;
      final activeRevY = revenueOffsets[selectedIndex].dy;

      // Vertical guide line
      final dashedPaint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.3)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(activeX, topPadding), Offset(activeX, size.height - bottomPadding), dashedPaint);

      // Dot on Revenue
      canvas.drawCircle(Offset(activeX, activeRevY), 6.0, Paint()..color = const Color(0xFF2563EB));
      canvas.drawCircle(Offset(activeX, activeRevY), 3.0, Paint()..color = Colors.white);

      // Tooltip Card
      final tooltipText = '${activePoint.revenue.toStringAsFixed(0)} ETB';
      axisTextPainter.text = TextSpan(
        text: tooltipText,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
      );
      axisTextPainter.layout();

      final tooltipWidth = axisTextPainter.width + 16;
      final tooltipHeight = 26.0;
      final tooltipX = (activeX - tooltipWidth / 2).clamp(leftPadding, size.width - rightPadding - tooltipWidth);
      final tooltipY = (activeRevY - tooltipHeight - 10).clamp(4.0, size.height);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
        const Radius.circular(8),
      );

      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF161B20));
      axisTextPainter.paint(canvas, Offset(tooltipX + 8, tooltipY + 5));
    }
  }

  void _drawSmoothCurve(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      canvas.drawCircle(points[0], paint.strokeWidth / 2, paint);
      return;
    }

    final path = Path()..moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.points != points;
  }
}
