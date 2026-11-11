import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../data/finance_models.dart';
import '../../data/finance_service.dart';
import '../finance_providers.dart';
import 'finance_sheets.dart';

/// Asks why something recorded in error is voided; null when cancelled.
Future<String?> askVoidReason(
  BuildContext context, {
  required String title,
  required String detail,
}) async {
  final controller = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detail),
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
  return reason;
}

/// Voids something after asking why, then refreshes the money screens.
Future<void> voidWithReason(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String detail,
  required Future<void> Function(String reason) run,
}) async {
  final reason = await askVoidReason(context, title: title, detail: detail);
  if (reason == null || !context.mounted) return;
  try {
    await run(reason);
    refreshMoney(ref);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }
}

/// A date button for the money forms.
class MoneyDateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateTime? first;
  final DateTime? last;
  final ValueChanged<DateTime?> onPicked;
  final bool clearable;

  const MoneyDateButton({
    super.key,
    required this.label,
    required this.date,
    required this.onPicked,
    this.first,
    this.last,
    this.clearable = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: first ?? DateTime(now.year - 2),
              lastDate: last ?? now,
              initialDate: date ?? now,
            );
            if (picked != null) onPicked(picked);
          },
          icon: const Icon(Icons.event_outlined),
          label: Text(
            '$label: ${date == null ? 'none' : FinanceService.iso(date!)}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      if (clearable && date != null)
        IconButton(
          tooltip: 'Clear',
          onPressed: () => onPicked(null),
          icon: const Icon(Icons.close_rounded),
        ),
    ],
  );
}

/// The Sacco's accounts to pick from, or a note to add one.
class _AccountPicker extends ConsumerWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _AccountPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts =
        ref.watch(cashAccountsProvider).valueOrNull?.active ??
        const <CashAccount>[];
    if (accounts.isEmpty) {
      return const Text(
        'Add an account first (Money → Accounts), such as the bank.',
        style: TextStyle(color: AppColors.error),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final a in accounts)
          DropdownMenuItem(
            value: a.id,
            child: Text(a.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

String? _text(TextEditingController c) =>
    c.text.trim().isEmpty ? null : c.text.trim();

/// Records money received besides milk sales.
class IncomeFormSheet extends ConsumerStatefulWidget {
  const IncomeFormSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showFinanceSheet(context, const IncomeFormSheet());

  @override
  ConsumerState<IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends ConsumerState<IncomeFormSheet> {
  final _amount = TextEditingController();
  final _payer = TextEditingController();
  final _reference = TextEditingController();
  final _description = TextEditingController();
  String? _categoryId;
  String? _accountId;
  DateTime _date = DateTime.now();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_amount, _payer, _reference, _description]) {
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
        _payer.text.trim().length < 2) {
      setState(
        () => _error = 'Fill in the category, account, amount and who paid.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(financeServiceProvider).recordIncome({
        'category_id': _categoryId,
        'cash_account_id': _accountId,
        'amount': amount,
        'payer': _payer.text.trim(),
        'date': FinanceService.iso(_date),
        'reference': ?_text(_reference),
        'description': ?_text(_description),
      });
      refreshMoney(ref);
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
          in ref.watch(incomeCategoriesProvider).valueOrNull ??
              const <ExpenseCategory>[])
        if (c.isActive) c,
    ];
    return FinanceForm(
      title: 'Record other income',
      subtitle:
          'Money received besides milk sales: interest, rent, items sold.',
      busy: _busy,
      error: _error,
      action: 'Save income',
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
        _AccountPicker(
          label: 'Received into',
          value: _accountId,
          onChanged: (v) => setState(() => _accountId = v),
        ),
        TextField(
          controller: _amount,
          keyboardType: moneyKeyboard,
          inputFormatters: moneyInput,
          decoration: const InputDecoration(labelText: 'Amount (KES)'),
        ),
        TextField(
          controller: _payer,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Received from',
            hintText: 'A person, bank or company',
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
        MoneyDateButton(
          label: 'Date',
          date: _date,
          onPicked: (d) => setState(() => _date = d ?? _date),
        ),
      ],
    );
  }
}

/// Adds or changes a supplier. Pops with the saved supplier.
class SupplierFormSheet extends ConsumerStatefulWidget {
  final Supplier? existing;

  const SupplierFormSheet({super.key, this.existing});

  static Future<Supplier?> show(BuildContext context, {Supplier? existing}) =>
      showFinanceSheet<Supplier>(
        context,
        SupplierFormSheet(existing: existing),
      );

  @override
  ConsumerState<SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends ConsumerState<SupplierFormSheet> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late bool _active = widget.existing?.isActive ?? true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Give the supplier a name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await ref
          .read(financeServiceProvider)
          .saveSupplier(widget.existing?.id, {
            'name': _name.text.trim(),
            'phone': _phone.text.trim(),
            'notes': _notes.text.trim(),
            if (widget.existing != null) 'is_active': _active,
          });
      refreshMoney(ref);
      if (mounted) Navigator.pop(context, s);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FinanceForm(
    title: widget.existing == null ? 'Add a supplier' : 'Change the supplier',
    subtitle:
        'Someone the Sacco pays: for bills, or money taken from farmers\' pay for them.',
    busy: _busy,
    error: _error,
    action: 'Save supplier',
    onSave: _save,
    children: [
      TextField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'e.g. Kiambu Agrovet, CIC Insurance',
        ),
      ),
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Phone (optional)'),
      ),
      TextField(
        controller: _notes,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Notes (optional)',
          hintText: 'Paybill, bank details, contact person',
        ),
      ),
      if (widget.existing != null)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _active,
          onChanged: _busy ? null : (v) => setState(() => _active = v),
          title: const Text('In use'),
        ),
    ],
  );
}

/// Records a bill from a supplier, to be paid later.
class BillFormSheet extends ConsumerStatefulWidget {
  final String? supplierId;

  const BillFormSheet({super.key, this.supplierId});

  static Future<void> show(BuildContext context, {String? supplierId}) =>
      showFinanceSheet(context, BillFormSheet(supplierId: supplierId));

  @override
  ConsumerState<BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends ConsumerState<BillFormSheet> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _description = TextEditingController();
  late String? _supplierId = widget.supplierId;
  String? _categoryId;
  DateTime _date = DateTime.now();
  DateTime? _due;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_amount, _reference, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (_supplierId == null ||
        _categoryId == null ||
        amount == null ||
        amount <= 0) {
      setState(
        () => _error = 'Fill in the supplier, what it is for and the amount.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(financeServiceProvider).recordBill({
        'supplier_id': _supplierId,
        'category_id': _categoryId,
        'amount': amount,
        'date': FinanceService.iso(_date),
        if (_due != null) 'due_date': FinanceService.iso(_due!),
        'reference': ?_text(_reference),
        'description': ?_text(_description),
      });
      refreshMoney(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers =
        ref.watch(suppliersProvider).valueOrNull?.active ?? const <Supplier>[];
    final categories = [
      for (final c
          in ref.watch(expenseCategoriesProvider).valueOrNull ??
              const <ExpenseCategory>[])
        if (c.isActive) c,
    ];
    final now = DateTime.now();
    return FinanceForm(
      title: 'Record a bill',
      subtitle:
          'Bought now, paid later. It counts as spending on the bill\'s date.',
      busy: _busy,
      error: _error,
      action: 'Save bill',
      onSave: _save,
      children: [
        if (widget.supplierId == null)
          DropdownButtonFormField<String>(
            initialValue: _supplierId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Supplier'),
            items: [
              for (final s in suppliers)
                DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _supplierId = v),
          ),
        DropdownButtonFormField<String>(
          initialValue: _categoryId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'What it is for'),
          items: [
            for (final c in categories)
              DropdownMenuItem(
                value: c.id,
                child: Text(c.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _categoryId = v),
        ),
        TextField(
          controller: _amount,
          keyboardType: moneyKeyboard,
          inputFormatters: moneyInput,
          decoration: const InputDecoration(labelText: 'Amount (KES)'),
        ),
        TextField(
          controller: _reference,
          decoration: const InputDecoration(
            labelText: 'Invoice number (optional)',
          ),
        ),
        TextField(
          controller: _description,
          decoration: const InputDecoration(labelText: 'Details (optional)'),
        ),
        MoneyDateButton(
          label: 'Bill date',
          date: _date,
          onPicked: (d) => setState(() => _date = d ?? _date),
        ),
        MoneyDateButton(
          label: 'Due',
          date: _due,
          first: _date,
          last: DateTime(now.year + 2),
          clearable: true,
          onPicked: (d) => setState(() => _due = d),
        ),
      ],
    );
  }
}

/// Pays a bill (in full or part) or pays over money held for a supplier.
class SupplierPaymentSheet extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final double most;
  final Future<void> Function(WidgetRef ref, Map<String, dynamic> body) send;

  const SupplierPaymentSheet._({
    required this.title,
    required this.subtitle,
    required this.most,
    required this.send,
  });

  static Future<void> payBill(
    BuildContext context,
    Bill bill,
  ) => showFinanceSheet(
    context,
    SupplierPaymentSheet._(
      title: 'Pay the bill',
      subtitle:
          '${bill.supplier}: ${kes(bill.unpaid)} of ${kes(bill.amount)} unpaid',
      most: bill.unpaid,
      send: (ref, body) =>
          ref.read(financeServiceProvider).payBill(bill.id, body),
    ),
  );

  static Future<void> payOver(BuildContext context, Supplier s) =>
      showFinanceSheet(
        context,
        SupplierPaymentSheet._(
          title: 'Pay over to ${s.name}',
          subtitle:
              '${kes(s.held)} taken from farmers\' pay for them is waiting',
          most: s.held,
          send: (ref, body) =>
              ref.read(financeServiceProvider).payOver(s.id, body),
        ),
      );

  @override
  ConsumerState<SupplierPaymentSheet> createState() =>
      _SupplierPaymentSheetState();
}

class _SupplierPaymentSheetState extends ConsumerState<SupplierPaymentSheet> {
  late final _amount = TextEditingController(
    text: widget.most == widget.most.roundToDouble()
        ? widget.most.toStringAsFixed(0)
        : widget.most.toStringAsFixed(2),
  );
  final _reference = TextEditingController();
  String? _accountId;
  DateTime _date = DateTime.now();
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
    if (_accountId == null || amount == null || amount <= 0) {
      setState(() => _error = 'Fill in the account and the amount.');
      return;
    }
    if (amount > widget.most + 0.005) {
      setState(() => _error = 'No more than ${kes(widget.most)}.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.send(ref, {
        'cash_account_id': _accountId,
        'amount': amount,
        'date': FinanceService.iso(_date),
        'reference': ?_text(_reference),
      });
      refreshMoney(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FinanceForm(
    title: widget.title,
    subtitle: widget.subtitle,
    busy: _busy,
    error: _error,
    action: 'Save payment',
    onSave: _save,
    children: [
      _AccountPicker(
        label: 'Paid from',
        value: _accountId,
        onChanged: (v) => setState(() => _accountId = v),
      ),
      TextField(
        controller: _amount,
        keyboardType: moneyKeyboard,
        inputFormatters: moneyInput,
        decoration: const InputDecoration(labelText: 'Amount (KES)'),
      ),
      TextField(
        controller: _reference,
        decoration: const InputDecoration(
          labelText: 'M-Pesa, cheque or bank reference (optional)',
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
