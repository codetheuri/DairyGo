import '../../../../core/pagination/page_result.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';
import '../models/customer_models.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource _remote;

  CustomerRepositoryImpl(this._remote);

  @override
  Future<PageResult<CustomerModel>> listCustomers({
    String? search,
    String? status,
    int page = 1,
    int perPage = 50,
  }) => _remote.listCustomers(
    search: search,
    status: status,
    page: page,
    perPage: perPage,
  );

  @override
  Future<CustomerModel> getCustomer(String id) => _remote.getCustomer(id);

  @override
  Future<CustomerModel> createCustomer(CreateCustomerRequestModel request) =>
      _remote.createCustomer(request);

  @override
  Future<CustomerModel> setStatus(String id, String status) =>
      _remote.setStatus(id, status);

  @override
  Future<CustomerStatementModel> getStatement(
    String id, {
    String? fromDate,
    String? toDate,
  }) => _remote.getStatement(id, fromDate: fromDate, toDate: toDate);

  @override
  Future<({List<CustomerBalanceModel> balances, double totalOwed})>
  getBalances({bool owingOnly = true}) =>
      _remote.getBalances(owingOnly: owingOnly);

  @override
  Future<void> recordPayment(
    String customerId,
    RecordPaymentRequestModel request,
  ) => _remote.recordPayment(customerId, request);

  @override
  Future<void> voidPayment(String paymentId, String reason) =>
      _remote.voidPayment(paymentId, reason);
}
