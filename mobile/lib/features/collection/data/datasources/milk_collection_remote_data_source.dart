import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/milk_collection_model.dart';

abstract class MilkCollectionRemoteDataSource {
  Future<MilkPriceModel> getActivePrice();
  Future<List<MilkCollectionModel>> listCollections({
    String? memberId,
    String? fromDate,
    String? toDate,
    String? shift,
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  });
  Future<MilkCollectionModel> recordCollection(RecordCollectionRequestModel request);
  Future<MilkCollectionModel> updateCollection(String id, UpdateCollectionRequestModel request);
}

class MilkCollectionRemoteDataSourceImpl implements MilkCollectionRemoteDataSource {
  final Dio _dio;

  MilkCollectionRemoteDataSourceImpl(this._dio);

  @override
  Future<MilkPriceModel> getActivePrice() async {
    try {
      final response = await _dio.get(ApiConstants.activePrice);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final priceMap = data['data']['price'];
        if (priceMap != null) {
          return MilkPriceModel.fromJson(priceMap as Map<String, dynamic>);
        }
      }
      // Fallback default if no active price set
      return const MilkPriceModel(id: 'default', pricePerLitre: 50.0);
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error fetching active milk price');
    }
  }

  @override
  Future<List<MilkCollectionModel>> listCollections({
    String? memberId,
    String? fromDate,
    String? toDate,
    String? shift,
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (memberId != null && memberId.isNotEmpty) queryParams['member_id'] = memberId;
      if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;
      if (shift != null && shift.isNotEmpty) queryParams['shift'] = shift;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        ApiConstants.collections,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final list = (data['data']['collections'] as List? ?? [])
            .map((e) => MilkCollectionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception(data['message'] ?? 'Failed to load milk collections');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error loading milk collections');
    }
  }

  @override
  Future<MilkCollectionModel> recordCollection(RecordCollectionRequestModel request) async {
    try {
      final response = await _dio.post(
        ApiConstants.collections,
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return MilkCollectionModel.fromJson(data['data']['collection'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to record milk intake');
    } on DioException catch (e) {
      String? serverMsg;
      if (e.response?.data is Map) {
        final resData = e.response!.data as Map;
        final msg = resData['message']?.toString();
        final detail = resData['detail']?.toString();

        if (msg != null &&
            msg.isNotEmpty &&
            !msg.toLowerCase().startsWith('validation failed')) {
          serverMsg = msg;
        } else if (detail != null && detail.isNotEmpty) {
          serverMsg = detail;
        } else if (resData['errors'] != null) {
          final errs = resData['errors'];
          if (errs is Map && errs.isNotEmpty) {
            final firstVal = errs.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              serverMsg = firstVal.first.toString();
            } else {
              serverMsg = firstVal.toString();
            }
          } else if (errs is List && errs.isNotEmpty) {
            serverMsg = errs.first.toString();
          }
        }
        serverMsg ??= msg;
      }
      throw Exception(serverMsg ?? e.message ?? 'Error recording milk intake');
    }
  }

  @override
  Future<MilkCollectionModel> updateCollection(
    String id,
    UpdateCollectionRequestModel request,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.collections}/$id',
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return MilkCollectionModel.fromJson(data['data']['collection'] as Map<String, dynamic>);
      }
      throw Exception(data['message'] ?? 'Failed to update milk intake');
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(serverMsg ?? e.message ?? 'Error updating milk intake');
    }
  }
}
