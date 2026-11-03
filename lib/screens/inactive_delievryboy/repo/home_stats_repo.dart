import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import '../model/home_stats_model.dart';

class HomeStatsRepo {
  Future<HomeStatsResponse> getHomeStats() async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: ApiRoutes.getHomeStatsApi,
        useAuthToken: true,
        params: {},
      );

      return HomeStatsResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch home stats: $e');
    }
  }
}
