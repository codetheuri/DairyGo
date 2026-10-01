import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../finance/presentation/finance_providers.dart';
import '../payout_providers.dart';

/// Records how farmers were paid: one farmer ([lineId]) or everyone still to
/// be paid. Pops with true once saved.
class MarkPaidSheet extends ConsumerStatefulWidget {
  final String runId;
  final String? lineId;
  final String who;
  final double amount;

  const MarkPaidSheet({
    super.key,
    required this.runId,
    this.lineId,
    required this.who,
    required this.amount,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String runId,
    String? lineId,
    String? farmer,
    int count = 1,
    required double amount,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => MarkPaidSheet(
      runId: runId,
      lineId: lineId,
      who: farmer ?? '$count farmers',
      amount: amount,
    ),
  );

  @override
  ConsumerState<MarkPaidSheet> createState() => _MarkPaidSheetState();
}

class _MarkPaidSheetState extends ConsumerState<MarkPaidSheet> {
  final _reference = TextEditingController();
  String _method = 'MPESA';
  String? _accountId;
  bool _busy = false;
  String? _error;

  static const _methods = [
    ('MPESA', 'M-Pesa'),
    ('BANK_TRANSFER', 'Bank'),
    ('CASH', 'Cash'),
    ('CHEQUE', 'Cheque'),
  ];

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ref0 = _reference.text.trim();
    if (_method != 'CASH' && ref0.isEmpty) {
      setState(() => _error = 'Give the M-Pesa, bank or cheque reference.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(payoutServiceProvider)
          .pay(
            widget.runId,
            lineIds: widget.lineId == null ? null : [widget.lineId!],
            method: _method,
            reference: ref0.isEmpty ? null : ref0,
            accountId: _accountId,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts =
        ref.watch(cashAccountsProvider).valueOrNull?.active ?? const [];
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mark ${widget.who} paid',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              kes(widget.amount),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'How were they paid?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label) in _methods)
                  ChoiceChip(
                    label: Text(label),
                    selected: _method == value,
                    showCheckmark: false,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _method = value),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reference,
              enabled: !_busy,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: _method == 'CASH'
                    ? 'Reference (optional)'
                    : 'Reference',
                hintText: _method == 'MPESA'
                    ? 'M-Pesa code or bulk payment ID'
                    : null,
              ),
            ),
            if (accounts.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                initialValue: _accountId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Paid from (optional)',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Not recorded'),
                  ),
                  for (final a in accounts)
                    DropdownMenuItem(
                      value: a.id,
                      child: Text(
                        '${a.name} (${a.kindLabel})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _busy ? null : (v) => setState(() => _accountId = v),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Mark paid'),
            ),
          ],
        ),
      ),
    );
  }
}
