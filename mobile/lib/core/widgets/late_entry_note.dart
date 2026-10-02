import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Shown on a milk record DairyGo support entered after its day (Sacco staff
/// record only today). Nothing when [reason] is null.
class LateEntryNote extends StatelessWidget {
  final String? reason;

  const LateEntryNote({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    final why = reason?.trim() ?? '';
    if (why.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Entered late by DairyGo support: $why',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
