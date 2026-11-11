import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../finance/presentation/finance_providers.dart'
    show Month, monthOf;

/// Month before / month after, never past this month.
class MonthSwitcher extends StatelessWidget {
  final Month month;
  final ValueChanged<Month> onChanged;

  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isThisMonth = monthOf(DateTime.now()).from == month.from;
    void shift(int by) =>
        onChanged(monthOf(DateTime(month.from.year, month.from.month + by, 1)));
    return Row(
      children: [
        IconButton(
          tooltip: 'Month before',
          onPressed: () => shift(-1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM y').format(month.from),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        IconButton(
          tooltip: 'Month after',
          onPressed: isThisMonth ? null : () => shift(1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

void showBooksError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorText(e)), backgroundColor: AppColors.error),
  );
}

void showBooksDone(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// An amount with "Dr" or "Cr": what accountants read.
String drCr(double debit, double credit) => debit > 0
    ? '${thousands(debit)} Dr'
    : credit > 0
    ? '${thousands(credit)} Cr'
    : '0.00';

/// A balance in the account's usual direction; negative shows in red.
Text balanceText(
  double v, {
  double size = 14,
  FontWeight weight = FontWeight.w700,
}) => Text(
  thousands(v),
  style: TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: v < 0 ? AppColors.error : AppColors.textPrimary,
  ),
);

/// A plain white card with the app's border.
class BooksCard extends StatelessWidget {
  final Widget child;
  final Color? border;

  const BooksCard({super.key, required this.child, this.border});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: border ?? AppColors.cardBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}
