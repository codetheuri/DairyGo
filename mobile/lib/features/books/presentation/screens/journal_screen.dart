import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/books_models.dart';
import '../books_providers.dart';
import '../widgets/books_widgets.dart';

/// One journal with its debits and credits. The accountant's own journals
/// can be reversed; a record's journal follows the record.
class JournalScreen extends ConsumerWidget {
  final String journalId;

  const JournalScreen({super.key, required this.journalId});

  Future<void> _reverse(BuildContext context, WidgetRef ref, Journal j) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reverse ${j.label}?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'A new journal takes it back on the same day. Both stay in the books.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                textCapitalization: TextCapitalization.sentences,
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
            child: const Text('Reverse'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final r = await ref
          .read(booksServiceProvider)
          .reverseJournal(j.id, reason.text);
      refreshBooks(ref);
      if (context.mounted) showBooksDone(context, 'Reversed by ${r.label}');
    } catch (e) {
      if (context.mounted) showBooksError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(journalProvider(journalId));
    final canManage =
        ref.watch(
          authControllerProvider.select(
            (s) => s.valueOrNull?.user?.canManageBooks,
          ),
        ) ??
        false;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          journal.valueOrNull?.label ?? 'Journal',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: journal.when(
        loading: () => const ListSkeleton(rows: 5),
        error: (e, _) => ErrorView(
          message: errorText(e),
          onRetry: () => ref.invalidate(journalProvider(journalId)),
        ),
        data: (j) {
          final canReverse =
              canManage &&
              j.isManual &&
              j.reversesId == null &&
              j.reversedById == null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              ReadableWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      j.memo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        DateFormat('d MMM y').format(j.date),
                        j.isManual
                            ? 'Made by hand${j.createdBy == null ? '' : ' (${j.createdBy})'}'
                            : 'From: ${journalSources[j.sourceType] ?? 'a record'}',
                        if ((j.reference ?? '').isNotEmpty)
                          'Ref ${j.reference}',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (j.reason != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Reason: ${j.reason}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                    if (j.reversedById != null)
                      _Link(
                        text: 'Reversed by J-${j.reversedByNumber ?? ''}',
                        id: j.reversedById!,
                      ),
                    if (j.reversesId != null)
                      _Link(
                        text: 'Reverses J-${j.reversesNumber ?? ''}',
                        id: j.reversesId!,
                      ),
                    const SizedBox(height: 14),
                    BooksCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < j.lines.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _LineTile(j.lines[i]),
                          ],
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Debits = credits',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  thousands(j.total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!j.isManual) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Posted from a record. To change it, correct or void the '
                        'record; its journal is reversed and posted again.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (canReverse) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _reverse(context, ref, j),
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Reverse this journal'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Link extends StatelessWidget {
  final String text;
  final String id;

  const _Link({required this.text, required this.id});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      onPressed: () => context.push('/books/journals/$id'),
      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
      label: Text(text),
    ),
  );
}

class _LineTile extends StatelessWidget {
  final JournalLine l;

  const _LineTile(this.l);

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/books/accounts/${l.accountId}'),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l.accountCode}  ${l.accountName}'),
                if ((l.memo ?? '').isNotEmpty)
                  Text(
                    l.memo!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            drCr(l.debit, l.credit),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: l.debit > 0 ? AppColors.textPrimary : AppColors.secondary,
            ),
          ),
        ],
      ),
    ),
  );
}
