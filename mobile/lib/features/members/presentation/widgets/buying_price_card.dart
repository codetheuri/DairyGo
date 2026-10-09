import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/prices/member_price.dart';
import '../../data/prices/member_price_providers.dart';

String _day(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// What a farmer's milk is bought at: the Sacco's price or their own, with
/// the farmer's price history. Admins can give the farmer their own price.
class BuyingPriceCard extends ConsumerWidget {
  final String memberId;
  final String farmerName;

  const BuyingPriceCard({
    super.key,
    required this.memberId,
    required this.farmerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSet =
        ref.watch(authControllerProvider).valueOrNull?.user?.canSetPrice ??
        false;
    final async = ref.watch(memberPricesProvider(memberId));
    final p = async.valueOrNull;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Buying price',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            if (p == null)
              Text(
                async.hasError ? errorText(async.error!) : 'Loading…',
                style: const TextStyle(color: AppColors.textSecondary),
              )
            else ...[
              Text(
                p.own
                    ? 'Own price ${kes(p.today)}/L'
                    : 'Sacco price ${kes(p.today)}/L',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: p.own ? AppColors.secondary : AppColors.primary,
                ),
              ),
              if (p.own)
                Text(
                  'The Sacco price is ${kes(p.saccoToday)}/L.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              for (final r in p.schedule.take(4))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'From ${_day(r.from)}: '
                          '${r.price == null ? 'Sacco price' : '${kes(r.price!)}/L'}'
                          '${(r.reason ?? '').isEmpty ? '' : ' · ${r.reason}'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      if (canSet)
                        InkWell(
                          onTap: () => _cancel(context, ref, r),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                              semanticLabel: 'Cancel this price',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
            if (canSet) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: p == null
                    ? null
                    : () =>
                          SetPriceSheet.show(context, memberId, farmerName, p),
                icon: const Icon(Icons.price_change_outlined, size: 18),
                label: const Text('Set own price'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    MemberPriceRow row,
  ) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this price?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unpaid milk from that date is repriced. Paid months do not change.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            TextField(
              controller: reason,
              decoration: const InputDecoration(labelText: 'Reason *'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel price'),
          ),
        ],
      ),
    );
    final why = reason.text.trim();
    reason.dispose();
    if (ok != true || !context.mounted) return;
    try {
      final n = await ref
          .read(memberPriceServiceProvider)
          .cancel(memberId, row.id, why);
      ref.invalidate(memberPricesProvider(memberId));
      if (context.mounted) _say(context, n);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    }
  }
}

void _say(
  BuildContext context,
  int repriced,
) => ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      repriced == 0
          ? 'Saved'
          : 'Saved. $repriced milk records repriced. Work out any draft pay run again.',
    ),
    backgroundColor: AppColors.success,
  ),
);

/// Gives a farmer their own price from a date, or puts them back on the
/// Sacco's price. Shows how many unpaid milk records will be repriced first.
class SetPriceSheet extends ConsumerStatefulWidget {
  final String memberId;
  final String farmerName;
  final MemberPrices current;

  const SetPriceSheet({
    super.key,
    required this.memberId,
    required this.farmerName,
    required this.current,
  });

  static Future<void> show(
    BuildContext context,
    String memberId,
    String farmerName,
    MemberPrices current,
  ) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => SetPriceSheet(
      memberId: memberId,
      farmerName: farmerName,
      current: current,
    ),
  );

  @override
  ConsumerState<SetPriceSheet> createState() => _SetPriceSheetState();
}

class _SetPriceSheetState extends ConsumerState<SetPriceSheet> {
  final _price = TextEditingController();
  final _reason = TextEditingController();
  bool _backToSacco = false;
  DateTime _from = DateTime.now();
  int? _willChange;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    _reason.dispose();
    super.dispose();
  }

  double? get _priceValue =>
      double.tryParse(_price.text.trim().replaceAll(',', ''));

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: 'Price starts on',
    );
    if (picked != null) {
      setState(() {
        _from = picked;
        _willChange = null;
      });
    }
  }

  Future<void> _submit() async {
    final price = _backToSacco ? null : _priceValue;
    if (!_backToSacco && (price == null || price <= 0)) {
      setState(() => _error = 'Enter the price per litre.');
      return;
    }
    if (_reason.text.trim().length < 3) {
      setState(() => _error = 'Say why, e.g. Agreed at the board meeting.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final service = ref.read(memberPriceServiceProvider);
    try {
      // First say how many records change; the second tap saves.
      if (_willChange == null) {
        final n = await service.setPrice(
          widget.memberId,
          price: price,
          from: _from,
          reason: _reason.text.trim(),
          preview: true,
        );
        setState(() => _willChange = n);
        return;
      }
      final n = await service.setPrice(
        widget.memberId,
        price: price,
        from: _from,
        reason: _reason.text.trim(),
      );
      ref.invalidate(memberPricesProvider(widget.memberId));
      if (mounted) {
        Navigator.pop(context);
        _say(context, n);
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final change = _willChange;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Buying price for ${widget.farmerName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            'The Sacco price is ${kes(widget.current.saccoToday)}/L.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Own price'),
                selected: !_backToSacco,
                showCheckmark: false,
                onSelected: (_) => setState(() {
                  _backToSacco = false;
                  _willChange = null;
                }),
              ),
              ChoiceChip(
                label: const Text('Back to the Sacco price'),
                selected: _backToSacco,
                showCheckmark: false,
                onSelected: (_) => setState(() {
                  _backToSacco = true;
                  _willChange = null;
                }),
              ),
            ],
          ),
          if (!_backToSacco) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() => _willChange = null),
              decoration: const InputDecoration(
                labelText: 'Price per litre',
                prefixText: 'KES ',
              ),
            ),
          ],
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_rounded, color: AppColors.primary),
            title: Text(
              'From ${_day(_from)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Unpaid milk from this day is repriced.'),
            trailing: TextButton(
              onPressed: _pickDate,
              child: const Text('Change'),
            ),
          ),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(
              labelText: 'Reason *',
              hintText: 'e.g. Agreed at the board meeting',
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentMint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                change == 0
                    ? 'No milk already recorded changes price.'
                    : '$change milk records from ${_day(_from)} will be repriced. Paid months do not change.',
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(change == null ? 'Check' : 'Save price'),
          ),
        ],
      ),
    );
  }
}
