import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/member_model.dart';
import '../controllers/member_controller.dart';
import 'next_of_kin_fields.dart';

/// Adds or corrects a farmer's next of kin. Pops with true when saved.
class NextOfKinDialog extends ConsumerStatefulWidget {
  final MemberModel member;

  const NextOfKinDialog({super.key, required this.member});

  static Future<bool?> show(BuildContext context, MemberModel member) {
    return showDialog<bool>(
      context: context,
      builder: (_) => NextOfKinDialog(member: member),
    );
  }

  @override
  ConsumerState<NextOfKinDialog> createState() => _NextOfKinDialogState();
}

class _NextOfKinDialogState extends ConsumerState<NextOfKinDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.member.nextOfKinName ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.member.nextOfKinPhone ?? '',
  );
  late String? _relationship =
      (widget.member.nextOfKinRelationship ?? '').isEmpty
      ? null
      : widget.member.nextOfKinRelationship;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await ref
        .read(memberActionsProvider)
        .saveNextOfKin(
          widget.member.id,
          name: _name.text.trim(),
          relationship: _relationship!,
          phone: _phone.text.trim(),
        );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Next of kin for ${widget.member.firstName}'),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
            NextOfKinFields(
              nameController: _name,
              phoneController: _phone,
              relationship: _relationship,
              onRelationshipChanged: (v) => setState(() => _relationship = v),
              farmerPhone: () => widget.member.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
