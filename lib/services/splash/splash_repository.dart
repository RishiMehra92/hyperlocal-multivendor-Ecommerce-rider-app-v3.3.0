import 'dart:developer';
import 'package:flutter/foundation.dart';
import '../../config/api_routes.dart';
import '../../config/api_base_helper.dart';
import '../../model/splash_model/splash_config_model.dart';
import 'splash_cache_service.dart';

class SplashRepository {
  final SplashCacheService _cacheService;

  SplashRepository({SplashCacheService? cacheService})
      : _cacheService = cacheService ?? SplashCacheService();

  SplashCacheService get cacheService => _cacheService;

  /// Fetch remote splash config from API and sync with local cache
  Future<SplashConfigData?> fetchAndSync() async {
    try {
      debugPrint('[Splash API] 🌐 Fetching splash config from: ${ApiRoutes.splashConfigApi}?app=rider');
      final response = await ApiBaseHelper.getApi(
        url: ApiRoutes.splashConfigApi,
        useAuthToken: false,
        params: {'app': 'rider'},
      );

      debugPrint('[Splash API] 📥 Response data: $response');
      if (response.isNotEmpty) {
        final splashResponse = SplashConfigResponse.fromJson(response);
        if (splashResponse.success && splashResponse.data != null) {
          final current = splashResponse.data!.current;
          final staged = splashResponse.data!.stagedNext;
          debugPrint('[Splash API] ✅ Splash config received successfully (Rider):');
          if (current != null) {
            debugPrint('[Splash API]    👉 Current: id=${current.id}, key=${current.cacheKey}');
            debugPrint('[Splash API]       Background: type=${current.background.type}, image=${current.background.imageUrl}, color=${current.background.color}');
            debugPrint('[Splash API]       Overlay   : enabled=${current.overlay.enabled}, type=${current.overlay.type}, url=${current.overlay.url}');
          } else {
            debugPrint('[Splash API]    👉 Current: null');
          }
          if (staged != null) {
            debugPrint('[Splash API]    👉 Staged : id=${staged.id}, key=${staged.cacheKey}');
          } else {
            debugPrint('[Splash API]    👉 Staged : null');
          }
          await _cacheService.syncSplashData(splashResponse.data!);
          return splashResponse.data;
        } else {
          debugPrint('[Splash API] ⚠️ Server returned success=false: ${response['message']}');
        }
      }
      return null;
    } catch (e, st) {
      debugPrint('❌ [Splash API] Request failed: $e');
      log('[Splash API] StackTrace: $st');
      return null;
    }
  }
}
