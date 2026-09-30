import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// The roles a Sacco gives its staff, with the server's role number and what
/// each one can do, in plain words.
const staffRoles = [
  (
    id: 1,
    name: 'Sacco Administrator',
    does: 'Manages staff, prices and every record',
  ),
  (
    id: 2,
    name: 'Milk Collector',
    does: 'Records milk, sales, transfers and spoilage',
  ),
  (
    id: 3,
    name: 'Board Member',
    does: 'Sees dashboards and reports; records nothing',
  ),
];

/// What an administrator can do with a staff member: give them another role
/// or remove them from the Sacco. The server refuses changes to your own
/// account and to the Sacco's only administrator.
class StaffActionsSheet extends ConsumerStatefulWidget {
  final UserEntity staff;

  const StaffActionsSheet({super.key, required this.staff});

  static Future<void> show(BuildContext context, UserEntity staff) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => StaffActionsSheet(staff: staff),
    );
  }

  @override
  ConsumerState<StaffActionsSheet> createState() => _StaffActionsSheetState();
}

class _StaffActionsSheetState extends ConsumerState<StaffActionsSheet> {
  late int _roleId = widget.staff.saccoRoleId;
  bool _saving = false;

  UserEntity get _staff => widget.staff;

  void _tell(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? null : AppColors.success,
      ),
    );
  }

  Future<void> _changeRole() async {
    final role = staffRoles.firstWhere((r) => r.id == _roleId);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Make ${_staff.fullName} a ${role.name}?'),
        content: Text(
          '${role.does}. This replaces their current role and applies '
          'straight away.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Change role'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    final error = await ref
        .read(staffActionsProvider)
        .changeRole(_staff.id, _roleId);
    if (!mounted) return;
    setState(() => _saving = false);
    _tell(
      error ?? '${_staff.fullName} is now a ${role.name}',
      error: error != null,
    );
    if (error == null) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${_staff.fullName}?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'They are signed out now and cannot sign in again. What they '
                'recorded stays in the reports under their name. This cannot '
                'be undone.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'e.g. left the Sacco',
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    final text = reason.text.trim();
    final error = await ref
        .read(staffActionsProvider)
        .remove(_staff.id, reason: text.isEmpty ? null : text);
    if (!mounted) return;
    setState(() => _saving = false);
    _tell(error ?? '${_staff.fullName} was removed', error: error != null);
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final changed = _roleId != _staff.saccoRoleId;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _staff.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              '@${_staff.username}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Role',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            for (final role in staffRoles)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RoleOption(
                  name: role.name,
                  does: role.does,
                  selected: role.id == _roleId,
                  onTap: _saving
                      ? null
                      : () => setState(() => _roleId = role.id),
                ),
              ),
            FilledButton(
              onPressed: changed && !_saving ? _changeRole : null,
              child: Text(changed ? 'Change role' : 'This is their role now'),
            ),
            const Divider(height: 32),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: _saving ? null : _remove,
              icon: const Icon(Icons.person_remove_outlined, size: 18),
              label: const Text('Remove from the Sacco'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String name;
  final String does;
  final bool selected;
  final VoidCallback? onTap;

  const _RoleOption({
    required this.name,
    required this.does,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    does,
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
