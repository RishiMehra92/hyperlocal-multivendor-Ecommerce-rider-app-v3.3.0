import 'package:hyper_local/config/api_routes.dart';
import '../../../config/api_base_helper.dart';

class OrderDetailsRepo {
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: '${ApiRoutes.orderDetailsApi}/$orderId',
        useAuthToken: true,
        params: {},
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while fetching order details');
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(int orderId) async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: '${ApiRoutes.orderDetailsApi}/$orderId/payment-status',
        useAuthToken: true,
        params: {},
      );
      return response;
    } catch (error) {
      throw Exception('Error occurred while checking payment status');
    }
  }

  Future<Map<String, dynamic>> cancelPaymentLink(int orderId) async {
    try {
      final response = await ApiBaseHelper.post(
        url: '${ApiRoutes.orderDetailsApi}/$orderId/payment-link/cancel',
        body: {},
        useAuthToken: true,
      );
      return response;
    } catch (error) {
      throw Exception('Error occurred while cancelling payment link');
    }
  }
}
