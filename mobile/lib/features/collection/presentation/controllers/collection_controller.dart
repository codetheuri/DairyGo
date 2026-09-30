import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/pagination/page_result.dart';
import '../../../../core/pagination/paged_list_notifier.dart';
import '../../../../core/models/audit_log_model.dart';

import '../../../../core/network/dio_client.dart';
import '../../../members/presentation/controllers/member_controller.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../data/datasources/milk_collection_remote_data_source.dart';
import '../../data/models/milk_collection_model.dart';
import '../../data/repositories/milk_collection_repository_impl.dart';
import '../../domain/repositories/milk_collection_repository.dart';

final milkCollectionRemoteDataSourceProvider =
    Provider<MilkCollectionRemoteDataSource>((ref) {
      final dio = ref.watch(dioClientProvider);
      return MilkCollectionRemoteDataSourceImpl(dio);
    });

final milkCollectionRepositoryProvider = Provider<MilkCollectionRepository>((
  ref,
) {
  final dataSource = ref.watch(milkCollectionRemoteDataSourceProvider);
  return MilkCollectionRepositoryImpl(dataSource);
});

final activeMilkPriceProvider = FutureProvider<MilkPriceModel>((ref) async {
  final repository = ref.watch(milkCollectionRepositoryProvider);
  return repository.getActivePrice();
});

/// Audit history of one collection, oldest first.
final collectionHistoryProvider = FutureProvider.autoDispose
    .family<List<AuditLogModel>, String>((ref, id) async {
      final repository = ref.watch(milkCollectionRepositoryProvider);
      return repository.getCollectionHistory(id);
    });

String getTodayDateString() {
  final now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
}

final collectionFilterShiftProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final collectionFilterDateProvider = StateProvider.autoDispose<String>(
  (ref) => getTodayDateString(),
);
final collectionSearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// One day's collections, loaded page by page as the user scrolls. The server
/// sends each row's farmer name, so no farmer list is downloaded.
final milkCollectionsListProvider =
    AsyncNotifierProvider<
      MilkCollectionsListNotifier,
      PagedList<MilkCollectionModel>
    >(MilkCollectionsListNotifier.new);

class MilkCollectionsListNotifier
    extends PagedListNotifier<MilkCollectionModel> {
  @override
  Future<PagedList<MilkCollectionModel>> build() async {
    final repository = ref.watch(milkCollectionRepositoryProvider);
    final shift = ref.watch(collectionFilterShiftProvider);
    final date = ref.watch(collectionFilterDateProvider);
    final search = ref.watch(collectionSearchProvider).trim();
    await debounce(search);

    return loadFirstPage((page) async {
      final result = await repository.listCollections(
        shift: shift,
        fromDate: date,
        toDate: date,
        search: search,
        page: page,
        perPage: PagedListNotifier.pageSize,
      );
      return PageResult(
        result.items.map(_withCollectorLabel).toList(),
        hasMore: result.hasMore,
      );
    });
  }

  static MilkCollectionModel _withCollectorLabel(MilkCollectionModel c) {
    final name = c.collectorName;
    return name != null && name.isNotEmpty
        ? c
        : c.copyWith(collectorName: 'Staff #${c.collectorId}');
  }
}

class RecordMilkCollectionController
    extends StateNotifier<AsyncValue<MilkCollectionModel?>> {
  final MilkCollectionRepository _repository;
  final Ref _ref;

  RecordMilkCollectionController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<bool> recordCollection(RecordCollectionRequestModel request) async {
    state = const AsyncValue.loading();
    try {
      final collection = await _repository.recordCollection(request);
      state = AsyncValue.data(collection);
      invalidateAllAppMetrics(_ref);
      // An inactive farmer who brings milk is active again: show that.
      _ref.invalidate(memberDetailsProvider(request.memberId));
      _ref.invalidate(memberHistoryProvider(request.memberId));
      _ref.invalidate(membersListProvider);
      _ref.invalidate(farmerPickerResultsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final recordMilkCollectionControllerProvider =
    StateNotifierProvider.autoDispose<
      RecordMilkCollectionController,
      AsyncValue<MilkCollectionModel?>
    >((ref) {
      final repository = ref.watch(milkCollectionRepositoryProvider);
      return RecordMilkCollectionController(repository, ref);
    });

class UpdateMilkCollectionController
    extends StateNotifier<AsyncValue<MilkCollectionModel?>> {
  final MilkCollectionRepository _repository;
  final Ref _ref;

  UpdateMilkCollectionController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<bool> updateCollection(
    String id,
    UpdateCollectionRequestModel request,
  ) async {
    state = const AsyncValue.loading();
    try {
      final collection = await _repository.updateCollection(id, request);
      state = AsyncValue.data(collection);
      invalidateAllAppMetrics(_ref);
      _ref.invalidate(collectionHistoryProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final updateMilkCollectionControllerProvider =
    StateNotifierProvider.autoDispose<
      UpdateMilkCollectionController,
      AsyncValue<MilkCollectionModel?>
    >((ref) {
      final repository = ref.watch(milkCollectionRepositoryProvider);
      return UpdateMilkCollectionController(repository, ref);
    });
