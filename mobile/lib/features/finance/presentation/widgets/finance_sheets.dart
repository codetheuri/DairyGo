import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_call.dart';
import '../../data/finance_models.dart';
import '../../data/finance_service.dart';
import '../finance_providers.dart';

final _money = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
const _moneyKeyboard = TextInputType.numberWithOptions(decimal: true);

/// The parts every finance form shares: a title, the fields, an error and a
/// save button, above the keyboard.
class _Form extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String? error;
  final bool busy;
  final String action;
  final VoidCallback onSave;

  const _Form({
    required this.title,
    this.subtitle,
    required this.children,
    this.error,
    required this.busy,
    required this.action,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 12),
          for (final c in children)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: c),
          if (error != null)
            Text(error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 8),
          FilledButton(onPressed: busy ? null : onSave, child: Text(action)),
        ],
      ),
    ),
  );
}

Future<T?> _sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => child,
    );

/// Records money the Sacco spent.
class ExpenseFormSheet extends ConsumerStatefulWidget {
  const ExpenseFormSheet({super.key});

  static Future<void> show(BuildContext context) =>
      _sheet(context, const ExpenseFormSheet());

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final _amount = TextEditingController();
  final _payee = TextEditingController();
  final _reference = TextEditingController();
  final _description = TextEditingController();
  String? _categoryId;
  String? _accountId;
  DateTime _date = DateTime.now();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_amount, _payee, _reference, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (_categoryId == null ||
        _accountId == null ||
        amount == null ||
        amount <= 0 ||
        _payee.text.trim().length < 2) {
      setState(
        () =>
            _error = 'Fill in the category, account, amount and who was paid.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(financeServiceProvider).recordExpense({
        'category_id': _categoryId,
        'cash_account_id': _accountId,
        'amount': amount,
        'payee': _payee.text.trim(),
        'date': FinanceService.iso(_date),
        if (_reference.text.trim().isNotEmpty)
          'reference': _reference.text.trim(),
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim(),
      });
      ref.invalidate(expensesProvider);
      ref.invalidate(cashAccountsProvider);
      ref.invalidate(financeSummaryProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      for (final c
          in ref.watch(expenseCategoriesProvider).valueOrNull ??
              const <ExpenseCategory>[])
        if (c.isActive) c,
    ];
    final accounts =
        ref.watch(cashAccountsProvider).valueOrNull?.active ??
        const <CashAccount>[];
    return _Form(
      title: 'Record an expense',
      busy: _busy,
      error: _error,
      action: 'Save expense',
      onSave: _save,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _categoryId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            for (final c in categories)
              DropdownMenuItem(
                value: c.id,
                child: Text(c.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _categoryId = v),
        ),
        if (accounts.isEmpty)
          const Text(
            'Add an account first (Accounts tab), such as Petty cash.',
            style: TextStyle(color: AppColors.error),
          )
        else
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
          keyboardType: _moneyKeyboard,
          inputFormatters: _money,
          decoration: const InputDecoration(labelText: 'Amount (KES)'),
        ),
        TextField(
          controller: _payee,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Paid to',
            hintText: 'A person, shop or company',
          ),
        ),
        TextField(
          controller: _reference,
          decoration: const InputDecoration(
            labelText: 'Receipt or M-Pesa code (optional)',
          ),
        ),
        TextField(
          controller: _description,
          decoration: const InputDecoration(labelText: 'What for (optional)'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(now.year - 2),
              lastDate: now,
              initialDate: _date,
            );
            if (picked != null) setState(() => _date = picked);
          },
          icon: const Icon(Icons.event_outlined),
          label: Text('Date: ${FinanceService.iso(_date)}'),
        ),
      ],
    );
  }
}

/// Adds a place the Sacco keeps money.
class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key});

  static Future<void> show(BuildContext context) =>
      _sheet(context, const AccountFormSheet());

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _opening = TextEditingController();
  String _kind = 'CASH';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _number, _opening]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(financeServiceProvider).saveAccount(null, {
        'name': _name.text.trim(),
        'kind': _kind,
        if (_number.text.trim().isNotEmpty)
          'account_number': _number.text.trim(),
        'opening_balance': double.tryParse(_opening.text.trim()) ?? 0,
      });
      ref.invalidate(cashAccountsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _Form(
    title: 'Add an account',
    subtitle: 'Where the Sacco keeps money.',
    busy: _busy,
    error: _error,
    action: 'Add account',
    onSave: _save,
    children: [
      Wrap(
        spacing: 8,
        children: [
          for (final (v, l) in const [
            ('CASH', 'Cash'),
            ('BANK', 'Bank'),
            ('MPESA', 'M-Pesa'),
          ])
            ChoiceChip(
              label: Text(l),
              selected: _kind == v,
              showCheckmark: false,
              onSelected: (_) => setState(() => _kind = v),
            ),
        ],
      ),
      TextField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Name',
          hintText: switch (_kind) {
            'BANK' => 'e.g. Equity Bank',
            'MPESA' => 'e.g. M-Pesa paybill',
            _ => 'e.g. Petty cash',
          },
        ),
      ),
      if (_kind != 'CASH')
        TextField(
          controller: _number,
          decoration: InputDecoration(
            labelText: _kind == 'BANK'
                ? 'Account number (optional)'
                : 'Till or paybill (optional)',
          ),
        ),
      TextField(
        controller: _opening,
        keyboardType: _moneyKeyboard,
        inputFormatters: _money,
        decoration: const InputDecoration(labelText: 'Money in it today (KES)'),
      ),
    ],
  );
}

/// Moves money between two accounts, e.g. topping up petty cash.
class TransferSheet extends ConsumerStatefulWidget {
  final List<CashAccount> accounts;

  const TransferSheet({super.key, required this.accounts});

  static Future<void> show(BuildContext context, List<CashAccount> accounts) =>
      _sheet(context, TransferSheet(accounts: accounts));

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  String? _from;
  String? _to;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (_from == null || _to == null || amount == null || amount <= 0) {
      setState(() => _error = 'Choose both accounts and the amount.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(financeServiceProvider).recordTransfer({
        'from_account_id': _from,
        'to_account_id': _to,
        'amount': amount,
        if (_reference.text.trim().isNotEmpty)
          'reference': _reference.text.trim(),
      });
      ref.invalidate(cashAccountsProvider);
      ref.invalidate(cashbookProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  DropdownButtonFormField<String> _pick(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final a in widget.accounts)
        DropdownMenuItem(
          value: a.id,
          child: Text(a.name, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged,
  );

  @override
  Widget build(BuildContext context) => _Form(
    title: 'Move money',
    subtitle: 'For example, top up petty cash from the bank.',
    busy: _busy,
    error: _error,
    action: 'Move money',
    onSave: _save,
    children: [
      _pick('From', _from, (v) => setState(() => _from = v)),
      _pick('To', _to, (v) => setState(() => _to = v)),
      TextField(
        controller: _amount,
        keyboardType: _moneyKeyboard,
        inputFormatters: _money,
        decoration: const InputDecoration(labelText: 'Amount (KES)'),
      ),
      TextField(
        controller: _reference,
        decoration: const InputDecoration(
          labelText: 'Reference (optional)',
          hintText: 'e.g. cheque number',
        ),
      ),
    ],
  );
}

/// Asks why an expense is voided, then voids it.
class VoidExpenseDialog {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    Expense e,
    ({Month month, String? categoryId}) query,
  ) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void this expense?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${e.payee}: KES ${e.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(financeServiceProvider).voidExpense(e.id, reason);
      ref.invalidate(expensesProvider(query));
      ref.invalidate(cashAccountsProvider);
      ref.invalidate(financeSummaryProvider);
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText(err))));
      }
    }
  }
}
