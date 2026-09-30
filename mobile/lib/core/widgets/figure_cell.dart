import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// A figure with its label underneath, e.g. "1234.5L / Intake". Several sit
/// side by side sharing a row equally; a long number shrinks to fit instead
/// of pushing the row off a small screen.
class FigureCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool emphasis;

  const FigureCell({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.bold,
              fontSize: emphasis ? 14 : 13,
              color: color,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
