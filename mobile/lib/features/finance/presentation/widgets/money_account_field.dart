import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/finance_models.dart';
import '../finance_providers.dart';

/// Which of the Sacco's accounts money went into or came from, so it shows in
/// that account's cashbook. It shows the account for the way of paying (cash
/// to the cash account, M-Pesa to M-Pesa, bank and cheques to the bank) and
/// follows the way of paying until the person picks one. [onChanged] gets
/// null while the shown default stands: the server picks the same account.
/// Shows nothing while the Sacco keeps no accounts.
class MoneyAccountField extends ConsumerStatefulWidget {
  final String method;
  final String label;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const MoneyAccountField({
    super.key,
    required this.method,
    required this.onChanged,
    this.label = 'Into account',
    this.enabled = true,
  });

  @override
  ConsumerState<MoneyAccountField> createState() => _MoneyAccountFieldState();
}

class _MoneyAccountFieldState extends ConsumerState<MoneyAccountField> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final choices = ref.watch(accountChoicesProvider).valueOrNull;
    if (choices == null || choices.accounts.isEmpty) {
      return const SizedBox.shrink();
    }
    final fallback = choices.defaultFor(widget.method);
    final shown = _picked ?? fallback;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String?>(
        // Rebuilt when the default changes with the way of paying.
        key: ValueKey('account-$shown'),
        initialValue: shown,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: shown == null
              ? 'No ${_kind(widget.method)} account yet: choose one, or it will not be in a cashbook'
              : null,
          helperMaxLines: 2,
          helperStyle: const TextStyle(color: AppColors.warning),
        ),
        items: [
          for (final a in choices.accounts)
            DropdownMenuItem(
              value: a.id,
              child: Text(
                '${a.name} (${a.kindLabel})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: widget.enabled
            ? (id) {
                setState(() => _picked = id);
                widget.onChanged(id == fallback ? null : id);
              }
            : null,
      ),
    );
  }

  static String _kind(String method) =>
      switch (AccountChoices.kindFor(method)) {
        'MPESA' => 'M-Pesa',
        'BANK' => 'bank',
        _ => 'cash',
      };
}
