import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/pagination/paged_list_notifier.dart';
import '../../data/datasources/customer_remote_data_source.dart';
import '../../data/models/customer_models.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/repositories/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return CustomerRepositoryImpl(CustomerRemoteDataSourceImpl(dio));
});

/// Search text for the customers list screen.
final customerSearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// The customers list, loaded page by page as the user scrolls. The screen
/// already waits for a pause in typing before changing the search.
final customersListProvider =
    AsyncNotifierProvider<CustomersListNotifier, PagedList<CustomerModel>>(
      CustomersListNotifier.new,
    );

class CustomersListNotifier extends PagedListNotifier<CustomerModel> {
  @override
  Future<PagedList<CustomerModel>> build() {
    final repository = ref.watch(customerRepositoryProvider);
    final search = ref.watch(customerSearchProvider);
    return loadFirstPage(
      (page) => repository.listCustomers(
        search: search,
        page: page,
        perPage: PagedListNotifier.pageSize,
      ),
    );
  }
}

/// Active customers matching a search, used by the sale customer picker.
final customerPickerResultsProvider = FutureProvider.autoDispose
    .family<List<CustomerModel>, String>((ref, search) async {
      final result = await ref
          .watch(customerRepositoryProvider)
          .listCustomers(search: search, status: 'ACTIVE', perPage: 30);
      return result.items;
    });

final customerDetailProvider = FutureProvider.autoDispose
    .family<CustomerModel, String>((ref, id) async {
      return ref.watch(customerRepositoryProvider).getCustomer(id);
    });

/// A statement request: customer and inclusive date range (YYYY-MM-DD).
typedef StatementQuery = ({String customerId, String fromDate, String toDate});

final customerStatementProvider = FutureProvider.autoDispose
    .family<CustomerStatementModel, StatementQuery>((ref, q) async {
      return ref
          .watch(customerRepositoryProvider)
          .getStatement(q.customerId, fromDate: q.fromDate, toDate: q.toDate);
    });

final customerBalancesProvider =
    FutureProvider.autoDispose<
      ({List<CustomerBalanceModel> balances, double totalOwed})
    >((ref) async {
      return ref.watch(customerRepositoryProvider).getBalances(owingOnly: true);
    });

/// Refreshes every customer view after a sale, payment or customer change.
void invalidateCustomerData(Ref ref) {
  ref.invalidate(customersListProvider);
  ref.invalidate(customerPickerResultsProvider);
  ref.invalidate(customerDetailProvider);
  ref.invalidate(customerStatementProvider);
  ref.invalidate(customerBalancesProvider);
}

/// Same as [invalidateCustomerData], for callers holding a [WidgetRef].
void invalidateCustomerDataFromWidget(WidgetRef ref) {
  ref.invalidate(customersListProvider);
  ref.invalidate(customerPickerResultsProvider);
  ref.invalidate(customerDetailProvider);
  ref.invalidate(customerStatementProvider);
  ref.invalidate(customerBalancesProvider);
}

/// Creates, updates and settles customers. Each method returns null on success
/// or the error message to show.
class CustomerActionsController extends StateNotifier<AsyncValue<void>> {
  final CustomerRepository _repository;
  final Ref _ref;

  CustomerActionsController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<CustomerModel?> create(CreateCustomerRequestModel request) async {
    state = const AsyncValue.loading();
    try {
      final customer = await _repository.createCustomer(request);
      state = const AsyncValue.data(null);
      invalidateCustomerData(_ref);
      return customer;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<String?> setStatus(String id, String status) =>
      _run(() => _repository.setStatus(id, status));

  Future<String?> recordPayment(
    String customerId,
    RecordPaymentRequestModel request,
  ) => _run(() => _repository.recordPayment(customerId, request));

  Future<String?> voidPayment(String paymentId, String reason) =>
      _run(() => _repository.voidPayment(paymentId, reason));

  Future<String?> _run(Future<Object?> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      state = const AsyncValue.data(null);
      invalidateCustomerData(_ref);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}

final customerActionsProvider =
    StateNotifierProvider.autoDispose<
      CustomerActionsController,
      AsyncValue<void>
    >((ref) {
      return CustomerActionsController(
        ref.watch(customerRepositoryProvider),
        ref,
      );
    });
