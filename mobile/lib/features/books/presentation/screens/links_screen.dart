import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/books_models.dart';
import '../books_providers.dart';
import '../widgets/books_widgets.dart';

/// Where each kind of record posts: every cash account, expense category and
/// deduction, and the accounts the records use for customers, farmers and
/// milk. The accountant points one at another account; journals already
/// posted stay where they are.
class LinksScreen extends ConsumerWidget {
  const LinksScreen({super.key});

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    BooksLink link,
  ) async {
    final List<LedgerAccount> all;
    try {
      all = await ref.read(ledgerAccountsProvider.future);
    } catch (e) {
      if (context.mounted) showBooksError(context, e);
      return;
    }
    final choices = all
        .where((a) => a.isActive && link.allowedTypes.contains(a.type))
        .where(
          (a) =>
              a.id == link.accountId ||
              !a.kept ||
              // Cash accounts may share one ledger account between them.
              (link.key.startsWith('cash_account:') &&
                  a.keptBy.startsWith('A cash account')),
        )
        .toList();
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * .7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${link.name} posts to',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              for (final a in choices)
                ListTile(
                  title: Text(a.label),
                  subtitle: Text(
                    accountTypeOne[a.type]!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: a.id == link.accountId
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, a.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == link.accountId || !context.mounted) return;
    try {
      await ref.read(booksServiceProvider).setLink(link.key, picked);
      refreshBooks(ref);
      if (context.mounted) {
        showBooksDone(context, '${link.name} posts there from now on');
      }
    } catch (e) {
      if (context.mounted) showBooksError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(booksLinksProvider);
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
          'Where records post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: links.when(
        loading: () => const ListSkeleton(rows: 8),
        error: (e, _) => ErrorView(
          message: errorText(e),
          onRetry: () => ref.invalidate(booksLinksProvider),
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            ReadableWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Each record posts to the account shown. A change applies '
                      'from now on; entries already posted stay where they are.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  for (final group in linkGroupNames.keys) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                      child: Text(
                        linkGroupNames[group]!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    for (final l in list.where((l) => l.group == group))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.name),
                        subtitle: Text(
                          [
                            if (l.detail.isNotEmpty) l.detail,
                            '→ ${l.accountCode} ${l.accountName}',
                          ].join('\n'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: l.detail.isNotEmpty,
                        trailing: canManage
                            ? const Icon(Icons.edit_outlined, size: 18)
                            : null,
                        onTap: canManage
                            ? () => _change(context, ref, l)
                            : null,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
