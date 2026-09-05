import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Compact and modern quantity stepper (- N +).
class PosQuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int minQuantity;
  final Color? accentColor;

  const PosQuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.minQuantity = 0,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = accentColor ?? AppColors.brandLime;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.remove_rounded,
            onTap: () {
              if (quantity > minQuantity) {
                HapticFeedback.lightImpact();
                onDecrement();
              }
            },
            isEnabled: quantity > minQuantity,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          _buildButton(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              onIncrement();
            },
            isEnabled: true,
            activeColor: effectiveColor,
            isFilled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
    Color? activeColor,
    bool isFilled = false,
  }) {
    final fillBg = activeColor ?? AppColors.brandLime;
    final isLime = fillBg == AppColors.brandLime;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isFilled ? fillBg : Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: isFilled
                ? (isLime ? AppColors.brandLimeDarkText : Colors.white)
                : (isEnabled ? AppColors.textDark : AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
