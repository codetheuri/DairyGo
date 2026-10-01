import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/report_download_service.dart';
import '../../data/report_spec.dart';
import '../report_download_controller.dart';
import '../widgets/report_download_sheet.dart';

/// Lists the reports this user may download (PDF or Excel), and the ones
/// already downloaded to open or share again.
class ReportDownloadsScreen extends ConsumerWidget {
  const ReportDownloadsScreen({super.key});

  static const _icons = {
    'farmer-payouts': Icons.payments_outlined,
    'farmer-statement': Icons.receipt_long_rounded,
    'collections': Icons.water_drop_outlined,
    'sales': Icons.storefront_outlined,
    'customer-statement': Icons.request_quote_outlined,
    'customers-owing': Icons.account_balance_wallet_outlined,
    'milk-balance': Icons.balance_rounded,
    'sacco-summary': Icons.insights_rounded,
    'farmer-register': Icons.groups_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(reportCatalogProvider);
    final saved = ref.watch(savedReportsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Download Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ReadableWidth(
        child: catalog.when(
          loading: () => const ListSkeleton(rows: 5),
          error: (e, _) => ErrorView(
            message: e.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(reportCatalogProvider),
          ),
          data: (reports) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const Text(
                'Reports are made on the server with your Sacco\'s letterhead. '
                'PDF to print or share; Excel for accounts.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              if (reports.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Your role has no reports to download.'),
                ),
              for (final r in reports) ...[
                _ReportCard(report: r, icon: _icons[r.key]),
                const SizedBox(height: 10),
              ],
              if (saved.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Downloaded',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Text(
                  'Kept on this phone for 30 days.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                for (final s in saved.take(15)) _SavedTile(saved: s),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportSpec report;
  final IconData? icon;

  const _ReportCard({required this.report, this.icon});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.cardBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => ReportDownloadSheet.show(context, report),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.accentMint,
              foregroundColor: AppColors.primary,
              child: Icon(icon ?? Icons.description_outlined, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.download_rounded, color: AppColors.primary),
          ],
        ),
      ),
    ),
  );
}

class _SavedTile extends StatelessWidget {
  final SavedReport saved;

  const _SavedTile({required this.saved});

  @override
  Widget build(BuildContext context) {
    final kb = (saved.size / 1024).ceil();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        saved.isPdf
            ? Icons.picture_as_pdf_outlined
            : Icons.table_chart_outlined,
        color: saved.isPdf ? AppColors.error : AppColors.success,
      ),
      title: Text(
        saved.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text('$kb KB', style: const TextStyle(fontSize: 12)),
      onTap: () async {
        final problem = await ReportFiles.open(saved.file);
        if (problem != null && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(problem)));
        }
      },
      trailing: IconButton(
        tooltip: 'Share',
        icon: const Icon(Icons.share_rounded),
        onPressed: () => ReportFiles.share(saved.file, saved.name),
      ),
    );
  }
}
