import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';

import '../model/refer_and_earn_model.dart';

class ReferAndEarnRepository {
  Future<ReferAndEarnModel> fetchReferAndEarn() async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: ApiRoutes.getReferInfoApi,
        useAuthToken: true,
        params: {},
      );

      if (response['success'] == true && response['data'] != null) {
        return ReferAndEarnModel.fromJson(response);
      } else {
        throw Exception(response['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
