import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
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

final memberSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final memberStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final membersListProvider = FutureProvider<List<MemberModel>>((ref) async {
  final repository = ref.watch(memberRepositoryProvider);
  final search = ref.watch(memberSearchQueryProvider);
  final status = ref.watch(memberStatusFilterProvider);

  return repository.listMembers(
    search: search,
    status: status,
    perPage: 100,
  );
});

final memberDetailsProvider = FutureProvider.family<MemberModel, String>((ref, id) async {
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
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final registerMemberControllerProvider =
    StateNotifierProvider.autoDispose<RegisterMemberController, AsyncValue<MemberModel?>>((ref) {
  final repository = ref.watch(memberRepositoryProvider);
  return RegisterMemberController(repository, ref);
});
