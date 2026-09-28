import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/pagination/page_result.dart';
import '../models/member_model.dart';

abstract class MemberRemoteDataSource {
  Future<PageResult<MemberModel>> listMembers({
    String? search,
    int page = 1,
    int perPage = 50,
    String? status,
  });
  Future<MemberModel> getMemberById(String id);
  Future<MemberModel> createMember(CreateMemberRequestModel request);
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
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }

      final response = await _dio.get(
        ApiConstants.members,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return PageResult.fromData(data['data'] as Map<String, dynamic>, 'members', MemberModel.fromJson);
      }
      throw Exception(data['message'] ?? 'Failed to load farmers directory');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error loading farmers directory');
    }
  }

  @override
  Future<MemberModel> getMemberById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.members}/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return MemberModel.fromJson(data['data']['member'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to load farmer details');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
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
        return MemberModel.fromJson(data['data']['member'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to register farmer member');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['errors']?['phone'])
          : null;
      throw Exception(serverMsg ?? e.message ?? 'Error registering farmer member');
    }
  }
}
