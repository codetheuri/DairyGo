import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../finance/data/finance_service.dart';
import '../../../finance/presentation/finance_providers.dart';
import '../../../finance/presentation/widgets/finance_sheets.dart';
import '../../../finance/presentation/widgets/money_flow_sheets.dart';
import '../../../members/data/models/member_model.dart';
import '../../../members/presentation/widgets/farmer_picker_sheet.dart';
import '../../data/payout_models.dart';
import '../payout_providers.dart';

/// A farmer's shares: savings taken from pay, shares held before DairyGo,
/// refunds and transfers, with the actions for whoever manages shares.
class SharesSection extends ConsumerWidget {
  final String memberId;
  final String farmer;
  final bool canManage;

  const SharesSection({
    super.key,
    required this.memberId,
    required this.farmer,
    required this.canManage,
  });

  static final _day = DateFormat('d MMM y');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shares = ref.watch(farmerSharesProvider(memberId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Shares',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        shares.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Text(
            errorText(e),
            style: const TextStyle(color: AppColors.error),
          ),
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.buckets.length > 1
                    ? s.buckets
                          .map((b) => '${b.name} ${kes(b.balance)}')
                          .join(' · ')
                    : '${kes(s.balance)} in shares',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (canManage)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => ShareSheet.show(
                          context,
                          memberId: memberId,
                          farmer: farmer,
                          action: ShareAction.opening,
                          shares: s,
                        ),
                        icon: const Icon(Icons.history_edu_outlined),
                        label: const Text('Opening shares'),
                      ),
                      if (s.balance > 0) ...[
                        OutlinedButton.icon(
                          onPressed: () => ShareSheet.show(
                            context,
                            memberId: memberId,
                            farmer: farmer,
                            action: ShareAction.refund,
                            shares: s,
                          ),
                          icon: const Icon(Icons.undo_rounded),
                          label: const Text('Refund'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => ShareSheet.show(
                            context,
                            memberId: memberId,
                            farmer: farmer,
                            action: ShareAction.transfer,
                            shares: s,
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Pass on'),
                        ),
                      ],
                    ],
                  ),
                ),
              for (final l in s.lines.take(12))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onLongPress: canManage && l.voidable
                      ? () => _void(context, ref, l)
                      : null,
                  title: Text(
                    [
                      l.kindLabel,
                      if (s.buckets.length > 1) l.savings,
                    ].join(' · '),
                    style: TextStyle(
                      decoration: l.voided ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    [
                      _day.format(l.date),
                      if (l.description.isNotEmpty) l.description,
                      if (l.voided) 'voided',
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${l.amount < 0 ? '−' : '+'}${thousands(l.amount.abs())}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: l.amount < 0 ? AppColors.error : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _void(BuildContext context, WidgetRef ref, ShareLine l) async {
    final reason = await askVoidReason(
      context,
      title: 'Void this?',
      detail: '${l.kindLabel}: ${kes(l.amount.abs())}',
    );
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(payoutServiceProvider).voidShareEntry(l.id, reason);
      _refresh(ref);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    }
  }
}

void _refresh(WidgetRef ref) {
  ref.invalidate(farmerSharesProvider);
  ref.invalidate(farmerAccountProvider);
  refreshMoney(ref);
}

enum ShareAction {
  opening('opening', 'Opening shares', 'Save'),
  refund('refund', 'Refund shares', 'Refund'),
  transfer('transfer', 'Pass shares on', 'Pass on');

  final String path;
  final String title;
  final String action;

  const ShareAction(this.path, this.title, this.action);
}

/// Records opening shares, a refund, or shares passed to another member.
class ShareSheet extends ConsumerStatefulWidget {
  final String memberId;
  final String farmer;
  final ShareAction action;
  final FarmerShares shares;

  const ShareSheet._({
    required this.memberId,
    required this.farmer,
    required this.action,
    required this.shares,
  });

  static Future<void> show(
    BuildContext context, {
    required String memberId,
    required String farmer,
    required ShareAction action,
    required FarmerShares shares,
  }) => showFinanceSheet(
    context,
    ShareSheet._(
      memberId: memberId,
      farmer: farmer,
      action: action,
      shares: shares,
    ),
  );

  @override
  ConsumerState<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<ShareSheet> {
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final _reference = TextEditingController();
  late String? _typeId = _held.length == 1 ? _held.first.deductionTypeId : null;
  String? _accountId;
  MemberModel? _to;
  DateTime _date = DateTime.now();
  bool _busy = false;
  String? _error;

  ShareAction get _a => widget.action;

  /// The savings shares can come from (a refund or transfer).
  List<ShareBucket> get _held => [
    for (final b in widget.shares.buckets)
      if (b.balance > 0) b,
  ];

  @override
  void dispose() {
    for (final c in [_amount, _notes, _reference]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Give the amount.');
      return;
    }
    if (_a == ShareAction.refund && _accountId == null) {
      setState(() => _error = 'Choose the account the refund is paid from.');
      return;
    }
    if (_a == ShareAction.transfer && _to == null) {
      setState(() => _error = 'Choose the member who receives the shares.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(payoutServiceProvider)
          .recordShares(widget.memberId, _a.path, {
            'amount': amount,
            'date': FinanceService.iso(_date),
            'deduction_type_id': ?_typeId,
            if (_a == ShareAction.refund) 'cash_account_id': _accountId,
            if (_a == ShareAction.transfer) 'to_member_id': _to!.id,
            if (_reference.text.trim().isNotEmpty)
              'reference': _reference.text.trim(),
            if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
          });
      _refresh(ref);
      if (mounted) Navigator.pop(context);
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
    final from = _a == ShareAction.opening
        ? const <ShareBucket>[]
        : _held.length > 1
        ? _held
        : const <ShareBucket>[];
    return FinanceForm(
      title: _a.title,
      subtitle: switch (_a) {
        ShareAction.opening =>
          'Shares ${widget.farmer} held before DairyGo. They count towards the shares target.',
        ShareAction.refund =>
          '${widget.farmer} has ${kes(widget.shares.balance)}. Paid back from one of the Sacco\'s accounts.',
        ShareAction.transfer =>
          'From ${widget.farmer} (${kes(widget.shares.balance)}) to another member. No money moves.',
      },
      busy: _busy,
      error: _error,
      action: _a.action,
      onSave: _save,
      children: [
        if (from.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: _typeId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Which savings'),
            items: [
              for (final b in from)
                if (b.deductionTypeId != null)
                  DropdownMenuItem(
                    value: b.deductionTypeId,
                    child: Text(
                      '${b.name} (${kes(b.balance)})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            ],
            onChanged: (v) => setState(() => _typeId = v),
          ),
        if (_a == ShareAction.transfer)
          OutlinedButton.icon(
            onPressed: () async {
              final m = await FarmerPickerSheet.show(
                context,
                selectedMemberId: _to?.id,
              );
              if (m != null && m.id != widget.memberId) {
                setState(() => _to = m);
              }
            },
            icon: const Icon(Icons.person_search_rounded),
            label: Text(
              _to == null
                  ? 'Choose who receives them'
                  : 'To ${_to!.firstName} ${_to!.lastName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (_a == ShareAction.refund)
          DropdownButtonFormField<String>(
            initialValue: _accountId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Paid from'),
            items: [
              for (final a in accounts)
                DropdownMenuItem(
                  value: a.id,
                  child: Text(a.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _accountId = v),
          ),
        TextField(
          controller: _amount,
          keyboardType: moneyKeyboard,
          inputFormatters: moneyInput,
          decoration: const InputDecoration(labelText: 'Amount (KES)'),
        ),
        if (_a == ShareAction.refund)
          TextField(
            controller: _reference,
            decoration: const InputDecoration(
              labelText: 'M-Pesa, cheque or bank reference (optional)',
            ),
          ),
        TextField(
          controller: _notes,
          decoration: InputDecoration(
            labelText: 'Note (optional)',
            hintText: switch (_a) {
              ShareAction.opening => 'e.g. From the old share register',
              ShareAction.refund => 'e.g. Leaving the Sacco',
              ShareAction.transfer => 'e.g. To her daughter',
            },
          ),
        ),
        MoneyDateButton(
          label: 'Date',
          date: _date,
          onPicked: (d) => setState(() => _date = d ?? _date),
        ),
      ],
    );
  }
}
