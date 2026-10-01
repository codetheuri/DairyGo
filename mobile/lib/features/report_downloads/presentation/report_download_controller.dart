import 'dart:io';

import 'package:flutter/services.dart';
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

  static const _files = MethodChannel('dairygo/files');

  /// Saves a copy of [file] where the user picks on Android's "Save as"
  /// screen (Downloads, Documents, a memory card). The copy stays after the
  /// app deletes its own after 30 days. Returns a message to show, or null
  /// when the user backed out.
  static Future<String?> saveToPhone(File file) async {
    String? outcome;
    try {
      outcome = await _files.invokeMethod<String>('saveAs', {
        'path': file.path,
        'mime': file.path.endsWith('.xlsx')
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : 'application/pdf',
      });
    } on MissingPluginException {
      outcome = 'failed'; // not on Android
    } on PlatformException {
      outcome = 'failed';
    }
    return switch (outcome) {
      'saved' => 'Saved to your phone',
      'cancelled' => null,
      _ => 'The report could not be saved. Share it instead.',
    };
  }

  /// Shares [file] (WhatsApp, email, ...).
  static Future<void> share(File file, String title) => SharePlus.instance
      .share(ShareParams(files: [XFile(file.path)], subject: title));
}
