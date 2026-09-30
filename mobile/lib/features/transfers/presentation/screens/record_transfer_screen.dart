import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../../field_operations/presentation/controllers/field_ops_controller.dart';
import '../../data/transfer_models.dart';
import '../transfer_controller.dart';

/// Hands milk to another collector: choose who, how many litres, confirm.
/// Admins can also choose who the milk comes from.
class RecordTransferScreen extends ConsumerStatefulWidget {
  const RecordTransferScreen({super.key});

  @override
  ConsumerState<RecordTransferScreen> createState() =>
      _RecordTransferScreenState();
}

class _RecordTransferScreenState extends ConsumerState<RecordTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litres = TextEditingController();
  final _notes = TextEditingController();
  final _search = TextEditingController();

  TransferRecipientModel? _to;

  /// Admins only: the sender, when not themselves.
  TransferRecipientModel? _from;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  /// With this many colleagues or more, a search box helps.
  static const _searchFrom = 7;

  @override
  void dispose() {
    _litres.dispose();
    _notes.dispose();
    _search.dispose();
    super.dispose();
  }

  double? get _litresValue => double.tryParse(_litres.text.trim());

  static String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _isToday => _dateString(_date) == getTodayDateString();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now,
      helpText: 'Day the milk was handed over',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit(String senderName) async {
    setState(() => _error = null);
    if (_to == null) {
      setState(() => _error = 'Choose who receives the milk.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final litres = _litresValue!;
    final to = _to!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Give ${_fmt(litres)} L to ${to.name}?'),
        content: Text(
          'The milk moves from $senderName to ${to.name} right away'
          '${_isToday ? '' : ', dated ${_dateString(_date)}'}. '
          '${to.name} will see it on their screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, transfer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final error = await ref
        .read(transferActionsProvider)
        .record(
          toCollectorId: to.id,
          litres: litres,
          transferDate: _isToday ? null : _dateString(_date),
          fromCollectorId: _from?.id,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_fmt(litres)} L transferred to ${to.name}'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final isAdmin = user?.canManageTransfers ?? false;
    final recipientsAsync = ref.watch(transferRecipientsProvider);
    // What the collector still holds today: the unaccounted balance.
    final holding = !isAdmin && _isToday
        ? ref.watch(reconciliationProvider(null)).valueOrNull?.unaccountedLitres
        : null;
    final senderName = _from?.name ?? 'you';
    final litres = _litresValue;
    final over = holding != null && litres != null && litres > holding + 0.001;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transfer milk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ReadableWidth(
        child: Stack(
          children: [
            recipientsAsync.when(
              loading: () => const ListSkeleton(rows: 5),
              error: (e, _) => ErrorView(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.refresh(transferRecipientsProvider.future),
              ),
              data: (recipients) {
                final choices = recipients
                    .where((r) => r.id != _from?.id)
                    .where(
                      (r) => r.name.toLowerCase().contains(
                        _search.text.trim().toLowerCase(),
                      ),
                    )
                    .toList();
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (holding != null) _HoldingCard(litres: holding),
                        if (_error != null) _ErrorBox(message: _error!),
                        if (isAdmin) ...[
                          _Heading('From'),
                          _SenderPicker(
                            me: user?.fullName ?? 'Me',
                            recipients: recipients,
                            selected: _from,
                            onChanged: (r) => setState(() {
                              _from = r;
                              if (_to?.id == r?.id) _to = null;
                            }),
                          ),
                          const SizedBox(height: 20),
                        ],
                        _Heading('Give milk to'),
                        if (recipients.length >= _searchFrom) ...[
                          TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded),
                              hintText: 'Search a name',
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (recipients.isEmpty)
                          const Text(
                            'There is no other collector in your Sacco yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        for (final r in choices)
                          _RecipientTile(
                            recipient: r,
                            selected: _to?.id == r.id,
                            onTap: () => setState(() {
                              _to = r;
                              _error = null;
                            }),
                          ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'Litres handed over *',
                          controller: _litres,
                          hint: 'e.g. 20',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefixIcon: Icons.water_drop_outlined,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final d = double.tryParse(v?.trim() ?? '');
                            if (d == null || d <= 0) {
                              return 'Enter the litres, more than 0';
                            }
                            return null;
                          },
                        ),
                        if (holding != null && holding > 0) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ActionChip(
                              avatar: const Icon(Icons.done_all, size: 18),
                              label: Text('All I hold: ${_fmt(holding)} L'),
                              onPressed: () => setState(() {
                                _litres.text = _fmt(holding);
                                HapticFeedback.selectionClick();
                              }),
                            ),
                          ),
                        ],
                        if (over)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'That is more than the ${_fmt(holding)} L you '
                              'hold today. Check the litres before saving.',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Note (optional)',
                          controller: _notes,
                          hint: 'e.g. handed over at the junction',
                          prefixIcon: Icons.notes_rounded,
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.event_rounded,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            _isToday ? 'Today' : _dateString(_date),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('Day of the handover'),
                          trailing: TextButton(
                            onPressed: _pickDate,
                            child: const Text('Change'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: _to == null
                              ? 'Transfer milk'
                              : litres == null || litres <= 0
                              ? 'Transfer to ${_to!.name}'
                              : 'Transfer ${_fmt(litres)} L to ${_to!.name}',
                          icon: Icons.swap_horiz_rounded,
                          onPressed: _saving ? null : () => _submit(senderName),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'It moves from $senderName to the other collector '
                          'at once. You can correct or cancel it today.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_saving) const LoadingOverlay(message: 'Saving transfer…'),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

/// "You hold X L": what is not yet sold, transferred or spoiled today.
class _HoldingCard extends StatelessWidget {
  final double litres;

  const _HoldingCard({required this.litres});

  @override
  Widget build(BuildContext context) {
    final value = litres == litres.roundToDouble()
        ? litres.toStringAsFixed(0)
        : litres.toStringAsFixed(1);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentMint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'You hold '),
                  TextSpan(
                    text: '$value L',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(
                    text:
                        ' today that is not yet sold, transferred or spoiled.',
                  ),
                ],
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.errorContainer,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.error),
    ),
    child: Text(message, style: const TextStyle(color: AppColors.error)),
  );
}

/// A colleague to choose, as a large tappable card.
class _RecipientTile extends StatelessWidget {
  final TransferRecipientModel recipient;
  final bool selected;
  final VoidCallback onTap;

  const _RecipientTile({
    required this.recipient,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.accentMint : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: selected
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  foregroundColor: selected
                      ? Colors.white
                      : AppColors.textPrimary,
                  child: Text(
                    recipient.name.isNotEmpty
                        ? recipient.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (recipient.username != recipient.name)
                        Text(
                          recipient.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Admins: whose milk it is (themselves or a collector).
class _SenderPicker extends StatelessWidget {
  final String me;
  final List<TransferRecipientModel> recipients;
  final TransferRecipientModel? selected;
  final ValueChanged<TransferRecipientModel?> onChanged;

  const _SenderPicker({
    required this.me,
    required this.recipients,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: selected?.id ?? 0,
      isExpanded: true,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
      items: [
        DropdownMenuItem(value: 0, child: Text('$me (me)')),
        for (final r in recipients)
          DropdownMenuItem(
            value: r.id,
            child: Text(r.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) => onChanged(
        id == null || id == 0 ? null : recipients.firstWhere((r) => r.id == id),
      ),
    );
  }
}
