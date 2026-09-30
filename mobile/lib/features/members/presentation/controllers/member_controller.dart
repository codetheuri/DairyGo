import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/audit_log_model.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/pagination/paged_list_notifier.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../data/datasources/member_remote_data_source.dart';
import '../../data/models/member_model.dart';
import '../../data/repositories/member_repository_impl.dart';
import '../../domain/repositories/member_repository.dart';

final memberRemoteDataSourceProvider = Provider<MemberRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return MemberRemoteDataSourceImpl(dio);
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final dataSource = ref.watch(memberRemoteDataSourceProvider);
  return MemberRepositoryImpl(dataSource);
});

final memberSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);
final memberStatusFilterProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// The farmer directory, loaded page by page as the user scrolls.
final membersListProvider =
    AsyncNotifierProvider<MembersListNotifier, PagedList<MemberModel>>(
      MembersListNotifier.new,
    );

class MembersListNotifier extends PagedListNotifier<MemberModel> {
  @override
  Future<PagedList<MemberModel>> build() async {
    final repository = ref.watch(memberRepositoryProvider);
    final search = ref.watch(memberSearchQueryProvider).trim();
    final status = ref.watch(memberStatusFilterProvider);
    await debounce(search);
    return loadFirstPage(
      (page) => repository.listMembers(
        search: search,
        status: status,
        page: page,
        perPage: PagedListNotifier.pageSize,
      ),
    );
  }
}

/// Farmers whose milk may be recorded (active and inactive, not suspended)
/// matching [search] (name, phone, membership or national ID), searched on
/// the server so every farmer can be found, not just a first page. Separate
/// from [membersListProvider], whose filters belong to the directory.
final farmerPickerResultsProvider = FutureProvider.autoDispose
    .family<List<MemberModel>, String>((ref, search) async {
      final result = await ref
          .watch(memberRepositoryProvider)
          .listMembers(search: search, canSupply: true, perPage: 30);
      return result.items;
    });

final memberDetailsProvider = FutureProvider.family<MemberModel, String>((
  ref,
  id,
) async {
  final repository = ref.watch(memberRepositoryProvider);
  return repository.getMemberById(id);
});

/// Who changed a farmer's details and when.
final memberHistoryProvider = FutureProvider.autoDispose
    .family<List<AuditLogModel>, String>(
      (ref, id) => ref.watch(memberRepositoryProvider).history(id),
    );

/// Changes to a farmer's profile. Each method returns null on success or the
/// message to show.
class MemberActions {
  final Ref _ref;

  MemberActions(this._ref);

  /// Saves [changes] to a farmer's details (see
  /// [MemberRepository.updateMember]).
  Future<String?> update(String memberId, Map<String, dynamic> changes) async {
    try {
      await _ref.read(memberRepositoryProvider).updateMember(memberId, changes);
      _refreshFarmer(memberId);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Changes a farmer's status (see [MemberRepository.setStatus]).
  Future<String?> setStatus(
    String memberId,
    String status, {
    String? reason,
  }) async {
    try {
      await _ref
          .read(memberRepositoryProvider)
          .setStatus(memberId, status, reason: reason);
      _refreshFarmer(memberId);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Everything that shows [memberId] is loaded again.
  void _refreshFarmer(String memberId) {
    _ref.invalidate(memberDetailsProvider(memberId));
    _ref.invalidate(memberHistoryProvider(memberId));
    _ref.invalidate(membersListProvider);
    _ref.invalidate(farmerPickerResultsProvider);
  }

  Future<String?> saveNextOfKin(
    String memberId, {
    required String name,
    required String relationship,
    required String phone,
  }) => update(memberId, {
    'next_of_kin_name': name,
    'next_of_kin_relationship': relationship,
    'next_of_kin_phone': phone,
  });
}

final memberActionsProvider = Provider<MemberActions>(MemberActions.new);

class RegisterMemberController extends StateNotifier<AsyncValue<MemberModel?>> {
  final MemberRepository _repository;
  final Ref _ref;

  RegisterMemberController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<bool> registerMember(CreateMemberRequestModel request) async {
    state = const AsyncValue.loading();
    try {
      final member = await _repository.createMember(request);
      state = AsyncValue.data(member);
      invalidateAllAppMetrics(_ref);
      _ref.invalidate(membersListProvider);
      _ref.invalidate(farmerPickerResultsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final registerMemberControllerProvider =
    StateNotifierProvider.autoDispose<
      RegisterMemberController,
      AsyncValue<MemberModel?>
    >((ref) {
      final repository = ref.watch(memberRepositoryProvider);
      return RegisterMemberController(repository, ref);
    });
