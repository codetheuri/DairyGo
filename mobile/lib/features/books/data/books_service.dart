import 'package:dio/dio.dart';

import '../../../core/network/api_call.dart';
import 'books_models.dart';

/// Talks to the books API (/api/v1/sacco/books).
class BooksService {
  final Dio _dio;

  BooksService(this._dio);

  static const _base = '/api/v1/sacco/books';

  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  BooksStatus _status(Map<String, dynamic> data) =>
      BooksStatus.fromJson(data['books'] as Map<String, dynamic>);

  Future<BooksStatus> status() async =>
      _status(await apiData(() => _dio.get(_base), 'Could not load the books'));

  /// Starts the books on [start], or moves their start (with a reason).
  Future<BooksStatus> start(DateTime start, {String? reason}) async => _status(
    await apiData(
      () => _dio.post(
        '$_base/start',
        data: {
          'start_date': iso(start),
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason,
        },
      ),
      'The books could not be started',
    ),
  );

  /// Compares every record with the books and posts what is missing.
  /// Returns the status and how many journals that made.
  Future<(BooksStatus, int)> bringUpToDate() async {
    final data = await apiData(
      () => _dio.post('$_base/sync'),
      'Could not bring the books up to date',
    );
    return (_status(data), (data['journals_made'] as num?)?.toInt() ?? 0);
  }

  Future<List<LedgerAccount>> accounts() async {
    final data = await apiData(
      () => _dio.get('$_base/accounts'),
      'Could not load the chart of accounts',
    );
    return [
      for (final a in (data['accounts'] as List?) ?? const [])
        LedgerAccount.fromJson(a as Map<String, dynamic>),
    ];
  }

  /// Adds (id null) or changes an account.
  Future<void> saveAccount(String? id, Map<String, dynamic> body) => apiData(
    () => id == null
        ? _dio.post('$_base/accounts', data: body)
        : _dio.put('$_base/accounts/$id', data: body),
    'The account could not be saved',
  );

  Future<List<BooksLink>> links() async => _links(
    await apiData(
      () => _dio.get('$_base/links'),
      'Could not load where records post',
    ),
  );

  Future<List<BooksLink>> setLink(String key, String accountId) async => _links(
    await apiData(
      () =>
          _dio.put('$_base/links', data: {'key': key, 'account_id': accountId}),
      'Could not change where it posts',
    ),
  );

  List<BooksLink> _links(Map<String, dynamic> data) => [
    for (final l in (data['links'] as List?) ?? const [])
      BooksLink.fromJson(l as Map<String, dynamic>),
  ];

  Future<JournalPage> journals({
    required DateTime from,
    required DateTime to,
    String? kind,
    String? accountId,
    String? search,
    int page = 1,
  }) async {
    final data = await apiData(
      () => _dio.get(
        '$_base/journals',
        queryParameters: {
          'from': iso(from),
          'to': iso(to),
          if (kind != null) 'kind': kind,
          if (accountId != null) 'account_id': accountId,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          'page': page,
        },
      ),
      'Could not load the journals',
    );
    return JournalPage.fromJson(data);
  }

  Future<Journal> journal(String id) async {
    final data = await apiData(
      () => _dio.get('$_base/journals/$id'),
      'Could not load the journal',
    );
    return Journal.fromJson(data['journal'] as Map<String, dynamic>);
  }

  Future<Journal> createJournal(Map<String, dynamic> body) async {
    final data = await apiData(
      () => _dio.post('$_base/journals', data: body),
      'The journal could not be saved',
    );
    return Journal.fromJson(data['journal'] as Map<String, dynamic>);
  }

  Future<Journal> reverseJournal(String id, String reason) async {
    final data = await apiData(
      () => _dio.post('$_base/journals/$id/reverse', data: {'reason': reason}),
      'The journal could not be reversed',
    );
    return Journal.fromJson(data['journal'] as Map<String, dynamic>);
  }

  Future<TrialBalance> trialBalance(DateTime date) async {
    final data = await apiData(
      () => _dio.get(
        '$_base/trial-balance',
        queryParameters: {'date': iso(date)},
      ),
      'Could not load the trial balance',
    );
    return TrialBalance.fromJson(data['trial_balance'] as Map<String, dynamic>);
  }

  Future<AccountLedger> ledger(String id, DateTime from, DateTime to) async {
    final data = await apiData(
      () => _dio.get(
        '$_base/accounts/$id/ledger',
        queryParameters: {'from': iso(from), 'to': iso(to)},
      ),
      'Could not load the account',
    );
    return AccountLedger.fromJson(data['ledger'] as Map<String, dynamic>);
  }
}
