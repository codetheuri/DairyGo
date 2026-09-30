import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/member_model.dart';
import '../controllers/member_controller.dart';

/// A farmer's statuses, with what each one means for taking their milk, in
/// the words staff see. The server enforces the same rules.
const farmerStatuses = [
  (
    value: 'ACTIVE',
    name: 'Active',
    means: 'Brings milk as usual',
    icon: Icons.check_circle_outline_rounded,
    color: AppColors.success,
  ),
  (
    value: 'INACTIVE',
    name: 'Inactive',
    means:
        'Not bringing milk for now. Milk is still taken, and taking it '
        'makes the farmer active again',
    icon: Icons.pause_circle_outline_rounded,
    color: AppColors.warning,
  ),
  (
    value: 'SUSPENDED',
    name: 'Suspended',
    means: 'No milk is taken until an administrator makes the farmer active',
    icon: Icons.block_rounded,
    color: AppColors.error,
  ),
];

/// Explains an inactive or suspended farmer's status where their profile is
/// shown; nothing for an active farmer.
class FarmerStatusNote extends StatelessWidget {
  final String status;

  const FarmerStatusNote({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    if (s != 'INACTIVE' && s != 'SUSPENDED') return const SizedBox.shrink();
    final suspended = s == 'SUSPENDED';
    final color = suspended ? AppColors.error : AppColors.warning;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: suspended
            ? AppColors.errorContainer
            : AppColors.warningContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            suspended ? Icons.block_rounded : Icons.info_outline_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              suspended
                  ? 'Suspended: milk cannot be recorded for this farmer.'
                  : 'Inactive: recording milk makes this farmer active again.',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets an administrator make a farmer active, inactive or suspended. A
/// suspension needs a reason, which is kept in the farmer's history.
class FarmerStatusSheet extends ConsumerStatefulWidget {
  final MemberModel member;

  const FarmerStatusSheet({super.key, required this.member});

  static Future<void> show(BuildContext context, MemberModel member) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => FarmerStatusSheet(member: member),
    );
  }

  @override
  ConsumerState<FarmerStatusSheet> createState() => _FarmerStatusSheetState();
}

class _FarmerStatusSheetState extends ConsumerState<FarmerStatusSheet> {
  late String _status = widget.member.status.toUpperCase();
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;

  String get _current => widget.member.status.toUpperCase();
  bool get _changed => _status != _current;
  bool get _needsReason => _status == 'SUSPENDED';

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_needsReason && _reason.text.trim().isEmpty) {
      setState(() => _error = 'Give a reason for suspending the farmer.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await ref
        .read(memberActionsProvider)
        .setStatus(widget.member.id, _status, reason: _reason.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    final name = farmerStatuses.firstWhere((s) => s.value == _status).name;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${widget.member.fullName} is now ${name.toLowerCase()}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keep the reason field above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Status of ${widget.member.fullName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 12),
            for (final s in farmerStatuses)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _StatusOption(
                  name: s.value == _current ? '${s.name} (now)' : s.name,
                  means: s.means,
                  icon: s.icon,
                  color: s.color,
                  selected: s.value == _status,
                  onTap: _saving
                      ? null
                      : () => setState(() {
                          _status = s.value;
                          _error = null;
                        }),
                ),
              ),
            const SizedBox(height: 4),
            TextField(
              controller: _reason,
              enabled: !_saving,
              maxLength: 500,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _needsReason
                    ? 'Reason (required)'
                    : 'Reason (optional)',
                hintText: _needsReason
                    ? 'e.g. water found in the milk'
                    : 'e.g. moved away for the season',
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _changed && !_saving ? _save : null,
              style: _status == 'SUSPENDED'
                  ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                  : null,
              child: Text(
                _saving
                    ? 'Saving…'
                    : _changed
                    ? 'Make ${farmerStatuses.firstWhere((s) => s.value == _status).name.toLowerCase()}'
                    : 'Choose a new status',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String name;
  final String means;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _StatusOption({
    required this.name,
    required this.means,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.accentMint : Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    means,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
