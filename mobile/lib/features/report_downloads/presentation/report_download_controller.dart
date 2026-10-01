import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/network/dio_client.dart';
import '../data/report_download_service.dart';
import '../data/report_spec.dart';

final reportDownloadServiceProvider = Provider<ReportDownloadService>(
  (ref) => ReportDownloadService(ref.watch(dioClientProvider)),
);

/// The reports this user may download.
final reportCatalogProvider = FutureProvider.autoDispose<List<ReportSpec>>(
  (ref) => ref.watch(reportDownloadServiceProvider).catalog(),
);

/// One report from the catalog, or null when the user may not download it.
final reportSpecProvider = FutureProvider.autoDispose
    .family<ReportSpec?, String>((ref, key) async {
      final list = await ref.watch(reportCatalogProvider.future);
      for (final r in list) {
        if (r.key == key) return r;
      }
      return null;
    });

/// Reports downloaded earlier and still on the phone.
final savedReportsProvider = FutureProvider.autoDispose<List<SavedReport>>(
  (ref) => ref.watch(reportDownloadServiceProvider).saved(),
);

/// Opens and shares saved reports with the phone's own apps.
class ReportFiles {
  /// Opens [file] in a PDF or spreadsheet viewer. Returns a message when no
  /// app can open it.
  static Future<String?> open(File file) async {
    final result = await OpenFilex.open(file.path);
    return switch (result.type) {
      ResultType.done => null,
      ResultType.noAppToOpen =>
        file.path.endsWith('.xlsx')
            ? 'No app on this phone opens Excel files. Share it instead, or install Google Sheets or Excel.'
            : 'No app on this phone opens PDF files. Share it instead.',
      _ => 'The report could not be opened: ${result.message}',
    };
  }

  /// Shares [file] (WhatsApp, email, ...).
  static Future<void> share(File file, String title) => SharePlus.instance
      .share(ShareParams(files: [XFile(file.path)], subject: title));
}
