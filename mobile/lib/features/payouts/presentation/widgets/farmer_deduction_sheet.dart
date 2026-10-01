import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../data/payout_models.dart';
import '../payout_providers.dart';

/// How one deduction applies to one farmer: whether they pay it, and their
/// own amount or target (for example a loan repaid at KES 1,000 a month).
class FarmerDeductionSheet extends ConsumerStatefulWidget {
  final String memberId;
  final FarmerDeduction deduction;

  const FarmerDeductionSheet({
    super.key,
    required this.memberId,
    required this.deduction,
  });

  static Future<void> show(
    BuildContext context, {
    required String memberId,
    required FarmerDeduction deduction,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) =>
        FarmerDeductionSheet(memberId: memberId, deduction: deduction),
  );

  @override
  ConsumerState<FarmerDeductionSheet> createState() =>
      _FarmerDeductionSheetState();
}

class _FarmerDeductionSheetState extends ConsumerState<FarmerDeductionSheet> {
  late bool _applies = widget.deduction.applies;
  late final _amount = TextEditingController(
    text: widget.deduction.amount == widget.deduction.type.amount
        ? ''
        : thousands(widget.deduction.amount).replaceAll(',', ''),
  );
  late final _target = TextEditingController(
    text:
        widget.deduction.target == null ||
            widget.deduction.target == widget.deduction.type.target
        ? ''
        : widget.deduction.target!.toStringAsFixed(0),
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(payoutServiceProvider)
          .setFarmerDeduction(
            widget.memberId,
            widget.deduction.type.id,
            applies: _applies,
            amount: double.tryParse(_amount.text.trim()) ?? 0,
            target: double.tryParse(_target.text.trim()) ?? 0,
          );
      ref.invalidate(farmerDeductionsProvider(widget.memberId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.deduction.type;
    final number = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
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
              t.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${t.howMuch} · ${t.howOften}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _applies,
              onChanged: _busy ? null : (v) => setState(() => _applies = v),
              title: const Text('This farmer pays it'),
              subtitle: Text(
                t.appliesTo == 'ALL'
                    ? 'Every farmer pays it unless switched off here.'
                    : 'Only farmers added here pay it.',
              ),
            ),
            if (_applies && t.method != 'TIERED') ...[
              TextField(
                controller: _amount,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: number,
                decoration: InputDecoration(
                  labelText: t.method == 'PERCENT'
                      ? 'Their percentage (optional)'
                      : 'Their amount in KES (optional)',
                  hintText: 'Usual: ${t.howMuch}',
                ),
              ),
              if (t.frequency == 'UNTIL_TARGET') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _target,
                  enabled: !_busy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: number,
                  decoration: InputDecoration(
                    labelText: 'Their target in KES (optional)',
                    hintText: t.target == null
                        ? 'e.g. a loan of 20000'
                        : 'Usual: ${kes(t.target!, cents: false)}',
                  ),
                ),
              ],
              const SizedBox(height: 4),
              const Text(
                'Leave empty to use the usual amount.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
