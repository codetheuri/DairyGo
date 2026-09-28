import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/audit_log_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../customers/presentation/controllers/customer_controller.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../data/datasources/field_ops_remote_data_source.dart';
import '../../data/models/field_ops_models.dart';
import '../../data/repositories/field_ops_repository_impl.dart';
import '../../domain/repositories/field_ops_repository.dart';

final fieldOpsRemoteDataSourceProvider = Provider<FieldOpsRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioClientProvider);
  return FieldOpsRemoteDataSourceImpl(dio);
});

final fieldOpsRepositoryProvider = Provider<FieldOpsRepository>((ref) {
  final dataSource = ref.watch(fieldOpsRemoteDataSourceProvider);
  return FieldOpsRepositoryImpl(dataSource);
});

final fieldOpsFilterDateProvider = StateProvider.autoDispose<String>(
  (ref) => getTodayDateString(),
);

final reconciliationProvider =
    FutureProvider.family<ReconciliationModel, String?>((ref, date) async {
      ref.reloadWhenNewerDataArrives();
      final repository = ref.watch(fieldOpsRepositoryProvider);
      return repository.getReconciliation(date: date);
    });

final saleHistoryProvider = FutureProvider.autoDispose
    .family<List<AuditLogModel>, String>((ref, id) async {
      return ref.watch(fieldOpsRepositoryProvider).getSaleHistory(id);
    });

/// Voids a sale (admins only). Returns null on success or the error message.
Future<String?> voidSale(WidgetRef ref, String id, String reason) async {
  try {
    await ref.read(fieldOpsRepositoryProvider).voidSale(id, reason);
    ref.invalidate(saleHistoryProvider(id));
    ref.invalidate(salesListProvider);
    ref.invalidate(reconciliationProvider(null));
    invalidateCustomerDataFromWidget(ref);
    return null;
  } catch (e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}

final salesListProvider = FutureProvider<List<MilkSaleModel>>((ref) async {
  ref.reloadWhenNewerDataArrives();
  final repository = ref.watch(fieldOpsRepositoryProvider);
  final date = ref.watch(fieldOpsFilterDateProvider);
  return repository.listSales(fromDate: date, toDate: date);
});

final spoilageListProvider = FutureProvider<List<MilkSpoilageModel>>((
  ref,
) async {
  ref.reloadWhenNewerDataArrives();
  final repository = ref.watch(fieldOpsRepositoryProvider);
  final date = ref.watch(fieldOpsFilterDateProvider);
  return repository.listSpoilage(fromDate: date, toDate: date);
});

class RecordSaleController extends StateNotifier<AsyncValue<MilkSaleModel?>> {
  final FieldOpsRepository _repository;
  final Ref _ref;

  RecordSaleController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<bool> recordSale(RecordSaleRequestModel request) async {
    state = const AsyncValue.loading();
    try {
      final sale = await _repository.recordSale(request);
      state = AsyncValue.data(sale);
      invalidateAllAppMetrics(_ref);
      invalidateCustomerData(_ref);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final recordSaleControllerProvider =
    StateNotifierProvider.autoDispose<
      RecordSaleController,
      AsyncValue<MilkSaleModel?>
    >((ref) {
      final repository = ref.watch(fieldOpsRepositoryProvider);
      return RecordSaleController(repository, ref);
    });

class RecordSpoilageController
    extends StateNotifier<AsyncValue<MilkSpoilageModel?>> {
  final FieldOpsRepository _repository;
  final Ref _ref;

  RecordSpoilageController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<bool> recordSpoilage(RecordSpoilageRequestModel request) async {
    state = const AsyncValue.loading();
    try {
      final spoilage = await _repository.recordSpoilage(request);
      state = AsyncValue.data(spoilage);
      invalidateAllAppMetrics(_ref);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final recordSpoilageControllerProvider =
    StateNotifierProvider.autoDispose<
      RecordSpoilageController,
      AsyncValue<MilkSpoilageModel?>
    >((ref) {
      final repository = ref.watch(fieldOpsRepositoryProvider);
      return RecordSpoilageController(repository, ref);
    });
