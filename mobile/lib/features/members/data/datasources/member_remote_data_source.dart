import 'package:dio/dio.dart';
import '../../../../core/models/audit_log_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/pagination/page_result.dart';
import '../models/member_model.dart';

abstract class MemberRemoteDataSource {
  Future<PageResult<MemberModel>> listMembers({
    String? search,
    int page = 1,
    int perPage = 50,
    String? status,
    bool canSupply = false,
  });
  Future<MemberModel> getMemberById(String id);
  Future<MemberModel> createMember(CreateMemberRequestModel request);
  Future<MemberModel> updateMember(String id, Map<String, dynamic> changes);
  Future<List<AuditLogModel>> history(String id);
  Future<MemberModel> setStatus(String id, String status, {String? reason});
}

class MemberRemoteDataSourceImpl implements MemberRemoteDataSource {
  final Dio _dio;

  MemberRemoteDataSourceImpl(this._dio);

  @override
  Future<PageResult<MemberModel>> listMembers({
    String? search,
    int page = 1,
    int perPage = 50,
    String? status,
    bool canSupply = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }
      if (canSupply) queryParams['can_supply'] = true;

      final response = await _dio.get(
        ApiConstants.members,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return PageResult.fromData(
          data['data'] as Map<String, dynamic>,
          'members',
          MemberModel.fromJson,
        );
      }
      throw Exception(data['message'] ?? 'Failed to load farmers directory');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? e.response?.data['message']
          : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Error loading farmers directory',
      );
    }
  }

  @override
  Future<MemberModel> getMemberById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.members}/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return MemberModel.fromJson(
          data['data']['member'] as Map<String, dynamic>,
        );
      }
      throw Exception(data['message'] ?? 'Failed to load farmer details');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? e.response?.data['message']
          : null;
      throw Exception(serverMsg ?? e.message ?? 'Error loading farmer details');
    }
  }

  @override
  Future<MemberModel> createMember(CreateMemberRequestModel request) async {
    try {
      final response = await _dio.post(
        ApiConstants.members,
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return MemberModel.fromJson(
          data['data']['member'] as Map<String, dynamic>,
        );
      }
      throw Exception(data['message'] ?? 'Failed to register farmer member');
    } on DioException catch (e) {
      throw Exception(
        _serverMessage(e) ?? e.message ?? 'Error registering farmer member',
      );
    }
  }

  @override
  Future<MemberModel> updateMember(
    String id,
    Map<String, dynamic> changes,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.members}/$id',
        data: changes,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return MemberModel.fromJson(
          data['data']['member'] as Map<String, dynamic>,
        );
      }
      throw Exception(data['message'] ?? 'Could not save the changes');
    } on DioException catch (e) {
      throw Exception(
        _serverMessage(e) ?? e.message ?? 'Could not save the changes',
      );
    }
  }

  @override
  Future<List<AuditLogModel>> history(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.members}/$id/history');
      final list = (response.data['data']?['history'] as List?) ?? const [];
      return list
          .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _serverMessage(e) ?? e.message ?? 'Could not load the history',
      );
    }
  }

  @override
  Future<MemberModel> setStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    try {
      final response = await _dio.patch(
        '${ApiConstants.members}/$id/status',
        data: {
          'status': status,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return MemberModel.fromJson(
          data['data']['member'] as Map<String, dynamic>,
        );
      }
      throw Exception(data['message'] ?? 'Could not change the status');
    } on DioException catch (e) {
      throw Exception(
        _serverMessage(e) ?? e.message ?? 'Could not change the status',
      );
    }
  }

  /// The reason the server gave: the first field error, else its message.
  static String? _serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first?.toString();
      if (first != null && first.isNotEmpty) return first;
    }
    return data['message']?.toString();
  }
}
