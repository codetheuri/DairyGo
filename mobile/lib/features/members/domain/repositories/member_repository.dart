import '../../../../core/models/audit_log_model.dart';
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

  /// Changes a farmer's details: only the keys given change, and an
  /// optional detail sent empty is cleared.
  Future<MemberModel> updateMember(String id, Map<String, dynamic> changes);

  /// Who changed the farmer's details and when, oldest first.
  Future<List<AuditLogModel>> history(String id);
}
