import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// A key figure: a label and a value ("Net pay", "KES 13,487.00").
class Figure {
  final String label;
  final String value;
  final Color? color;

  const Figure(this.label, this.value, {this.color});
}

/// Key figures in boxes, two to a row on a phone and more on wider screens.
/// Long values shrink to fit; nothing scrolls sideways.
class FigureGrid extends StatelessWidget {
  final List<Figure> figures;

  const FigureGrid({super.key, required this.figures});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final perRow = constraints.maxWidth >= 600 ? 4 : 2;
        final width = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final f in figures)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentMint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          f.value,
                          maxLines: 1,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: f.color ?? AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
