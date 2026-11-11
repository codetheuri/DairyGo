import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../data/books_models.dart';
import 'books_widgets.dart';

/// A statement section: each account with this period's amount, the
/// earlier one in small type under it, and the totals. Stacked rather than
/// in columns so it fits the smallest phone at large text.
class StatementSectionCard extends StatelessWidget {
  final StatementSection section;
  final String previousLabel;
  final String totalLabel;

  const StatementSectionCard({
    super.key,
    required this.section,
    required this.previousLabel,
    required this.totalLabel,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          section.title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        BooksCard(
          child: Column(
            children: [
              if (section.lines.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Nothing.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              for (final l in section.lines) ...[
                StatementRow(
                  label: l.label,
                  amount: l.amount,
                  previous: l.previous,
                  previousLabel: previousLabel,
                  onTap: l.accountId == null
                      ? null
                      : () => context.push('/books/accounts/${l.accountId}'),
                ),
                const Divider(height: 1),
              ],
              StatementRow(
                label: totalLabel,
                amount: section.total,
                previous: section.previousTotal,
                previousLabel: previousLabel,
                bold: true,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// One line: label and amount, the earlier amount under them.
class StatementRow extends StatelessWidget {
  final String label;
  final double amount;
  final double previous;
  final String previousLabel;
  final bool bold;
  final VoidCallback? onTap;

  const StatementRow({
    super.key,
    required this.label,
    required this.amount,
    required this.previous,
    required this.previousLabel,
    this.bold = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weight = bold ? FontWeight.w700 : FontWeight.w400;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(label, style: TextStyle(fontWeight: weight)),
                ),
                const SizedBox(width: 8),
                Text(
                  thousands(amount),
                  style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: amount < 0 ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '$previousLabel: ${thousands(previous)}',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
