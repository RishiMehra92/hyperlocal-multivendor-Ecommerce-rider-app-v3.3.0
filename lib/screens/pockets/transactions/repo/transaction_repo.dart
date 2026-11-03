import '../../../../config/api_routes.dart';
import '../../../../config/api_base_helper.dart';

class TransactionRepo {
  // Get earnings list

  Future<Map<String, dynamic>> fetchWalletTransactions({
    required int perPage,
    required int page,
  }) async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: '${ApiRoutes.getTransactionsApi}?page=$page&per_page=$perPage',
        useAuthToken: true,
        params: {},
      );
      return response;
    } catch (e) {
      throw Exception('Error fetching wallet transactions: $e');
    }
  }

  // Future<RatingsResponse> fetchOverallRatings() async {
  //   try {
  //     final deliveryBoyId = await _getDeliveryBoyId();
  //
  //     final response = await ApiBaseHelper.getApi(
  //       url: ApiRoutes.ratingApi,
  //       useAuthToken: true,
  //       params: {'delivery_boy_id': deliveryBoyId},
  //     );
  //
  //     return RatingsResponse.fromJson(response);
  //   } catch (e) {
  //     throw Exception('Error fetching overall ratings: $e');
  //   }
  // }
}
