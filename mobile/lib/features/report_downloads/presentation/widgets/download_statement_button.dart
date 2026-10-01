import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../customers/data/models/customer_models.dart';
import '../../../members/data/models/member_model.dart';
import '../report_download_controller.dart';
import 'report_download_sheet.dart';

/// "Download statement" for one farmer or customer, shown only when the
/// user may download that report (the server's report list decides).
class DownloadStatementButton extends ConsumerWidget {
  final MemberModel? farmer;
  final CustomerModel? customer;

  /// An app bar icon instead of a full-width button.
  final bool icon;

  const DownloadStatementButton.farmer(
    this.farmer, {
    super.key,
    this.icon = false,
  }) : customer = null;

  const DownloadStatementButton.customer(
    this.customer, {
    super.key,
    this.icon = false,
  }) : farmer = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = farmer != null ? 'farmer-statement' : 'customer-statement';
    final report = ref.watch(reportSpecProvider(key)).valueOrNull;
    if (report == null) return const SizedBox.shrink();
    void open() => ReportDownloadSheet.show(
      context,
      report,
      farmer: farmer,
      customer: customer,
    );
    if (icon) {
      return IconButton(
        tooltip: 'Download statement',
        icon: const Icon(Icons.download_rounded),
        onPressed: open,
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.download_rounded),
        label: const Text(
          'Download Statement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: open,
      ),
    );
  }
}
