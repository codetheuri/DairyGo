import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/prices/customer_price.dart';
import '../controllers/customer_controller.dart';

String _day(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// A customer's price per litre and its history. Admins change it from a
/// date; the customer's sales from then are repriced (see the sheet).
class CustomerPriceCard extends ConsumerWidget {
  final String customerId;
  final String customerName;

  const CustomerPriceCard({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canChange =
        ref
            .watch(authControllerProvider)
            .valueOrNull
            ?.user
            ?.canChangeCustomerPrices ??
        false;
    final async = ref.watch(customerPricesProvider(customerId));
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
              'Price',
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
                p.today == null ? 'No agreed price' : '${kes(p.today!)}/L',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.primary,
                ),
              ),
              for (final r in p.schedule)
                _HistoryRow(
                  row: r,
                  onCancel: canChange
                      ? () => ChangeCustomerPriceSheet.show(
                          context,
                          customerId: customerId,
                          customerName: customerName,
                          prices: p,
                          cancelling: r,
                        )
                      : null,
                ),
              for (final r in p.cancelled) _HistoryRow(row: r),
            ],
            if (canChange) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: p == null
                    ? null
                    : () => ChangeCustomerPriceSheet.show(
                        context,
                        customerId: customerId,
                        customerName: customerName,
                        prices: p,
                      ),
                icon: const Icon(Icons.price_change_outlined, size: 18),
                label: const Text('Change price'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final CustomerPriceRow row;
  final VoidCallback? onCancel;

  const _HistoryRow({required this.row, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final cancelled = row.voidReason != null;
    final details = [
      if ((row.reason ?? '').isNotEmpty) row.reason!,
      if ((row.setBy ?? '').isNotEmpty) 'by ${row.setBy}',
      if (cancelled) 'cancelled: ${row.voidReason}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'From ${_day(row.from)}: ${kes(row.price)}/L',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (details.isNotEmpty) TextSpan(text: '\n$details'),
                ],
              ),
              style: TextStyle(
                fontSize: 12,
                color: cancelled ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ),
          if (onCancel != null)
            InkWell(
              onTap: onCancel,
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
    );
  }
}

/// Changes a customer's price from a date, or ([cancelling]) cancels one
/// entered in error. "Check" first says what changes; when some of the
/// customer's sales were paid in full at the old price, it asks whether to
/// reprice those too.
class ChangeCustomerPriceSheet extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final CustomerPrices prices;
  final CustomerPriceRow? cancelling;

  const ChangeCustomerPriceSheet({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.prices,
    this.cancelling,
  });

  static Future<void> show(
    BuildContext context, {
    required String customerId,
    required String customerName,
    required CustomerPrices prices,
    CustomerPriceRow? cancelling,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => ChangeCustomerPriceSheet(
      customerId: customerId,
      customerName: customerName,
      prices: prices,
      cancelling: cancelling,
    ),
  );

  @override
  ConsumerState<ChangeCustomerPriceSheet> createState() =>
      _ChangeCustomerPriceSheetState();
}

class _ChangeCustomerPriceSheetState
    extends ConsumerState<ChangeCustomerPriceSheet> {
  final _price = TextEditingController();
  final _reason = TextEditingController();
  late DateTime _from = _today();
  RepriceSummary? _check;
  bool _includePaid = false;
  bool _busy = false;
  String? _error;

  bool get _cancel => widget.cancelling != null;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    _price.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _changed() => setState(() {
    _check = null;
    _includePaid = false;
  });

  Future<void> _pickDate() async {
    final first = widget.prices.firstDay;
    final picked = await showDatePicker(
      context: context,
      initialDate: _from.isBefore(first) ? first : _from,
      firstDate: first,
      lastDate: DateTime(_from.year + 1, 12, 31),
      helpText: 'Price starts on',
    );
    if (picked != null) {
      _from = picked;
      _changed();
    }
  }

  Future<RepriceSummary> _send({required bool preview}) {
    final service = ref.read(customerPriceServiceProvider);
    final reason = _reason.text.trim();
    if (_cancel) {
      return service.cancel(
        widget.customerId,
        widget.cancelling!.id,
        reason: reason,
        includePaid: _includePaid,
        preview: preview,
      );
    }
    return service.setPrice(
      widget.customerId,
      price: double.parse(_price.text.trim().replaceAll(',', '')),
      from: _from,
      reason: reason,
      includePaid: _includePaid,
      preview: preview,
    );
  }

  Future<void> _submit() async {
    final price = double.tryParse(_price.text.trim().replaceAll(',', ''));
    if (!_cancel && (price == null || price <= 0)) {
      setState(() => _error = 'Enter the price per litre.');
      return;
    }
    if (_reason.text.trim().length < 3) {
      setState(
        () => _error = _cancel
            ? 'Say why it is cancelled.'
            : 'Say why, e.g. New contract from October.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // First say what changes; the second tap saves.
      if (_check == null) {
        final check = await _send(preview: true);
        setState(() => _check = check);
        return;
      }
      final done = await _send(preview: false);
      ref.invalidate(customerPricesProvider(widget.customerId));
      ref.invalidate(customerDetailProvider(widget.customerId));
      ref.invalidate(customerStatementProvider);
      ref.invalidate(customerBalancesProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              done.repriced == 0
                  ? 'Saved'
                  : 'Saved. ${done.repriced} ${done.repriced == 1 ? 'sale' : 'sales'} repriced.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _owes(double change) => change == 0
      ? 'what they owe does not change'
      : change > 0
      ? 'they will owe ${kes(change)} more'
      : 'they will owe ${kes(-change)} less';

  @override
  Widget build(BuildContext context) {
    final check = _check;
    final c = widget.cancelling;
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
            _cancel
                ? 'Cancel the price from ${_day(c!.from)}'
                : 'Price for ${widget.customerName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            _cancel
                ? '${kes(c!.price)}/L, entered in error. Their sales go back to the price before it.'
                : widget.prices.today == null
                ? 'No agreed price yet.'
                : 'Now ${kes(widget.prices.today!)}/L.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (!_cancel) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => _changed(),
              decoration: const InputDecoration(
                labelText: 'New price per litre',
                prefixText: 'KES ',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.event_rounded,
                color: AppColors.primary,
              ),
              title: Text(
                'From ${_day(_from)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Their sales from this day are repriced. '
                'Earliest: ${_day(widget.prices.firstDay)}.',
              ),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Change'),
              ),
            ),
          ],
          TextField(
            controller: _reason,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Reason *',
              hintText: _cancel
                  ? 'e.g. Wrong price typed'
                  : 'e.g. New contract from October',
            ),
          ),
          if (check != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentMint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                [
                  check.creditSales == 0
                      ? 'No unpaid sales change price.'
                      : '${check.creditSales} ${check.creditSales == 1 ? 'sale' : 'sales'} not fully paid will be repriced: ${_owes(check.creditChange)}.',
                  if (check.handtyped > 0)
                    '${check.handtyped} ${check.handtyped == 1 ? 'sale has a price' : 'sales have prices'} typed on the day; they stay as they are.',
                ].join(' '),
              ),
            ),
            if (check.paidSales > 0) ...[
              const SizedBox(height: 12),
              Text(
                '${check.paidSales} ${check.paidSales == 1 ? 'sale was' : 'sales were'} paid in full at the old price. Reprice ${check.paidSales == 1 ? 'it' : 'them'} too?',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('No, leave them'),
                    selected: !_includePaid,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _includePaid = false),
                  ),
                  ChoiceChip(
                    label: const Text('Yes, reprice them'),
                    selected: _includePaid,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _includePaid = true),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _includePaid
                    ? 'The cash received stays the same, so ${_owes(check.paidChange)}${check.paidChange < 0 ? ' (in credit)' : ''}.'
                    : 'Those sales keep their old price.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(
              check == null
                  ? 'Check'
                  : _cancel
                  ? 'Cancel price'
                  : 'Save price',
            ),
          ),
        ],
      ),
    );
  }
}
