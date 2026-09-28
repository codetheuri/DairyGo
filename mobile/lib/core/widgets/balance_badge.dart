import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Shows the result of balancing milk: every litre collected must be sold
/// (coolers included) or logged as spoilage.
/// [status] is BALANCED, MISSING (unaccounted > 0) or OVERSOLD (unaccounted < 0).
class BalanceBadge extends StatelessWidget {
  final double unaccountedLitres;
  final String status;
  final bool large;

  const BalanceBadge({
    super.key,
    required this.unaccountedLitres,
    required this.status,
    this.large = false,
  });

  static Color colorFor(String status) {
    switch (status) {
      case 'MISSING':
        return AppColors.error;
      case 'OVERSOLD':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  static String labelFor(double unaccountedLitres, String status) {
    switch (status) {
      case 'MISSING':
        return '${unaccountedLitres.toStringAsFixed(1)} L missing';
      case 'OVERSOLD':
        return '${(-unaccountedLitres).toStringAsFixed(1)} L oversold';
      default:
        return unaccountedLitres == 0
            ? 'Balanced'
            : 'Balanced (${unaccountedLitres.toStringAsFixed(1)} L)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'BALANCED'
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            size: large ? 18 : 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            labelFor(unaccountedLitres, status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: large ? 14 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
