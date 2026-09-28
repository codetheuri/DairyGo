import 'package:flutter/material.dart';

/// Material 3 window-size classes, in logical pixels.
/// https://m3.material.io/foundations/layout/applying-layout/window-size-classes
abstract class Breakpoints {
  /// From here up (tablets, phones in landscape) navigation moves to a side rail.
  static const double medium = 600;

  /// From here up the side rail shows labels beside its icons.
  static const double expanded = 1200;

  /// Widest a column of text, forms or lists should grow; wider looks
  /// stretched and is hard to read.
  static const double readableWidth = 720;
}

/// The body of a screen: kept clear of the areas the system draws over, and
/// at a readable width, centred, on wide screens.
///
/// Since Android 15 apps draw edge to edge, so without this the last button
/// of a form ends up under the gesture or 3-button navigation bar, and in
/// landscape content goes under the camera cutout. The top is left to the
/// app bar. Inside the main sections the bottom bar already takes the bottom
/// inset, so nothing is added twice.
class ReadableWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ReadableWidth({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.readableWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Lays cards out in rows, as many per row as fit at [minItemWidth] each
/// (at least [minColumns]). The width grows with the user's text size, so
/// large text gets fewer, wider cards instead of truncated titles. Every card in a row takes the height of the
/// tallest, and rows grow with the text, so large font settings never
/// overflow a card the way a fixed aspect-ratio grid does.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final int minColumns;
  final int maxColumns;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 160,
    this.minColumns = 1,
    this.maxColumns = 4,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = MediaQuery.textScalerOf(context).scale(minItemWidth);
        final fit = ((constraints.maxWidth + spacing) / (itemWidth + spacing))
            .floor();
        final columns = fit.clamp(minColumns, maxColumns);
        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          final cells = <Widget>[];
          for (var i = 0; i < columns; i++) {
            if (i > 0) cells.add(SizedBox(width: spacing));
            final index = start + i;
            cells.add(
              Expanded(
                child: index < children.length
                    ? children[index]
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cells,
              ),
            ),
          );
        }
        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }
}
