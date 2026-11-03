import 'package:hyper_local/config/api_routes.dart';
import '../../../config/api_base_helper.dart';

class OrderActionsRepo {
  Future<Map<String, dynamic>> cancelOrder({
    required int orderId,
    required String note,
  }) async {
    try {
      return await ApiBaseHelper.post(
        url: '${ApiRoutes.orderDropApi}/$orderId/drop',
        body: {'note': note},
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> markDeliveryFailed({
    required int orderItemId,
    required String reasonCode,
    String? note,
  }) async {
    try {
      final Map<String, dynamic> body = {'reason_code': reasonCode};
      if (note != null && note.trim().isNotEmpty) {
        body['note'] = note.trim();
      }
      return await ApiBaseHelper.post(
        url: '${ApiRoutes.deliveryFailedApi}/$orderItemId/delivery-failed',
        body: body,
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
