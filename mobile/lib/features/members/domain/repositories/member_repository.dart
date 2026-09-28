import '../../data/models/member_model.dart';
import '../../../../core/pagination/page_result.dart';

abstract class MemberRepository {
  Future<PageResult<MemberModel>> listMembers({
    String? search,
    int page = 1,
    int perPage = 50,
    String? status,
  });
  Future<MemberModel> getMemberById(String id);
  Future<MemberModel> createMember(CreateMemberRequestModel request);
}
