import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/books_models.dart';
import '../../data/books_service.dart';
import '../books_providers.dart';
import '../widgets/books_widgets.dart';

class _Line {
  String? accountId;
  bool debit;
  final amount = TextEditingController();
  final memo = TextEditingController();

  _Line({required this.debit});

  double get value => double.tryParse(amount.text.replaceAll(',', '')) ?? 0;

  void dispose() {
    amount.dispose();
    memo.dispose();
  }
}

/// The accountant's own journal: a date, what it is for, and lines that
/// balance. Accounts kept from records (customers, farmers, pay due, cash
/// accounts) are not offered: those change only through their records.
class NewJournalScreen extends ConsumerStatefulWidget {
  const NewJournalScreen({super.key});

  @override
  ConsumerState<NewJournalScreen> createState() => _NewJournalScreenState();
}

class _NewJournalScreenState extends ConsumerState<NewJournalScreen> {
  late DateTime _date;
  final _memo = TextEditingController();
  final _reference = TextEditingController();
  final List<_Line> _lines = [_Line(debit: true), _Line(debit: false)];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _memo.dispose();
    _reference.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  double get _debits =>
      _lines.where((l) => l.debit).fold(0, (s, l) => s + l.value);
  double get _credits =>
      _lines.where((l) => !l.debit).fold(0, (s, l) => s + l.value);

  bool get _ready =>
      _memo.text.trim().length >= 3 &&
      _lines.length >= 2 &&
      _lines.every((l) => l.accountId != null && l.value > 0) &&
      (_debits - _credits).abs() < 0.005 &&
      _debits > 0;

  Future<void> _pickDate(DateTime? first) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: first ?? DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (day != null) setState(() => _date = day);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final j = await ref.read(booksServiceProvider).createJournal({
        'date': BooksService.iso(_date),
        'memo': _memo.text.trim(),
        if (_reference.text.trim().isNotEmpty)
          'reference': _reference.text.trim(),
        'lines': [
          for (final l in _lines)
            {
              'account_id': l.accountId,
              if (l.debit) 'debit': l.value else 'credit': l.value,
              if (l.memo.text.trim().isNotEmpty) 'memo': l.memo.text.trim(),
            },
        ],
      });
      refreshBooks(ref);
      if (!mounted) return;
      showBooksDone(context, 'Journal ${j.label} saved');
      context.pushReplacement('/books/journals/${j.id}');
    } catch (e) {
      if (mounted) showBooksError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(ledgerAccountsProvider);
    final start = ref.watch(booksStatusProvider).valueOrNull?.startDate;
    final diff = _debits - _credits;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New journal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: accounts.when(
        loading: () => const ListSkeleton(rows: 5),
        error: (e, _) => ErrorView(
          message: errorText(e),
          onRetry: () => ref.invalidate(ledgerAccountsProvider),
        ),
        data: (all) {
          final usable = all.where((a) => a.isActive && !a.kept).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              ReadableWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(start),
                      icon: const Icon(Icons.event_rounded, size: 18),
                      label: Text(
                        'Date: ${DateFormat('d MMM y').format(_date)}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _memo,
                      decoration: const InputDecoration(
                        labelText: 'What is it for?',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reference,
                      decoration: const InputDecoration(
                        labelText: 'Reference (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _lines.length; i++) ...[
                      _LineCard(
                        index: i,
                        line: _lines[i],
                        accounts: usable,
                        canRemove: _lines.length > 2,
                        onChanged: () => setState(() {}),
                        onRemove: () =>
                            setState(() => _lines.removeAt(i).dispose()),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(
                          () =>
                              _lines.add(_Line(debit: diff > 0 ? false : true)),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add a line'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    BooksCard(
                      border: diff.abs() < 0.005
                          ? AppColors.cardBorder
                          : AppColors.warning,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _total('Debits', _debits),
                            const SizedBox(height: 4),
                            _total('Credits', _credits),
                            const SizedBox(height: 6),
                            Text(
                              diff.abs() < 0.005
                                  ? 'Balanced'
                                  : 'Off by ${thousands(diff.abs())}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: diff.abs() < 0.005
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Customers, farmers\' accounts, pay due and cash accounts '
                      'follow their records, so they are not listed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _ready && !_saving ? _save : null,
                      child: Text(_saving ? 'Saving…' : 'Save journal'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _total(String label, double v) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(thousands(v), style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _LineCard extends StatelessWidget {
  final int index;
  final _Line line;
  final List<LedgerAccount> accounts;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _LineCard({
    required this.index,
    required this.line,
    required this.accounts,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => BooksCard(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Line ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: 'Remove line ${index + 1}',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: line.accountId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: [
                    for (final a in accounts)
                      DropdownMenuItem(
                        value: a.id,
                        child: Text(a.label, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) {
                    line.accountId = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Debit'),
                      selected: line.debit,
                      onSelected: (_) {
                        line.debit = true;
                        onChanged();
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Credit'),
                      selected: !line.debit,
                      onSelected: (_) {
                        line.debit = false;
                        onChanged();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: line.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Amount (KES)'),
                  onChanged: (_) => onChanged(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: line.memo,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
