import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/payout_models.dart';
import '../payout_providers.dart';

/// Farmer pay: the next pay run to work out, and every pay run so far.
class PayRunsScreen extends ConsumerWidget {
  const PayRunsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final runs = ref.watch(payRunsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Farmer Pay',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Deductions',
            icon: const Icon(Icons.rule_rounded),
            onPressed: () => context.push('/payouts/deductions'),
          ),
        ],
      ),
      body: ReadableWidth(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(payRunsProvider.future),
          child: runs.when(
            loading: () => const ListSkeleton(rows: 4),
            error: (e, _) => ErrorView(
              message: errorText(e),
              onRetry: () => ref.invalidate(payRunsProvider),
            ),
            data: (list) {
              final draft = list.runs.where((r) => r.isDraft).firstOrNull;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (draft == null && (user?.canPreparePayRuns ?? false))
                    _NextRunCard(from: list.nextFrom, to: list.nextTo),
                  if (list.runs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No pay runs yet. Each month, work out every farmer\'s pay: '
                        'milk delivered, less advances, charges and deductions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  for (final r in list.runs) ...[
                    _RunCard(run: r),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NextRunCard extends ConsumerStatefulWidget {
  final DateTime from;
  final DateTime to;

  const _NextRunCard({required this.from, required this.to});

  @override
  ConsumerState<_NextRunCard> createState() => _NextRunCardState();
}

class _NextRunCardState extends ConsumerState<_NextRunCard> {
  bool _busy = false;
  String? _error;

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final detail = await ref
          .read(payoutServiceProvider)
          .createPayRun(widget.from, widget.to);
      ref.invalidate(payRunsProvider);
      if (mounted) context.push('/payouts/runs/${detail.run.id}');
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentMint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Next pay run',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            periodLabel(widget.from, widget.to),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.primary,
            ),
          ),
          Text(
            '${shortDate(widget.from)} to ${shortDate(widget.to)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: _busy ? null : _create,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calculate_outlined),
            label: const Text('Work out pay'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nothing is final until it is approved. You can check every farmer first.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RunCard extends StatelessWidget {
  final PayRun run;

  const _RunCard({required this.run});

  @override
  Widget build(BuildContext context) {
    final toPay = run.isApproved ? ' · ${run.paidCount} paid' : '';
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/payouts/runs/${run.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      periodLabel(run.from, run.to),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${run.farmers} farmers · ${litres(run.litres)}$toPay',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusPill.fromStatusString(run.statusLabel),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Net pay',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    kes(run.net, cents: false),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
