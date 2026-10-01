import 'package:dio/dio.dart';

import '../../../core/network/api_call.dart';
import 'payout_models.dart';

/// Talks to the payout API: deductions, farmer accounts and pay runs.
class PayoutService {
  final Dio _dio;

  PayoutService(this._dio);

  static const _base = '/api/v1/sacco';

  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // --- deductions ---

  Future<List<DeductionType>> deductionTypes() async {
    final data = await apiData(
      () => _dio.get('$_base/deduction-types'),
      'Could not load the deductions',
    );
    return [
      for (final d in (data['deductions'] as List?) ?? const [])
        DeductionType.fromJson(d as Map<String, dynamic>),
    ];
  }

  /// Creates (id null) or changes a deduction; only the fields given change.
  Future<DeductionType> saveDeductionType(
    String? id,
    Map<String, dynamic> body,
  ) async {
    final data = await apiData(
      () => id == null
          ? _dio.post('$_base/deduction-types', data: body)
          : _dio.put('$_base/deduction-types/$id', data: body),
      'The deduction could not be saved',
    );
    return DeductionType.fromJson(data['deduction'] as Map<String, dynamic>);
  }

  Future<void> deleteDeductionType(String id) => apiData(
    () => _dio.delete('$_base/deduction-types/$id'),
    'The deduction could not be deleted',
  );

  // --- a farmer ---

  Future<List<FarmerDeduction>> farmerDeductions(String memberId) async {
    final data = await apiData(
      () => _dio.get('$_base/members/$memberId/deductions'),
      "Could not load the farmer's deductions",
    );
    return [
      for (final d in (data['deductions'] as List?) ?? const [])
        FarmerDeduction.fromJson(d as Map<String, dynamic>),
    ];
  }

  Future<void> setFarmerDeduction(
    String memberId,
    String typeId, {
    required bool applies,
    double? amount,
    double? target,
  }) => apiData(
    () => _dio.put(
      '$_base/members/$memberId/deductions/$typeId',
      data: {'applies': applies, 'amount': ?amount, 'target_amount': ?target},
    ),
    'Could not save',
  );

  Future<FarmerAccount> account(
    String memberId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final data = await apiData(
      () => _dio.get(
        '$_base/members/$memberId/account',
        queryParameters: {
          'from': ?(from == null ? null : iso(from)),
          'to': ?(to == null ? null : iso(to)),
        },
      ),
      "Could not load the farmer's account",
    );
    return FarmerAccount.fromJson(data['account'] as Map<String, dynamic>);
  }

  Future<AdvanceInfo> advanceInfo(String memberId) async {
    final data = await apiData(
      () => _dio.get('$_base/members/$memberId/advance'),
      'Could not check the advance limit',
    );
    return AdvanceInfo.fromJson(data['advance'] as Map<String, dynamic>);
  }

  /// Records an advance, charge or adjustment ([kind] advances, charges,
  /// adjustments).
  Future<void> recordEntry(
    String memberId,
    String kind,
    Map<String, dynamic> body,
  ) => apiData(
    () => _dio.post('$_base/members/$memberId/$kind', data: body),
    'Could not save',
  );

  Future<void> voidEntry(String id, String reason) => apiData(
    () =>
        _dio.post('$_base/account-entries/$id/void', data: {'reason': reason}),
    'Could not void',
  );

  // --- pay runs ---

  Future<PayRunList> payRuns() async {
    final data = await apiData(
      () => _dio.get('$_base/pay-runs'),
      'Could not load the pay runs',
    );
    return PayRunList.fromJson(data);
  }

  Future<PayRunDetail> payRun(String id, {String? search}) async {
    final data = await apiData(
      () => _dio.get(
        '$_base/pay-runs/$id',
        queryParameters: {if ((search ?? '').isNotEmpty) 'search': search},
      ),
      'Could not load the pay run',
    );
    return PayRunDetail.fromJson(data);
  }

  Future<PayRunDetail> createPayRun(DateTime from, DateTime to) async {
    final data = await apiData(
      () => _dio.post(
        '$_base/pay-runs',
        data: {'from_date': iso(from), 'to_date': iso(to)},
      ),
      'The pay run could not be worked out',
    );
    return PayRunDetail.fromJson(data);
  }

  Future<PayRunDetail> recompute(String id) async => PayRunDetail.fromJson(
    await apiData(
      () => _dio.post('$_base/pay-runs/$id/recompute'),
      'Could not work it out again',
    ),
  );

  /// Approves with the net total the user saw; refused if it changed.
  Future<PayRunDetail> approve(String id, double expectedNet) async =>
      PayRunDetail.fromJson(
        await apiData(
          () => _dio.post(
            '$_base/pay-runs/$id/approve',
            data: {'expected_total_net': expectedNet},
          ),
          'The pay run could not be approved',
        ),
      );

  Future<void> cancel(String id, {String? reason}) => apiData(
    () => _dio.post('$_base/pay-runs/$id/cancel', data: {'reason': ?reason}),
    'The pay run could not be cancelled',
  );

  /// Marks farmers paid; no [lineIds] marks everyone still to be paid.
  Future<PayRunDetail> pay(
    String id, {
    List<String>? lineIds,
    required String method,
    String? reference,
    String? accountId,
  }) async => PayRunDetail.fromJson(
    await apiData(
      () => _dio.post(
        '$_base/pay-runs/$id/pay',
        data: {
          'line_ids': ?lineIds,
          'method': method,
          'reference': ?reference,
          'cash_account_id': ?accountId,
        },
      ),
      'Could not mark them paid',
    ),
  );

  Future<int> sendSms(String id) async {
    final data = await apiData(
      () => _dio.post('$_base/pay-runs/$id/sms'),
      'The messages could not be sent',
    );
    return (data['queued'] as num?)?.toInt() ?? 0;
  }

  /// Paths of the pay run's files, for [ReportDownloadService.downloadPath].
  static String registerPath(String id) => '$_base/pay-runs/$id/register';
  static String paymentFilePath(String id) =>
      '$_base/pay-runs/$id/payment-file';
  static String payslipPath(String id, String memberId) =>
      '$_base/pay-runs/$id/payslips/$memberId';
}
