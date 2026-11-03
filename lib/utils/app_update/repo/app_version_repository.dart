import 'dart:developer';
import 'dart:io';
import 'package:hyper_local/config/api_routes.dart';
import '../../../config/api_base_helper.dart';
import '../../../config/constant.dart';
import '../model/app_version_model.dart';
import '../model/update_config.dart';

class AppVersionRepository {
  Future<UpdateConfig> fetchUpdateConfig() async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';

      final response = await ApiBaseHelper.getApi(
        url: '${ApiRoutes.versionCheckApi}?platform=$platform',
        useAuthToken: false,
        params: {'current_version': AppConstant.systemVersion, 'app': 'rider'},
      );

      // ApiBaseHelper.getApi returns a Map<String, dynamic>
      // If success is false, we should handle it.
      if (response['success'] == false) {
        log('[AppVersionRepo] API returned success: false — failing open');
        return _upToDate();
      }

      // The response is already the data Map decoded by ApiBaseHelper
      final apiResponse = AppVersionModel.fromJson(response);

      final model = apiResponse.data;
      if (model != null) {
        log(
          '[AppVersionRepo] API Response -> '
          'update_available: ${model.updateAvailable}, '
          'update_type: ${model.updateType}, '
          'min_supported: ${model.minSupportedVersion}, '
          'latest: ${model.latestVersion}, '
          'message: ${model.message}',
        );

        if (model.updateAvailable == true) {
          final isForce =
              model.updateType == 'force' || model.updateType == 'force_update';
          log(
            '[AppVersionRepo] Update type: ${model.updateType}, isForce: $isForce',
          );
          return UpdateConfig(
            status:
                isForce
                    ? UpdateStatus.forceUpdate
                    : UpdateStatus.optionalUpdate,
            title: isForce ? 'Update Required' : 'Update Available',
            message:
                model.message?.isNotEmpty == true
                    ? model.message!
                    : isForce
                    ? 'Please update the app to continue using our services.'
                    : 'A new version is available. Would you like to update?',
            iosStoreUrl: model.updateUrl ?? '',
            androidStoreUrl: model.updateUrl ?? '',
            updateAvailable: true,
            updateType: model.updateType ?? '',
            minSupportedVersion: model.minSupportedVersion ?? '',
            latestVersion: model.latestVersion,
          );
        }
      }

      return _upToDate();
    } catch (e, stack) {
      log(
        '[AppVersionRepo] Error fetching update config: $e',
        error: e,
        stackTrace: stack,
      );
      return _upToDate();
    }
  }

  static UpdateConfig _upToDate() => const UpdateConfig(
    status: UpdateStatus.upToDate,
    title: '',
    message: '',
    iosStoreUrl: '',
    androidStoreUrl: '',
  );
}
