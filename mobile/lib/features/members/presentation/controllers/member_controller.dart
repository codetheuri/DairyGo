import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Active farmers matching [search] (name, phone, membership or national ID),
/// searched on the server so every farmer can be found, not just a first page.
/// Separate from [membersListProvider], whose filters belong to the directory.
final farmerPickerResultsProvider = FutureProvider.autoDispose
    .family<List<MemberModel>, String>((ref, search) async {
      final result = await ref
          .watch(memberRepositoryProvider)
          .listMembers(search: search, status: 'ACTIVE', perPage: 30);
      return result.items;
    });

final memberDetailsProvider = FutureProvider.family<MemberModel, String>((
  ref,
  id,
) async {
  final repository = ref.watch(memberRepositoryProvider);
  return repository.getMemberById(id);
});

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
