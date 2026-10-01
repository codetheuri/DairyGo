import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dairy_sacco_mobile/core/network/cache_interceptor.dart';
import 'package:dairy_sacco_mobile/features/report_downloads/data/report_download_service.dart';
import 'package:dairy_sacco_mobile/features/report_downloads/data/report_spec.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers like the report server: a file for downloads, JSON otherwise.
class _ReportServer implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object body = utf8.encode('%PDF-1.4 a report');
  Map<String, List<String>> headers = {
    'content-type': ['application/pdf'],
    'content-disposition': [
      'attachment; filename="maru-farmer-payouts-2026-10-01-to-2026-10-15.pdf"',
    ],
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final bytes = body is String
        ? utf8.encode(body as String)
        : body as List<int>;
    return ResponseBody(
      Stream.value(Uint8List.fromList(bytes)),
      status,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

const _payouts = ReportSpec(
  key: 'farmer-payouts',
  title: 'Farmer Payouts',
  description: '',
);

void main() {
  group('periods', () {
    String show(ReportPeriod p) =>
        '${p.label}: ${ReportPeriod.iso(p.from)}..${ReportPeriod.iso(p.to)}';

    test('as of a Wednesday in mid-October', () {
      final presets = ReportPeriod.presets(DateTime(2026, 10, 14, 17, 30));
      expect(presets.map(show), [
        'This month: 2026-10-01..2026-10-14',
        'Last month: 2026-09-01..2026-09-30',
        'This week: 2026-10-12..2026-10-14', // from Monday
        'Today: 2026-10-14..2026-10-14',
      ]);
    });

    test('last month from January is December of the year before', () {
      final last = ReportPeriod.presets(DateTime(2027, 1, 3))[1];
      expect(show(last), 'Last month: 2026-12-01..2026-12-31');
    });

    test('on a Monday the week is one day', () {
      final week = ReportPeriod.presets(DateTime(2026, 10, 12))[2];
      expect(show(week), 'This week: 2026-10-12..2026-10-12');
    });

    test('dates for people', () {
      expect(
        ReportPeriod('x', DateTime(2026, 9, 1), DateTime(2026, 9, 30)).dates,
        '1 Sep 2026 – 30 Sep 2026',
      );
      expect(
        ReportPeriod('x', DateTime(2026, 9, 1), DateTime(2026, 9, 1)).dates,
        '1 Sep 2026',
      );
    });
  });

  test('file names come from the server, made safe', () {
    expect(
      fileNameFrom(
        'attachment; filename="maru-sales-2026-10-01.pdf"',
        fallback: 'x.pdf',
      ),
      'maru-sales-2026-10-01.pdf',
    );
    expect(fileNameFrom(null, fallback: 'sales.pdf'), 'sales.pdf');
    expect(
      fileNameFrom(
        'attachment; filename="../../etc/passwd"',
        fallback: 'x.pdf',
      ),
      'x.pdf',
    );
    expect(
      fileNameFrom('attachment; filename="a b/c.pdf"', fallback: 'x.pdf'),
      'a-b-c.pdf',
    );
  });

  test('a report from the list', () {
    final r = ReportSpec.fromJson({
      'key': 'farmer-statement',
      'title': 'Farmer Statement',
      'description': 'd',
      'needs': 'farmer',
    });
    expect(r.needsFarmer, isTrue);
    expect(r.needsCustomer, isFalse);
    expect(ReportSpec.fromJson({'key': 'sales', 'needs': ''}).needs, isNull);
  });

  group('ReportDownloadService', () {
    late Directory dir;
    late _ReportServer server;
    late ReportDownloadService service;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('reports');
      server = _ReportServer();
      service = ReportDownloadService(
        Dio(BaseOptions(baseUrl: 'http://api'))..httpClientAdapter = server,
        baseDir: () async => dir,
      );
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('downloads the file the server made, under its name', () async {
      final progress = <double?>[];
      final file = await service.download(
        _payouts,
        format: ReportFormat.excel,
        period: ReportPeriod(
          'Last month',
          DateTime(2026, 9, 1),
          DateTime(2026, 9, 30),
        ),
        filters: const ReportFilters(status: 'ACTIVE'),
        onProgress: progress.add,
      );
      expect(
        file.path,
        endsWith('/reports/maru-farmer-payouts-2026-10-01-to-2026-10-15.pdf'),
      );
      expect(file.readAsStringSync(), '%PDF-1.4 a report');
      expect(progress, isNotEmpty);

      final sent = server.requests.single;
      expect(sent.path, '/api/v1/sacco/exports/farmer-payouts');
      expect(sent.queryParameters, {
        'format': 'xlsx',
        'from': '2026-09-01',
        'to': '2026-09-30',
        'status': 'ACTIVE',
      });
      // Never answered from, or kept in, the offline cache.
      expect(sent.extra[CacheExtra.skip], isTrue);
    });

    test('a report "as at today" sends no period', () async {
      await service.download(
        const ReportSpec(
          key: 'customers-owing',
          title: '',
          description: '',
          asAt: true,
        ),
        format: ReportFormat.pdf,
        period: ReportPeriod(
          'This month',
          DateTime(2026, 10, 1),
          DateTime(2026, 10, 14),
        ),
      );
      expect(server.requests.single.queryParameters, {'format': 'pdf'});
    });

    test('says why the server refused', () async {
      server
        ..status = 400
        ..headers = {
          'content-type': ['application/json'],
        }
        ..body = jsonEncode({
          'success': false,
          'message': 'Choose a period of at most a year',
        });
      await expectLater(
        service.download(_payouts, format: ReportFormat.pdf),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Choose a period of at most a year'),
          ),
        ),
      );
      expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
    });

    test('lists saved reports, newest first, and clears old ones', () async {
      final folder = Directory('${dir.path}/reports')..createSync();
      final old = File('${folder.path}/old.pdf')..writeAsStringSync('x');
      old.setLastModifiedSync(
        DateTime.now().subtract(const Duration(days: 40)),
      );
      File('${folder.path}/a.xlsx')
        ..writeAsStringSync('x')
        ..setLastModifiedSync(DateTime.now().subtract(const Duration(days: 2)));
      File('${folder.path}/b.pdf').writeAsStringSync('xx');

      final saved = await service.saved();
      expect(saved.map((s) => s.name), ['b.pdf', 'a.xlsx']);
      expect(saved.first.isPdf, isTrue);
      expect(old.existsSync(), isFalse);
    });
  });
}
