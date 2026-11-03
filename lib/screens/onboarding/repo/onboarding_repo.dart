import 'dart:developer';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/app_images.dart';
import 'package:hyper_local/config/global.dart';
import '../model/onboarding_model.dart';

class OnboardingRepository {
  /// Fetch dynamic onboarding config from API
  Future<OnboardingConfig> fetchFromApi() async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: ApiRoutes.onboardingScreensApi,
        useAuthToken: false,
        params: {'app': 'rider'},
      );

      final onboardingResponse = OnboardingResponse.fromJson(response);
      if (onboardingResponse.data != null) {
        await syncCache(onboardingResponse.data!);
        return onboardingResponse.data!;
      }

      throw Exception('Onboarding config payload was null');
    } catch (e) {
      log('[OnboardingRepo] Failed to fetch onboarding: $e');
      rethrow;
    }
  }

  /// Read cached onboarding config from local storage (Hive)
  OnboardingConfig? getCachedConfig() {
    try {
      final cachedJson = Global.cachedOnboardingConfig;
      if (cachedJson != null) {
        return OnboardingConfig.fromJson(cachedJson);
      }
    } catch (e) {
      log('[OnboardingRepo] Error reading cached onboarding: $e');
    }
    return null;
  }

  /// Sync newly received config to local storage and evict obsolete media
  Future<void> syncCache(OnboardingConfig newConfig) async {
    try {
      final previousConfig = getCachedConfig();
      if (previousConfig != null) {
        final newUrls = newConfig.screens
            .where((s) => s.isNetworkMedia)
            .map((s) => s.media)
            .toSet();

        for (final oldScreen in previousConfig.screens) {
          if (oldScreen.isNetworkMedia && !newUrls.contains(oldScreen.media)) {
            try {
              await DefaultCacheManager().removeFile(oldScreen.media);
              log('[OnboardingRepo] Evicted removed media from cache: ${oldScreen.media}');
            } catch (e) {
              log('[OnboardingRepo] Could not remove old cache entry: $e');
            }
          }
        }
      }

      await Global.saveCachedOnboardingConfig(newConfig.toJson());
    } catch (e) {
      log('[OnboardingRepo] Error saving cache: $e');
    }
  }

  /// Default fallback screens when offline, API fails, or screens is empty
  static List<OnboardingScreenItem> getDefaultScreens() {
    return [
      OnboardingScreenItem(
        id: -1,
        title: 'Accept & Manage Deliveries',
        subtitle:
            'Get delivery orders in real time and fulfill them seamlessly.',
        media: AppImages.onboard1,
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
      OnboardingScreenItem(
        id: -2,
        title: 'Track Your Earnings',
        subtitle:
            'Keep real-time track of your daily earnings and bonuses.',
        media: AppImages.onboard2,
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
      OnboardingScreenItem(
        id: -3,
        title: 'Navigate Easily',
        subtitle:
            'Reach customer and store locations faster with turn-by-turn routes.',
        media: AppImages.onboard3,
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
    ];
  }
}
