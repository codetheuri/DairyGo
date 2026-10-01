import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/figure_grid.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../report_downloads/presentation/widgets/file_download_sheet.dart';
import '../../data/payout_models.dart';
import '../../data/payout_service.dart';
import '../payout_providers.dart';
import '../widgets/mark_paid_sheet.dart';
import '../widgets/payslip_sheet.dart';

/// One pay run: totals, what can be done next, and every farmer's pay.
class PayRunDetailScreen extends ConsumerStatefulWidget {
  final String runId;

  const PayRunDetailScreen({super.key, required this.runId});

  @override
  ConsumerState<PayRunDetailScreen> createState() => _PayRunDetailScreenState();
}

class _PayRunDetailScreenState extends ConsumerState<PayRunDetailScreen> {
  String _search = '';
  bool _busy = false;

  void _say(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.error : null,
      ),
    );
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(payRunProvider(widget.runId));
      ref.invalidate(payRunsProvider);
      if (mounted && done.isNotEmpty) _say(done);
    } catch (e) {
      if (mounted) _say(errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(
    String title,
    String body,
    String action, {
    bool danger = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              style: danger
                  ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                  : null,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this pay run?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Everything it wrote to farmers\' accounts is removed and the period opens again, '
              'so milk records can be corrected. Advances and charges wait for the next pay run.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g. Wrong milk price',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Cancel pay run'),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason;
  }

  Future<void> _paymentList(PayRun run) async {
    final kind = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.phone_android_rounded,
                color: AppColors.primary,
              ),
              title: const Text('M-Pesa list'),
              subtitle: const Text(
                'Phone, amount and name, for a bulk payment',
              ),
              onTap: () => Navigator.pop(ctx, 'mpesa'),
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Bank list'),
              subtitle: const Text('Bank, account, name and amount'),
              onTap: () => Navigator.pop(ctx, 'bank'),
            ),
          ],
        ),
      ),
    );
    if (kind == null || !mounted) return;
    await FileDownloadSheet.show(
      context,
      title: kind == 'bank' ? 'Bank payment list' : 'M-Pesa payment list',
      path: PayoutService.paymentFilePath(run.id),
      query: {'kind': kind},
      fallbackName: '$kind-payments.xlsx',
    );
  }

  Future<void> _register(PayRun run) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.error,
              ),
              title: const Text('PDF'),
              subtitle: const Text('To print or share'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
            ListTile(
              leading: const Icon(
                Icons.table_chart_outlined,
                color: AppColors.success,
              ),
              title: const Text('Excel'),
              subtitle: const Text('For the accounts'),
              onTap: () => Navigator.pop(ctx, 'xlsx'),
            ),
          ],
        ),
      ),
    );
    if (format == null || !mounted) return;
    await FileDownloadSheet.show(
      context,
      title: 'Pay run register',
      path: PayoutService.registerPath(run.id),
      query: {'format': format},
      fallbackName: 'pay-run.$format',
    );
  }

  List<Widget> _actions(PayRunDetail d) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final run = d.run;
    final service = ref.read(payoutServiceProvider);
    final unpaid = d.lines.where((l) => l.toPay).length;
    Widget button(
      IconData icon,
      String label,
      VoidCallback onTap, {
      bool primary = false,
    }) => primary
        ? FilledButton.icon(
            onPressed: _busy ? null : onTap,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: _busy ? null : onTap,
            icon: Icon(icon),
            label: Text(label),
          );

    return [
      if (run.isDraft && (user?.canApprovePayRuns ?? false))
        button(Icons.verified_outlined, 'Approve', () async {
          final ok = await _confirm(
            'Approve pay for ${periodLabel(run.from, run.to)}?',
            '${run.farmers} farmers, net pay ${kes(run.net)}.\n\n'
                'Milk records up to ${shortDate(run.to)} will be locked, and advances, charges and '
                'deductions are written to farmers\' accounts.',
            'Approve',
          );
          if (ok) {
            await _run(
              () => service.approve(run.id, run.net),
              'Pay run approved',
            );
          }
        }, primary: true),
      if (run.isDraft && (user?.canPreparePayRuns ?? false))
        button(
          Icons.refresh_rounded,
          'Work out again',
          () => _run(() => service.recompute(run.id), 'Worked out again'),
        ),
      if (run.isApproved && (user?.canPayFarmers ?? false)) ...[
        button(Icons.download_rounded, 'Payment list', () => _paymentList(run)),
        if (unpaid > 0)
          button(Icons.done_all_rounded, 'Mark all paid', () async {
            final done = await MarkPaidSheet.show(
              context,
              runId: run.id,
              count: unpaid,
              amount: run.net - run.paid,
            );
            if (done == true) {
              ref.invalidate(payRunProvider(widget.runId));
              ref.invalidate(payRunsProvider);
            }
          }, primary: true),
      ],
      if ((run.isApproved || run.isPaid) && (user?.canPayFarmers ?? false))
        button(
          Icons.sms_outlined,
          run.smsSentAt == null ? 'Text farmers' : 'Text again',
          () async {
            final ok = await _confirm(
              'Text ${run.farmers} farmers their pay?',
              run.smsSentAt == null
                  ? 'Each farmer gets one SMS with their milk, what was taken off and their net pay.'
                  : 'They were already texted on ${shortDate(run.smsSentAt!)}. Send again?',
              'Send',
            );
            if (ok) {
              await _run(() async {
                final n = await service.sendSms(run.id);
                if (mounted) _say('Sending $n messages');
              }, '');
            }
          },
        ),
      button(Icons.description_outlined, 'Register', () => _register(run)),
      if (run.isDraft && (user?.canPreparePayRuns ?? false))
        button(Icons.delete_outline_rounded, 'Discard', () async {
          final ok = await _confirm(
            'Discard this draft?',
            'You can work it out again any time.',
            'Discard',
            danger: true,
          );
          if (!ok) return;
          await _run(() => service.cancel(run.id), 'Draft discarded');
          if (mounted) context.pop();
        }),
      if (run.isApproved &&
          run.paidCount == 0 &&
          (user?.canPreparePayRuns ?? false))
        button(Icons.undo_rounded, 'Cancel', () async {
          final reason = await _askReason();
          if (reason == null) return;
          await _run(
            () => service.cancel(run.id, reason: reason),
            'Pay run cancelled',
          );
          if (mounted) context.pop();
        }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(payRunProvider(widget.runId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          detail.valueOrNull == null
              ? 'Pay run'
              : periodLabel(detail.value!.run.from, detail.value!.run.to),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ReadableWidth(
        child: detail.when(
          loading: () => const ListSkeleton(rows: 6),
          error: (e, _) => ErrorView(
            message: errorText(e),
            onRetry: () => ref.invalidate(payRunProvider(widget.runId)),
          ),
          data: (d) {
            final run = d.run;
            final q = _search.toLowerCase();
            final lines = q.isEmpty
                ? d.lines
                : d.lines
                      .where(
                        (l) =>
                            l.name.toLowerCase().contains(q) ||
                            l.number.contains(q) ||
                            l.phone.contains(q),
                      )
                      .toList();
            return RefreshIndicator(
              onRefresh: () => ref.refresh(payRunProvider(widget.runId).future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Row(
                    children: [
                      StatusPill.fromStatusString(run.statusLabel),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${shortDate(run.from)} to ${shortDate(run.to)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (run.isDraft) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Draft: check the farmers below. Nothing is final until the pay run is approved.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FigureGrid(
                    figures: [
                      Figure('Farmers', '${run.farmers}'),
                      Figure('Milk', litres(run.litres)),
                      Figure('Gross pay', kes(run.gross, cents: false)),
                      Figure('Deductions', kes(run.deductions, cents: false)),
                      Figure('Net pay', kes(run.net, cents: false)),
                      Figure(
                        'Paid',
                        run.isDraft
                            ? '—'
                            : '${run.paidCount} of ${d.lines.where((l) => l.net > 0).length}',
                        color: run.isPaid ? AppColors.success : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: _actions(d)),
                  const SizedBox(height: 18),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search name, number or phone',
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                  const SizedBox(height: 8),
                  if (lines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No farmers match.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final l in lines) _LineTile(run: run, line: l),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  final PayRun run;
  final PayLine line;

  const _LineTile({required this.run, required this.line});

  @override
  Widget build(BuildContext context) {
    final owes = line.closing < 0;
    final String sub;
    if (line.isPaid) {
      sub = 'Paid · ${line.paidLabel} ${line.paidReference ?? ''}'.trim();
    } else if (owes) {
      sub = 'Owes ${kes(-line.closing, cents: false)}, carried to next pay';
    } else {
      sub = '${litres(line.litres)} · gross ${kes(line.gross, cents: false)}';
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => PayslipSheet.show(context, run: run, line: line),
      title: Text(
        '${line.name} · ${line.number}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        sub,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: owes
              ? AppColors.error
              : (line.isPaid ? AppColors.success : null),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            kes(line.net, cents: false),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (line.isPaid)
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}
