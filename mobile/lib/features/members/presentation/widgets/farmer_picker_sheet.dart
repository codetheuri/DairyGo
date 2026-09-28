import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/member_model.dart';
import '../controllers/member_controller.dart';
import 'quick_add_farmer_dialog.dart';

/// Search-as-you-type picker for the farmer whose milk is being recorded.
/// Searches the server (active farmers only), so it works for any number of
/// farmers. If the farmer is new, "Register new farmer" creates them and
/// returns them selected.
class FarmerPickerSheet extends ConsumerStatefulWidget {
  final String? selectedMemberId;

  const FarmerPickerSheet({super.key, this.selectedMemberId});

  static Future<MemberModel?> show(
    BuildContext context, {
    String? selectedMemberId,
  }) {
    return showModalBottomSheet<MemberModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => FarmerPickerSheet(selectedMemberId: selectedMemberId),
    );
  }

  @override
  ConsumerState<FarmerPickerSheet> createState() => _FarmerPickerSheetState();
}

class _FarmerPickerSheetState extends ConsumerState<FarmerPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Waits for a pause in typing so a slow connection is not flooded with a
  // request per keystroke.
  void _onChanged(String value) {
    setState(() {}); // refresh the "Register" button label
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _registerNew() async {
    final created = await QuickAddFarmerDialog.show(
      context,
      initialText: _searchController.text,
    );
    if (created != null && mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(farmerPickerResultsProvider(_query));
    final typed = _searchController.text.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select farmer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Name, phone or membership no.',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: typed.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onChanged('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _registerNew,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(
                typed.isEmpty
                    ? 'Register new farmer'
                    : 'Register "$typed" as new farmer',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.when(
                skipLoadingOnReload: true,
                data: (members) => members.isEmpty
                    ? Center(
                        child: Text(
                          typed.isEmpty
                              ? 'No active farmers yet. Register one above.'
                              : 'No farmer matches "$typed".',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: members.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: AppColors.cardBorder,
                        ),
                        itemBuilder: (_, i) => _FarmerTile(
                          member: members[i],
                          selected: members[i].id == widget.selectedMemberId,
                          onTap: () => Navigator.of(context).pop(members[i]),
                        ),
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.toString().replaceAll('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            ref.invalidate(farmerPickerResultsProvider(_query)),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerTile extends StatelessWidget {
  final MemberModel member;
  final bool selected;
  final VoidCallback onTap;

  const _FarmerTile({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      member.membershipNumber,
      member.phone,
      if (member.location != null && member.location!.isNotEmpty)
        member.location!,
    ].where((s) => s.isNotEmpty).join(' • ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: selected ? AppColors.primary : AppColors.accentMint,
        foregroundColor: selected ? Colors.white : AppColors.primary,
        child: Text(
          member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : 'F',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        member.fullName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        details,
        style: const TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
    );
  }
}
