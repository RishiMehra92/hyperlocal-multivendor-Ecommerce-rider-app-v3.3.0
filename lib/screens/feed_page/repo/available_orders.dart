import 'package:hyper_local/config/api_routes.dart';

import '../../../config/api_base_helper.dart';

class AvailableOrdersRepo {
  Future<Map<String, dynamic>> availableOrdersList({
    int? limit,
    int? offset,
    String? search = "",
  }) async {
    try {
      Map<String, dynamic> body = {};
      if (limit != null) {
        body["per_page"] = limit;
      }
      if (offset != null) {
        // Convert offset to page number (offset 0 = page 1, offset 10 = page 2, etc.)
        int page = (offset ~/ (limit ?? 10)) + 1;
        body["page"] = page;
      }

      final response = await ApiBaseHelper.getApi(
        url: ApiRoutes.availableOrdersStatusApi,
        useAuthToken: true,
        params: body,
      );
      return response;
    } catch (error) {
      throw Exception('Error occurred');
    }
  }
}
