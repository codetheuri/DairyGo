import 'dart:convert';

import 'package:file_selector/file_selector.dart';
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
import '../finance_providers.dart';

/// An account's bank or M-Pesa statements: import one, then open it to
/// match its lines to the cashbook.
class ReconcileScreen extends ConsumerStatefulWidget {
  final String accountId;

  const ReconcileScreen({super.key, required this.accountId});

  @override
  ConsumerState<ReconcileScreen> createState() => _ReconcileScreenState();
}

class _ReconcileScreenState extends ConsumerState<ReconcileScreen> {
  bool _busy = false;
  static final _day = DateFormat('d MMM y');

  void _say(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  /// Picks a statement file, shows what it holds, and imports it.
  Future<void> _import() async {
    final file = await openFile();
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      _say('The file must be under 5 MB.');
      return;
    }
    final encoded = base64Encode(bytes);
    final service = ref.read(financeServiceProvider);
    setState(() => _busy = true);
    try {
      final p = await service.importStatement(
        widget.accountId,
        fileBase64: encoded,
        fileName: file.name,
        preview: true,
      );
      if (!mounted) return;
      if (p.problems.isNotEmpty) {
        await _problems(p.problems);
        return;
      }
      if (p.lines == 0) {
        _say('Every line in ${file.name} was imported already.');
        return;
      }
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import this statement?'),
          content: Text(
            [
              '${p.lines} ${p.lines == 1 ? 'line' : 'lines'}: '
                  '${kes(p.moneyIn)} in, ${kes(p.moneyOut)} out.',
              if (p.alreadyImported > 0)
                '${p.alreadyImported} imported before are left out.',
              'Lines with one cashbook movement of the same amount are matched straight away.',
            ].join('\n\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      if (go != true) return;
      final done = await service.importStatement(
        widget.accountId,
        fileBase64: encoded,
        fileName: file.name,
      );
      ref.invalidate(statementsProvider(widget.accountId));
      ref.invalidate(cashbookProvider);
      if (done.statement != null && mounted) {
        _say('Imported: ${done.matched} of ${done.lines} lines matched.');
        context.push('/finance/statements/${done.statement!.id}');
      }
    } catch (e) {
      _say(errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _problems(List<String> problems) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Fix the file first'),
      content: SingleChildScrollView(
        child: Text(
          'Nothing was imported.\n\n${problems.take(8).join('\n')}'
          '${problems.length > 8 ? '\n…and ${problems.length - 8} more' : ''}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final canManage =
        ref
            .watch(authControllerProvider)
            .valueOrNull
            ?.user
            ?.canManageAccounts ??
        false;
    final list = ref.watch(statementsProvider(widget.accountId));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reconcile with the bank',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _import,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: const Text('Import statement'),
            )
          : null,
      body: ReadableWidth(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.refresh(statementsProvider(widget.accountId).future),
          child: list.when(
            loading: () => const ListSkeleton(rows: 4),
            error: (e, _) => ErrorView(
              message: errorText(e),
              onRetry: () =>
                  ref.invalidate(statementsProvider(widget.accountId)),
            ),
            data: (statements) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const Text(
                  'Import the bank\'s or M-Pesa\'s statement (CSV or Excel), then match each line '
                  'to the cashbook. What is left over is what to look into: money the bank shows '
                  'that DairyGo does not have, and money in DairyGo the bank has not shown.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                if (statements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No statements imported yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final s in statements)
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    child: ListTile(
                      onTap: () => context.push('/finance/statements/${s.id}'),
                      leading: Icon(
                        s.matched == s.lines
                            ? Icons.task_alt_rounded
                            : Icons.rule_rounded,
                        color: s.matched == s.lines
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      title: Text(
                        '${_day.format(s.from)} – ${_day.format(s.to)}',
                      ),
                      subtitle: Text(
                        [
                          '${s.matched} of ${s.lines} matched',
                          if ((s.fileName ?? '').isNotEmpty) s.fileName!,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
