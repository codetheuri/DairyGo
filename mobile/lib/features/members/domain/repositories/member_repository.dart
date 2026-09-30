import '../../../../core/models/audit_log_model.dart';
import '../../data/models/member_model.dart';
import '../../../../core/pagination/page_result.dart';

abstract class MemberRepository {
  /// Farmers page by page. [canSupply] leaves out suspended farmers, for
  /// choosing whose milk to record.
  Future<PageResult<MemberModel>> listMembers({
    String? search,
    int page = 1,
    int perPage = 50,
    String? status,
    bool canSupply = false,
  });
  Future<MemberModel> getMemberById(String id);
  Future<MemberModel> createMember(CreateMemberRequestModel request);

  /// Changes a farmer's details: only the keys given change, and an
  /// optional detail sent empty is cleared.
  Future<MemberModel> updateMember(String id, Map<String, dynamic> changes);

  /// Who changed the farmer's details and when, oldest first.
  Future<List<AuditLogModel>> history(String id);

  /// Makes a farmer ACTIVE, INACTIVE or SUSPENDED; a suspension needs a
  /// [reason]. Suspended farmers cannot supply milk; inactive ones can, and
  /// become active when they do.
  Future<MemberModel> setStatus(String id, String status, {String? reason});
}
