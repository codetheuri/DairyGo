import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_call.dart';
import '../../data/payout_models.dart';
import '../payout_providers.dart';

/// Adds or changes a deduction, in plain questions: how much, how often,
/// who pays it. The fields shown follow the answers.
class DeductionFormSheet extends ConsumerStatefulWidget {
  final DeductionType? existing;

  const DeductionFormSheet({super.key, this.existing});

  static Future<void> show(BuildContext context, {DeductionType? existing}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => DeductionFormSheet(existing: existing),
      );

  @override
  ConsumerState<DeductionFormSheet> createState() => _DeductionFormSheetState();
}

class _Band {
  final upTo = TextEditingController();
  final fee = TextEditingController();

  void dispose() {
    upTo.dispose();
    fee.dispose();
  }
}

class _DeductionFormSheetState extends ConsumerState<DeductionFormSheet> {
  late final DeductionType? d = widget.existing;
  late final _name = TextEditingController(text: d?.name ?? '');
  late final _amount = TextEditingController(
    text: d == null || d!.amount == 0 ? '' : _plain(d!.amount),
  );
  late final _target = TextEditingController(
    text: d?.target == null ? '' : _plain(d!.target!),
  );
  late final _priority = TextEditingController(text: '${d?.priority ?? 50}');
  late String _method = d?.method ?? 'FIXED';
  late String _base = d?.base ?? 'GROSS';
  late String _frequency = d?.frequency ?? 'EVERY_RUN';
  late String _appliesTo = d?.appliesTo ?? 'ALL';
  late bool _savings = d?.isSavings ?? false;
  late bool _active = d?.isActive ?? true;
  final List<_Band> _bands = [];
  bool _busy = false;
  String? _error;

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void initState() {
    super.initState();
    for (final t in d?.tiers ?? const <FeeBand>[]) {
      final b = _Band();
      b.upTo.text = t.upTo == null ? '' : _plain(t.upTo!);
      b.fee.text = _plain(t.fee);
      _bands.add(b);
    }
    if (_bands.isEmpty) _bands.add(_Band());
  }

  @override
  void dispose() {
    for (final c in [_name, _amount, _target, _priority]) {
      c.dispose();
    }
    for (final b in _bands) {
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final tiers = <Map<String, dynamic>>[];
    if (_method == 'TIERED') {
      for (final b in _bands) {
        final fee = double.tryParse(b.fee.text.trim());
        if (fee == null) continue;
        final upTo = double.tryParse(b.upTo.text.trim());
        tiers.add({'up_to': ?upTo, 'fee': fee});
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(payoutServiceProvider).saveDeductionType(d?.id, {
        'name': _name.text.trim(),
        'method': _method,
        'base': _method == 'PERCENT' || _method == 'TIERED' ? _base : 'GROSS',
        'amount': double.tryParse(_amount.text.trim()) ?? 0,
        if (_method == 'TIERED') 'tiers': tiers,
        'frequency': _frequency,
        if (_frequency == 'UNTIL_TARGET')
          'target_amount': double.tryParse(_target.text.trim()) ?? 0,
        'applies_to': _appliesTo,
        'priority': int.tryParse(_priority.text.trim()) ?? 50,
        'is_savings': _savings,
        'is_active': _active,
      });
      ref.invalidate(deductionTypesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await ref.read(payoutServiceProvider).deleteDeductionType(d!.id);
      ref.invalidate(deductionTypesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _choices(
    List<(String, String)> options,
    String value,
    void Function(String) onPick,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (v, label) in options)
        ChoiceChip(
          label: Text(label),
          selected: value == v,
          showCheckmark: false,
          onSelected: _busy ? null : (_) => setState(() => onPick(v)),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final number = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
    final numKeyboard = const TextInputType.numberWithOptions(decimal: true);
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
              d == null ? 'Add a deduction' : 'Change ${d!.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              enabled: !_busy,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Shares, Welfare, Transport',
              ),
            ),
            _label('How much?'),
            _choices(
              const [
                ('FIXED', 'A fixed amount'),
                ('PERCENT', 'A percentage'),
                ('PER_LITRE', 'Per litre'),
                ('TIERED', 'By bands'),
              ],
              _method,
              (v) => _method = v,
            ),
            const SizedBox(height: 10),
            if (_method != 'TIERED')
              TextField(
                controller: _amount,
                enabled: !_busy,
                keyboardType: numKeyboard,
                inputFormatters: number,
                decoration: InputDecoration(
                  labelText: switch (_method) {
                    'PERCENT' => 'Percent',
                    'PER_LITRE' => 'KES per litre',
                    _ => 'Amount in KES',
                  },
                ),
              ),
            if (_method == 'TIERED') ...[
              const Text(
                'Fee by amount, lowest band first. Leave "Up to" empty on the last band for everything above.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              for (final b in _bands)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: b.upTo,
                          keyboardType: numKeyboard,
                          inputFormatters: number,
                          decoration: const InputDecoration(
                            labelText: 'Up to KES',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: b.fee,
                          keyboardType: numKeyboard,
                          inputFormatters: number,
                          decoration: const InputDecoration(
                            labelText: 'Fee KES',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _bands.add(_Band())),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add band'),
                ),
              ),
            ],
            if (_method == 'PERCENT' || _method == 'TIERED') ...[
              _label('Worked out on'),
              _choices(
                const [('GROSS', 'The milk value'), ('NET', 'The money sent')],
                _base,
                (v) => _base = v,
              ),
            ],
            _label('How often?'),
            _choices(
              const [
                ('EVERY_RUN', 'Every pay run'),
                ('ONCE_PER_MEMBER', 'Once per farmer'),
                ('ONCE_PER_YEAR', 'Once a year'),
                ('UNTIL_TARGET', 'Until a total'),
              ],
              _frequency,
              (v) => _frequency = v,
            ),
            if (_frequency == 'UNTIL_TARGET') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _target,
                enabled: !_busy,
                keyboardType: numKeyboard,
                inputFormatters: number,
                decoration: const InputDecoration(
                  labelText: 'Stop when a farmer has paid (KES)',
                  hintText: 'e.g. 5000',
                ),
              ),
            ],
            _label('Who pays it?'),
            _choices(
              const [('ALL', 'Every farmer'), ('ENROLLED', 'Chosen farmers')],
              _appliesTo,
              (v) => _appliesTo = v,
            ),
            if (_appliesTo == 'ENROLLED')
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Add farmers to it from their account (Farmer → Account → Deductions).',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _savings,
              onChanged: _busy ? null : (v) => setState(() => _savings = v),
              title: const Text('Savings (like shares)'),
              subtitle: const Text(
                'Belongs to the farmer. Taken only from what is left, never as a debt.',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: _busy ? null : (v) => setState(() => _active = v),
              title: const Text('Switched on'),
            ),
            TextField(
              controller: _priority,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Order (lower is taken first)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('Save'),
            ),
            if (d != null)
              TextButton(
                onPressed: _busy ? null : _delete,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete (only if never taken)'),
              ),
          ],
        ),
      ),
    );
  }
}
