import 'package:hyper_local/config/api_routes.dart';

import '../../../config/api_base_helper.dart';

class AcceptOrderRepo {
  Future<Map<String, dynamic>> updateAcceptOrder({required int orderId}) async {
    try {
      Map<String, dynamic> body = {};

      final response = await ApiBaseHelper.post(
        url: "${ApiRoutes.acceptOrderApi}/$orderId/accept",
        useAuthToken: true,
        body: body,
      );
      return response;
    } catch (error) {
      rethrow;
    }
  }
}
