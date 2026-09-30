import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/models/member_model.dart';
import '../controllers/member_controller.dart';
import '../widgets/farmer_details_fields.dart';
import 'register_farmer_screen.dart';

/// Edits a farmer's personal, next of kin, location and payout details.
/// Every change is kept in the farmer's history on the server.
class EditFarmerScreen extends ConsumerWidget {
  final String memberId;

  const EditFarmerScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberDetailsProvider(memberId));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Farmer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ReadableWidth(
        child: memberAsync.when(
          loading: () => const ListSkeleton(rows: 6),
          error: (e, _) => ErrorView(
            message: e.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.refresh(memberDetailsProvider(memberId).future),
          ),
          // Keyed by farmer so the form starts from their saved details.
          data: (member) => _EditForm(key: ValueKey(member.id), member: member),
        ),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  final MemberModel member;

  const _EditForm({super.key, required this.member});

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _data = FarmerFormData.of(widget.member);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _data.dispose();
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
        .update(widget.member.id, _data.toUpdate());
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Farmer details saved'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${m.fullName} · ${m.membershipNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  FormErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                FarmerDetailsFields(data: _data, editing: true),
                const SizedBox(height: 30),
                PrimaryButton(
                  label: 'Save Changes',
                  icon: Icons.save_outlined,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
        if (_saving) const LoadingOverlay(message: 'Saving...'),
      ],
    );
  }
}
