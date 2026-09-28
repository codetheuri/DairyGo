import '../../../../core/pagination/page_result.dart';
import '../../data/models/customer_models.dart';

abstract class CustomerRepository {
  Future<PageResult<CustomerModel>> listCustomers({String? search, String? status, int page = 1, int perPage = 50});
  Future<CustomerModel> getCustomer(String id);
  Future<CustomerModel> createCustomer(CreateCustomerRequestModel request);
  Future<CustomerModel> setStatus(String id, String status);
  Future<CustomerStatementModel> getStatement(String id, {String? fromDate, String? toDate});
  Future<({List<CustomerBalanceModel> balances, double totalOwed})> getBalances({bool owingOnly = true});
  Future<void> recordPayment(String customerId, RecordPaymentRequestModel request);
  Future<void> voidPayment(String paymentId, String reason);
}
