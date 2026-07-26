import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../data/datasources/field_ops_remote_data_source.dart';
import '../../data/models/field_ops_models.dart';
import '../../data/repositories/field_ops_repository_impl.dart';
import '../../domain/repositories/field_ops_repository.dart';

final fieldOpsRemoteDataSourceProvider = Provider<FieldOpsRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return FieldOpsRemoteDataSourceImpl(dio);
});

final fieldOpsRepositoryProvider = Provider<FieldOpsRepository>((ref) {
  final dataSource = ref.watch(fieldOpsRemoteDataSourceProvider);
  return FieldOpsRepositoryImpl(dataSource);
});

final fieldOpsFilterDateProvider = StateProvider.autoDispose<String>((ref) => getTodayDateString());

final reconciliationProvider =
    FutureProvider.autoDispose.family<ReconciliationModel, String?>((ref, date) async {
  final repository = ref.watch(fieldOpsRepositoryProvider);
  return repository.getReconciliation(date: date);
});

final salesListProvider = FutureProvider.autoDispose<List<MilkSaleModel>>((ref) async {
  final repository = ref.watch(fieldOpsRepositoryProvider);
  final date = ref.watch(fieldOpsFilterDateProvider);
  return repository.listSales(fromDate: date, toDate: date);
});

final spoilageListProvider = FutureProvider.autoDispose<List<MilkSpoilageModel>>((ref) async {
  final repository = ref.watch(fieldOpsRepositoryProvider);
  final date = ref.watch(fieldOpsFilterDateProvider);
  return repository.listSpoilage(fromDate: date, toDate: date);
});

class RecordSaleController extends StateNotifier<AsyncValue<MilkSaleModel?>> {
  final FieldOpsRepository _repository;
  final Ref _ref;

  RecordSaleController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> recordSale(RecordSaleRequestModel request) async {
    state = const AsyncValue.loading();
    try {
      final sale = await _repository.recordSale(request);
      state = AsyncValue.data(sale);
      _ref.invalidate(salesListProvider);
      _ref.invalidate(reconciliationProvider(null));
      _ref.invalidate(collectorDashboardProvider(null));
      _ref.invalidate(executiveDashboardProvider(7));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final recordSaleControllerProvider =
    StateNotifierProvider.autoDispose<RecordSaleController, AsyncValue<MilkSaleModel?>>((ref) {
  final repository = ref.watch(fieldOpsRepositoryProvider);
  return RecordSaleController(repository, ref);
});

class RecordSpoilageController extends StateNotifier<AsyncValue<MilkSpoilageModel?>> {
  final FieldOpsRepository _repository;
  final Ref _ref;

  RecordSpoilageController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> recordSpoilage(RecordSpoilageRequestModel request) async {
    state = const AsyncValue.loading();
    try {
      final spoilage = await _repository.recordSpoilage(request);
      state = AsyncValue.data(spoilage);
      _ref.invalidate(spoilageListProvider);
      _ref.invalidate(reconciliationProvider(null));
      _ref.invalidate(collectorDashboardProvider(null));
      _ref.invalidate(executiveDashboardProvider(7));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final recordSpoilageControllerProvider =
    StateNotifierProvider.autoDispose<RecordSpoilageController, AsyncValue<MilkSpoilageModel?>>((ref) {
  final repository = ref.watch(fieldOpsRepositoryProvider);
  return RecordSpoilageController(repository, ref);
});
