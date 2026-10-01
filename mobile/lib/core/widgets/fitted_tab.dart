import 'package:flutter/material.dart';

/// A tab with an icon over a short label. Use it in a TabBar that is not
/// scrollable: every tab then takes an equal share of the width, and a label
/// too long for its share (a small phone with large text) shrinks to fit
/// instead of being cut off, so every tab is always visible.
class FittedTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const FittedTab({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Tab(
    iconMargin: const EdgeInsets.only(bottom: 2),
    icon: Icon(icon, size: 18),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, softWrap: false),
    ),
  );
}
