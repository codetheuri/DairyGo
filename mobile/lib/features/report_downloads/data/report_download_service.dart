import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/cache_interceptor.dart';
import 'report_spec.dart';

/// What to put in a report besides its period and format.
class ReportFilters {
  final String? memberId;
  final String? customerId;
  final String? status;

  const ReportFilters({this.memberId, this.customerId, this.status});
}

/// A report saved on the phone.
class SavedReport {
  final File file;
  final DateTime savedAt;
  final int size;

  const SavedReport(this.file, this.savedAt, this.size);

  String get name => file.uri.pathSegments.last;
  bool get isPdf => name.toLowerCase().endsWith('.pdf');
}

/// Downloads reports made by the server. Reports are kept in the app's own
/// folder (no storage permission needed) for [keepFor], then deleted.
class ReportDownloadService {
  static const keepFor = Duration(days: 30);

  final Dio _dio;
  final Future<Directory> Function() _baseDir;

  ReportDownloadService(this._dio, {Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationDocumentsDirectory;

  /// The reports this user may download.
  Future<List<ReportSpec>> catalog() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiConstants.exports);
      final list = (res.data?['data']?['reports'] as List?) ?? const [];
      return list
          .map((e) => ReportSpec.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_message(e) ?? 'Could not load the reports');
    }
  }

  Future<Directory> _folder() async {
    final dir = Directory('${(await _baseDir()).path}/reports');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Downloads [report] and returns the saved file. [onProgress] gets 0..1,
  /// or null while the size is unknown.
  Future<File> download(
    ReportSpec report, {
    required ReportFormat format,
    ReportPeriod? period,
    ReportFilters filters = const ReportFilters(),
    CancelToken? cancel,
    void Function(double? progress)? onProgress,
  }) async {
    try {
      final res = await _dio.get<List<int>>(
        '${ApiConstants.exports}/${report.key}',
        queryParameters: {
          'format': format.query,
          if (period != null && !report.asAt) ...{
            'from': ReportPeriod.iso(period.from),
            'to': ReportPeriod.iso(period.to),
          },
          if (filters.memberId != null) 'member_id': filters.memberId,
          if (filters.customerId != null) 'customer_id': filters.customerId,
          if (filters.status != null) 'status': filters.status,
        },
        cancelToken: cancel,
        onReceiveProgress: (received, total) =>
            onProgress?.call(total > 0 ? received / total : null),
        options: Options(
          responseType: ResponseType.bytes,
          // Reports are made fresh and never kept in the offline cache.
          extra: {CacheExtra.skip: true},
          // A big report can take a while on a slow link.
          receiveTimeout: const Duration(minutes: 3),
        ),
      );
      final name = fileNameFrom(
        res.headers.value('content-disposition'),
        fallback: '${report.key}.${format.query}',
      );
      final file = File('${(await _folder()).path}/$name');
      await file.writeAsBytes(res.data ?? const [], flush: true);
      return file;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw Exception(
        _message(e) ??
            'The report could not be downloaded. Check your connection and try again.',
      );
    }
  }

  /// Reports saved on the phone, newest first. Old ones are deleted.
  Future<List<SavedReport>> saved() async {
    final dir = await _folder();
    final out = <SavedReport>[];
    final cutoff = DateTime.now().subtract(keepFor);
    await for (final f in dir.list()) {
      if (f is! File) continue;
      final stat = await f.stat();
      if (stat.modified.isBefore(cutoff)) {
        await f.delete().catchError((_) => f);
        continue;
      }
      out.add(SavedReport(f, stat.modified, stat.size));
    }
    out.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return out;
  }

  /// Deletes one saved report from the phone.
  Future<void> delete(File file) async {
    if (await file.exists()) await file.delete();
  }

  /// Deletes every saved report from the phone.
  Future<void> deleteAll() async {
    final dir = await _folder();
    await for (final f in dir.list()) {
      if (f is File) await f.delete().catchError((_) => f);
    }
  }

  /// The server's reason for refusing, from a JSON body sent as bytes.
  static String? _message(DioException e) {
    var data = e.response?.data;
    if (data is List<int>) {
      try {
        data = jsonDecode(utf8.decode(data));
      } catch (_) {
        return null;
      }
    }
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first?.toString();
      if (first != null && first.isNotEmpty) return first;
    }
    return data['message']?.toString();
  }
}

/// The file name from a Content-Disposition header, made safe to save.
String fileNameFrom(String? header, {required String fallback}) {
  final match = RegExp(r'filename="?([^";]+)"?').firstMatch(header ?? '');
  final raw = match?.group(1)?.trim() ?? fallback;
  final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
  return safe.isEmpty || safe.startsWith('.') ? fallback : safe;
}
