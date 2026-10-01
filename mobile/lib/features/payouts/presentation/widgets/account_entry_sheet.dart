import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../finance/presentation/finance_providers.dart';
import '../../data/payout_models.dart';
import '../payout_providers.dart';

/// What can be put on a farmer's account between pay runs.
enum EntryKind {
  advance('advances', 'Give an advance', 'Advance'),
  charge('charges', 'Add a charge', 'Charge'),
  adjustment('adjustments', 'Adjust the account', 'Adjustment');

  final String path;
  final String title;
  final String label;

  const EntryKind(this.path, this.title, this.label);
}

/// Records an advance, a charge or an adjustment on a farmer's account. Pops
/// with true once saved.
class AccountEntrySheet extends ConsumerStatefulWidget {
  final String memberId;
  final String farmer;
  final EntryKind kind;

  const AccountEntrySheet({
    super.key,
    required this.memberId,
    required this.farmer,
    required this.kind,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String memberId,
    required String farmer,
    required EntryKind kind,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) =>
        AccountEntrySheet(memberId: memberId, farmer: farmer, kind: kind),
  );

  @override
  ConsumerState<AccountEntrySheet> createState() => _AccountEntrySheetState();
}

class _AccountEntrySheetState extends ConsumerState<AccountEntrySheet> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _reference = TextEditingController();
  String _method = 'MPESA';
  String? _accountId;
  bool _addsToPay = false; // adjustments: in the farmer's favour
  bool _busy = false;
  String? _error;
  AdvanceInfo? _info;

  @override
  void initState() {
    super.initState();
    if (widget.kind == EntryKind.advance) {
      ref.read(payoutServiceProvider).advanceInfo(widget.memberId).then((i) {
        if (mounted) setState(() => _info = i);
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter the amount.');
      return;
    }
    final desc = _description.text.trim();
    if (widget.kind != EntryKind.advance && desc.length < 3) {
      setState(
        () => _error = widget.kind == EntryKind.charge
            ? 'Say what the charge is for.'
            : 'Give the reason.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(payoutServiceProvider)
          .recordEntry(widget.memberId, widget.kind.path, {
            'amount': widget.kind == EntryKind.adjustment && !_addsToPay
                ? -amount
                : amount,
            if (desc.isNotEmpty) 'description': desc,
            if (widget.kind == EntryKind.advance) 'method': _method,
            if (_reference.text.trim().isNotEmpty)
              'reference': _reference.text.trim(),
            'cash_account_id': ?_accountId,
          });
      ref.invalidate(farmerAccountProvider(widget.memberId));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final info = _info;
    final accounts = kind == EntryKind.advance
        ? (ref.watch(cashAccountsProvider).valueOrNull?.active ?? const [])
        : const [];
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
              kind.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.farmer,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (kind == EntryKind.advance)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: info == null
                    ? const LinearProgressIndicator()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Milk since last pay: ${kes(info.milkSoFar)} (${litres(info.litresSoFar)})',
                          ),
                          Text('Advances taken: ${kes(info.taken)}'),
                          if (info.balance < 0)
                            Text('Owes the Sacco now: ${kes(-info.balance)}'),
                          if (info.limit != null)
                            Text('Limit per pay period: ${kes(info.limit!)}'),
                          if (info.milkAllows != null)
                            Text(
                              'Milk allows: ${kes(info.milkAllows!)} '
                              '(${info.milkPercent}% of milk, less what they owe)',
                            ),
                          const SizedBox(height: 4),
                          Text(
                            info.closed != null
                                ? 'No advance today: ${info.closed}.'
                                : info.available == null
                                ? 'No advance limit is set.'
                                : 'Can take now: ${kes(info.available!)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color:
                                  info.closed != null ||
                                      (info.available ?? 1) <= 0
                                  ? AppColors.error
                                  : null,
                            ),
                          ),
                        ],
                      ),
              ),
            if (kind == EntryKind.charge)
              const Text(
                'Something the farmer owes, such as feeds, AI or vet services. It is taken from their next pay.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            if (kind == EntryKind.adjustment) ...[
              const Text(
                'A correction. It needs a reason and is recorded with your name.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Take off their pay'),
                    selected: !_addsToPay,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _addsToPay = false),
                  ),
                  ChoiceChip(
                    label: const Text('Add to their pay'),
                    selected: _addsToPay,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _addsToPay = true),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              enabled: !_busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(labelText: 'Amount (KES)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: switch (kind) {
                  EntryKind.advance => 'Note (optional)',
                  EntryKind.charge => 'What for',
                  EntryKind.adjustment => 'Reason',
                },
                hintText: kind == EntryKind.charge
                    ? 'e.g. Dairy meal 2 bags'
                    : null,
              ),
            ),
            if (kind == EntryKind.advance) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final (v, l) in const [
                    ('MPESA', 'M-Pesa'),
                    ('CASH', 'Cash'),
                    ('BANK_TRANSFER', 'Bank'),
                  ])
                    ChoiceChip(
                      label: Text(l),
                      selected: _method == v,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _method = v),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reference,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Reference (optional)',
                ),
              ),
              if (accounts.isNotEmpty) ...[
                const SizedBox(height: 10),
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
                        child: Text(a.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _accountId = v),
                ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text('Save ${kind.label.toLowerCase()}'),
            ),
          ],
        ),
      ),
    );
  }
}
