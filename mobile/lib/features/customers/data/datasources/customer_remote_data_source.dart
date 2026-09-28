import 'package:dio/dio.dart';
import '../../../../core/pagination/page_result.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/customer_models.dart';

abstract class CustomerRemoteDataSource {
  Future<PageResult<CustomerModel>> listCustomers({
    String? search,
    String? status,
    int page = 1,
    int perPage = 50,
  });
  Future<CustomerModel> getCustomer(String id);
  Future<CustomerModel> createCustomer(CreateCustomerRequestModel request);
  Future<CustomerModel> setStatus(String id, String status);
  Future<CustomerStatementModel> getStatement(
    String id, {
    String? fromDate,
    String? toDate,
  });
  Future<({List<CustomerBalanceModel> balances, double totalOwed})>
  getBalances({bool owingOnly = true});
  Future<void> recordPayment(
    String customerId,
    RecordPaymentRequestModel request,
  );
  Future<void> voidPayment(String paymentId, String reason);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final Dio _dio;

  CustomerRemoteDataSourceImpl(this._dio);

  /// Runs a request and returns the envelope's `data`, turning server errors
  /// into exceptions carrying the server's message.
  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
    String fallback,
  ) async {
    try {
      final response = await request();
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return body['data'] as Map<String, dynamic>;
      }
      throw Exception(body['message'] ?? fallback);
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? e.response?.data['message']
          : null;
      throw Exception(serverMsg ?? e.message ?? fallback);
    }
  }

  @override
  Future<PageResult<CustomerModel>> listCustomers({
    String? search,
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (status != null) params['status'] = status;
    final data = await _send(
      () => _dio.get(ApiConstants.customers, queryParameters: params),
      'Failed to load customers',
    );
    return PageResult.fromData(data, 'customers', CustomerModel.fromJson);
  }

  @override
  Future<CustomerModel> getCustomer(String id) async {
    final data = await _send(
      () => _dio.get('${ApiConstants.customers}/$id'),
      'Failed to load customer',
    );
    return CustomerModel.fromJson(data['customer'] as Map<String, dynamic>);
  }

  @override
  Future<CustomerModel> createCustomer(
    CreateCustomerRequestModel request,
  ) async {
    final data = await _send(
      () => _dio.post(ApiConstants.customers, data: request.toJson()),
      'Failed to add customer',
    );
    return CustomerModel.fromJson(data['customer'] as Map<String, dynamic>);
  }

  @override
  Future<CustomerModel> setStatus(String id, String status) async {
    final data = await _send(
      () => _dio.patch(
        '${ApiConstants.customers}/$id/status',
        data: {'status': status},
      ),
      'Failed to update customer status',
    );
    return CustomerModel.fromJson(data['customer'] as Map<String, dynamic>);
  }

  @override
  Future<CustomerStatementModel> getStatement(
    String id, {
    String? fromDate,
    String? toDate,
  }) async {
    final params = <String, dynamic>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    final data = await _send(
      () => _dio.get(
        '${ApiConstants.customers}/$id/statement',
        queryParameters: params,
      ),
      'Failed to load statement',
    );
    return CustomerStatementModel.fromJson(
      data['statement'] as Map<String, dynamic>,
    );
  }

  @override
  Future<({List<CustomerBalanceModel> balances, double totalOwed})>
  getBalances({bool owingOnly = true}) async {
    final data = await _send(
      () => _dio.get(
        ApiConstants.customerBalances,
        queryParameters: {'owing_only': owingOnly},
      ),
      'Failed to load customer balances',
    );
    final balances = (data['balances'] as List? ?? [])
        .map((e) => CustomerBalanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      balances: balances,
      totalOwed: (data['total_owed'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<void> recordPayment(
    String customerId,
    RecordPaymentRequestModel request,
  ) async {
    await _send(
      () => _dio.post(
        '${ApiConstants.customers}/$customerId/payments',
        data: request.toJson(),
      ),
      'Failed to record payment',
    );
  }

  @override
  Future<void> voidPayment(String paymentId, String reason) async {
    await _send(
      () => _dio.post(
        '${ApiConstants.customerPayments}/$paymentId/void',
        data: {'reason': reason},
      ),
      'Failed to void payment',
    );
  }
}
