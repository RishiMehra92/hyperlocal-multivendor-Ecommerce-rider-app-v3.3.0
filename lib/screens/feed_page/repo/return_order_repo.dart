import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';

class ReturnOrderRepo {
  Future<Map<String, dynamic>> getReturnOrder({int? limit, int? offset}) async {
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
        url: ApiRoutes.getReturnOrdersApi,
        useAuthToken: true,
        params: body,
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while fetching return order details');
    }
  }

  Future<Map<String, dynamic>> acceptReturnOrder(String returnId) async {
    try {
      final response = await ApiBaseHelper.post(
        url: '${ApiRoutes.acceptReturnOrderApi}$returnId/accept',
        useAuthToken: true,
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while accepting return order');
    }
  }

  Future<Map<String, dynamic>> updateReturnOrderStatus(
    String returnId,
    String status, {
    String? otp,
    List<File>? images,
    String? pickupCondition,
    String? pickupRemarks,
  }) async {
    try {
      final Map<String, dynamic> bodyMap = {'status': status};
      if (otp != null && otp.isNotEmpty) {
        bodyMap['otp'] = otp;
      }
      if (pickupCondition != null && pickupCondition.isNotEmpty) {
        bodyMap['pickup_condition'] = pickupCondition;
      }
      if (pickupRemarks != null && pickupRemarks.isNotEmpty) {
        bodyMap['pickup_remarks'] = pickupRemarks;
      }

      dynamic body;

      if ((images != null && images.isNotEmpty) || status == 'picked_up') {
        final formData = FormData.fromMap(bodyMap);

        if (images != null && images.isNotEmpty) {
          for (final file in images) {
            final fileName = file.path.split('/').last;
            formData.files.add(
              MapEntry(
                'images[]',
                await MultipartFile.fromFile(file.path, filename: fileName),
              ),
            );
          }
        }

        body = formData;
      } else {
        body = bodyMap;
      }

      final response = await ApiBaseHelper.put(
        url: '${ApiRoutes.updateReturnOrderApi}$returnId/status',
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while updating return order');
    }
  }

  Future<Map<String, dynamic>> getReturnPickups({
    int? limit,
    int? offset,
    String? status,
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
      if (status != null) {
        body["status"] = status;
      }

      final response = await ApiBaseHelper.getApi(
        url: ApiRoutes.listPickupsApi,
        useAuthToken: true,
        params: body,
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while fetching return pickups');
    }
  }

  Future<Map<String, dynamic>> getReturnPickupsDetails(String returnId) async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: '${ApiRoutes.pickupDetailsApi}$returnId',
        useAuthToken: true,
        params: {},
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while fetching return pickups details');
    }
  }
}
