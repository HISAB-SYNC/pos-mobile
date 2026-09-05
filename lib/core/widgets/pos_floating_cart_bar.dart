import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_typography.dart';

/// Modern floating bottom action bar displaying item count, subtotal, and checkout trigger.
class PosFloatingCartBar extends StatelessWidget {
  final int itemCount;
  final String formattedTotal;
  final VoidCallback onTap;
  final String label;

  const PosFloatingCartBar({
    super.key,
    required this.itemCount,
    required this.formattedTotal,
    required this.onTap,
    this.label = 'View Cart',
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: AppDecorations.floatingBarDecoration,
          child: Row(
            children: [
              // Badge & item count text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandLime,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                    color: AppColors.brandLimeDarkText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Price Tag & Shopping bag icon
              Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.brandLime,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedTotal,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.brandLime,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
