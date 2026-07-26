import '../../data/models/member_model.dart';

abstract class MemberRepository {
  Future<List<MemberModel>> listMembers({
    String? search,
    int page = 1,
    int perPage = 50,
    String? status,
  });
  Future<MemberModel> getMemberById(String id);
  Future<MemberModel> createMember(CreateMemberRequestModel request);
}
