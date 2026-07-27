import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../members/data/models/member_model.dart';
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

final milkCollectionRepositoryProvider =
    Provider<MilkCollectionRepository>((ref) {
  final dataSource = ref.watch(milkCollectionRemoteDataSourceProvider);
  return MilkCollectionRepositoryImpl(dataSource);
});

final activeMilkPriceProvider = FutureProvider<MilkPriceModel>((ref) async {
  final repository = ref.watch(milkCollectionRepositoryProvider);
  return repository.getActivePrice();
});

String getTodayDateString() {
  final now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
}

final collectionFilterShiftProvider = StateProvider.autoDispose<String?>((ref) => null);
final collectionFilterDateProvider = StateProvider.autoDispose<String>((ref) => getTodayDateString());
final collectionSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final milkCollectionsListProvider =
    FutureProvider<List<MilkCollectionModel>>((ref) async {
  final repository = ref.watch(milkCollectionRepositoryProvider);
  final memberRepo = ref.watch(memberRepositoryProvider);
  final shift = ref.watch(collectionFilterShiftProvider);
  final date = ref.watch(collectionFilterDateProvider);
  final search = ref.watch(collectionSearchProvider);

  final collections = await repository.listCollections(
    shift: shift,
    fromDate: date,
    toDate: date,
    search: search,
    perPage: 100,
  );

  // Cross-reference members list to populate farmer full name & membership number
  final members = await memberRepo.listMembers(perPage: 200).catchError((_) => <MemberModel>[]);
  final memberMap = {for (var m in members) m.id: m};

  return collections.map((c) {
    final member = memberMap[c.memberId];
    if (member != null) {
      return c.copyWith(
        memberName: member.fullName,
        membershipNumber: member.membershipNumber,
      );
    }
    return c;
  }).toList();
});

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
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final recordMilkCollectionControllerProvider = StateNotifierProvider.autoDispose<
    RecordMilkCollectionController, AsyncValue<MilkCollectionModel?>>((ref) {
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
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final updateMilkCollectionControllerProvider = StateNotifierProvider.autoDispose<
    UpdateMilkCollectionController, AsyncValue<MilkCollectionModel?>>((ref) {
  final repository = ref.watch(milkCollectionRepositoryProvider);
  return UpdateMilkCollectionController(repository, ref);
});
