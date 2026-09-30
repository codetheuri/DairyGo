import '../datasources/member_remote_data_source.dart';
import '../models/member_model.dart';
import '../../../../core/pagination/page_result.dart';
import '../../domain/repositories/member_repository.dart';

class MemberRepositoryImpl implements MemberRepository {
  final MemberRemoteDataSource _remoteDataSource;

  MemberRepositoryImpl(this._remoteDataSource);

  @override
  Future<PageResult<MemberModel>> listMembers({
    String? search,
    int page = 1,
    int perPage = 50,
    String? status,
  }) {
    return _remoteDataSource.listMembers(
      search: search,
      page: page,
      perPage: perPage,
      status: status,
    );
  }

  @override
  Future<MemberModel> getMemberById(String id) {
    return _remoteDataSource.getMemberById(id);
  }

  @override
  Future<MemberModel> createMember(CreateMemberRequestModel request) {
    return _remoteDataSource.createMember(request);
  }

  @override
  Future<MemberModel> updateNextOfKin(
    String id, {
    required String name,
    required String relationship,
    required String phone,
  }) => _remoteDataSource.updateNextOfKin(
    id,
    name: name,
    relationship: relationship,
    phone: phone,
  );
}
