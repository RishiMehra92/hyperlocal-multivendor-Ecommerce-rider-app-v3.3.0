import 'package:hyper_local/config/api_routes.dart';
import '../../../config/api_base_helper.dart';

class ItemsCollectedRepo {
  Future<Map<String, dynamic>> itemsCollected(String orderItemId) async {
    try {
      final response = await ApiBaseHelper.put(
        url: '${ApiRoutes.itemsCollectedApi}/$orderItemId/status',
        body: {'status': 'collected'},
      );

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> itemsDelivered(
    String orderItemId,
    String? otp,
  ) async {
    try {
      // Initialize the body with the status
      final Map<String, dynamic> body = {'status': 'delivered'};

      // Add otp to the body only if it is not null or empty
      if (otp != null && otp.isNotEmpty) {
        body['otp'] = otp;
      }

      final response = await ApiBaseHelper.put(
        url: '${ApiRoutes.itemsCollectedApi}/$orderItemId/status',
        body: body,
      );

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> collectAll({
    required int orderId,
    required int storeId,
  }) async {
    try {
      final response = await ApiBaseHelper.put(
        url: ApiRoutes.collectAllApi(orderId),
        body: {'store_id': storeId},
      );
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deliverAll({
    required int orderId,
    String? otp,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (otp != null && otp.isNotEmpty) {
        body['otp'] = otp;
      }
      final response = await ApiBaseHelper.put(
        url: ApiRoutes.deliverAllApi(orderId),
        body: body,
      );
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
