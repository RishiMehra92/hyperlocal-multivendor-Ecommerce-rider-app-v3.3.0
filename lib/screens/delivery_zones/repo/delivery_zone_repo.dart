import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import '../model/delivery_zone_model.dart';

class DeliveryZoneRepository {
  Future<DeliveryZoneListResponse> getDeliveryZones({
    int page = 1,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await ApiBaseHelper.getApi(
        url: ApiRoutes.deliveryZoneApi,
        useAuthToken: true,
        params: queryParams,
      );

      if (kDebugMode) {
        debugPrint('📍 Delivery zones fetched: ${response['data']['total']}');
      }

      return DeliveryZoneListResponse.fromJson(response);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching delivery zones: ${e.message}');
      }
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch zones');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected error: $e');
      }
      throw Exception('An unexpected error occurred');
    }
  }

  Future<DeliveryZoneModel> getDeliveryZoneById(int id) async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: '${ApiRoutes.deliveryZoneApi}/$id',
        useAuthToken: true,
        params: {},
      );

      if (kDebugMode) {
        debugPrint(
          '📍 Delivery zone details fetched: ${response['data']['name']}',
        );
      }

      return DeliveryZoneModel.fromJson(response['data']);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching zone details: ${e.message}');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch zone details',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected error: $e');
      }
      throw Exception('An unexpected error occurred');
    }
  }
}
