import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/models/audit_log_model.dart';
import '../../../core/pagination/page_result.dart';
import 'transfer_models.dart';

/// Milk transfers between collectors (/api/v1/sacco/milk-transfers).
class TransferRepository {
  final Dio _dio;

  TransferRepository(this._dio);

  /// The server's message for a failed request, or [fallback].
  static Exception _error(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] : null;
      return Exception(message ?? e.message ?? fallback);
    }
    return Exception(fallback);
  }

  static Map<String, dynamic> _data(Response<dynamic> res) {
    final body = res.data as Map<String, dynamic>;
    if (body['success'] != true || body['data'] == null) {
      throw Exception(body['message'] ?? 'Unexpected answer from the server');
    }
    return body['data'] as Map<String, dynamic>;
  }

  /// Colleagues the signed-in user can transfer milk to.
  Future<List<TransferRecipientModel>> recipients() async {
    try {
      final data = _data(
        await _dio.get('${ApiConstants.transfers}/recipients'),
      );
      return (data['collectors'] as List? ?? [])
          .map(
            (e) => TransferRecipientModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw _error(e, 'Could not load collectors');
    }
  }

  /// One page of transfers. Collectors get only those they sent or received.
  Future<PageResult<MilkTransferModel>> list({
    int? collectorId,
    String? direction,
    String? fromDate,
    String? toDate,
    bool includeCancelled = false,
    int page = 1,
    int perPage = maxPageSize,
  }) async {
    try {
      final data = _data(
        await _dio.get(
          ApiConstants.transfers,
          queryParameters: {
            'page': page,
            'per_page': perPage,
            'collector_id': ?collectorId,
            'direction': ?direction,
            'from_date': ?fromDate,
            'to_date': ?toDate,
            if (includeCancelled) 'include_cancelled': true,
          },
        ),
      );
      return PageResult.fromData(data, 'transfers', MilkTransferModel.fromJson);
    } catch (e) {
      throw _error(e, 'Could not load transfers');
    }
  }

  Future<MilkTransferModel> record({
    required int toCollectorId,
    required double litres,
    String? transferDate,
    int? fromCollectorId,
    String? notes,
  }) async {
    try {
      final data = _data(
        await _dio.post(
          ApiConstants.transfers,
          data: {
            'to_collector_id': toCollectorId,
            'quantity_litres': litres,
            'transfer_date': ?transferDate,
            'from_collector_id': ?fromCollectorId,
            'notes': ?notes,
          },
        ),
      );
      return MilkTransferModel.fromJson(
        data['transfer'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw _error(e, 'Could not record the transfer');
    }
  }

  Future<MilkTransferModel> update(
    String id, {
    int? toCollectorId,
    double? litres,
    String? notes,
    String? reason,
  }) async {
    try {
      final data = _data(
        await _dio.put(
          '${ApiConstants.transfers}/$id',
          data: {
            'to_collector_id': ?toCollectorId,
            'quantity_litres': ?litres,
            'notes': ?notes,
            'reason': ?reason,
          },
        ),
      );
      return MilkTransferModel.fromJson(
        data['transfer'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw _error(e, 'Could not change the transfer');
    }
  }

  Future<void> cancel(String id, String reason) async {
    try {
      _data(
        await _dio.post(
          '${ApiConstants.transfers}/$id/cancel',
          data: {'reason': reason},
        ),
      );
    } catch (e) {
      throw _error(e, 'Could not cancel the transfer');
    }
  }

  Future<List<AuditLogModel>> history(String id) async {
    try {
      final data = _data(
        await _dio.get('${ApiConstants.transfers}/$id/history'),
      );
      return (data['history'] as List? ?? [])
          .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _error(e, 'Could not load the history');
    }
  }
}
