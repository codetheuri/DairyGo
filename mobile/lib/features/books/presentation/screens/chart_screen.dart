import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/books_models.dart';
import '../books_providers.dart';
import '../widgets/books_widgets.dart';

/// The chart of accounts by kind, each with its balance now. The accountant
/// adds accounts; tapping one opens its ledger.
class ChartScreen extends ConsumerWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(ledgerAccountsProvider);
    final canManage =
        ref.watch(
          authControllerProvider.select(
            (s) => s.valueOrNull?.user?.canManageBooks,
          ),
        ) ??
        false;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chart of accounts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'new-account',
              onPressed: () => showAccountDialog(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Account'),
            )
          : null,
      body: accounts.when(
        loading: () => const ListSkeleton(rows: 8),
        error: (e, _) => ErrorView(
          message: errorText(e),
          onRetry: () => ref.invalidate(ledgerAccountsProvider),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(ledgerAccountsProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              ReadableWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final type in accountTypes) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                        child: Text(
                          accountTypeNames[type]!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      for (final a in list.where((a) => a.type == type))
                        _AccountRow(a),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final LedgerAccount a;

  const _AccountRow(this.a);

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/books/accounts/${a.id}'),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              a.code,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  style: TextStyle(
                    color: a.isActive ? null : AppColors.textMuted,
                  ),
                ),
                if (a.kept || !a.isActive)
                  Text(
                    !a.isActive
                        ? 'Switched off'
                        : 'Follows ${a.keptBy.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          balanceText(a.balance, size: 13, weight: FontWeight.w600),
        ],
      ),
    ),
  );
}

/// Adds an account, or changes [account]: code, name, kind (only while
/// nothing has posted to it), description and switched on or off.
Future<void> showAccountDialog(
  BuildContext context,
  WidgetRef ref, {
  LedgerAccount? account,
}) async {
  final code = TextEditingController(text: account?.code ?? '');
  final name = TextEditingController(text: account?.name ?? '');
  final desc = TextEditingController(text: account?.description ?? '');
  var type = account?.type ?? 'EXPENSE';
  var active = account?.isActive ?? true;
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(account == null ? 'New account' : 'Change ${account.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: code,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'e.g. 6100',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Kind',
                  helperText: account?.used ?? false
                      ? 'Entries have posted to it, so it stays this kind'
                      : null,
                  helperMaxLines: 2,
                ),
                items: [
                  for (final t in accountTypes)
                    DropdownMenuItem(value: t, child: Text(accountTypeOne[t]!)),
                ],
                onChanged: account?.used ?? false
                    ? null
                    : (v) => setState(() => type = v ?? type),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: desc,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
              if (account != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('In use'),
                  subtitle: const Text(
                    'Switched off: nothing new posts to it; its history stays.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  if (saved != true || !context.mounted) return;
  try {
    await ref.read(booksServiceProvider).saveAccount(account?.id, {
      'code': code.text.trim(),
      'name': name.text.trim(),
      if (account == null || !account.used) 'type': type,
      'description': desc.text.trim(),
      if (account != null) 'is_active': active,
    });
    refreshBooks(ref);
    if (context.mounted) {
      showBooksDone(
        context,
        account == null ? 'Account added' : 'Account saved',
      );
    }
  } catch (e) {
    if (context.mounted) showBooksError(context, e);
  }
}
