import 'package:hyper_local/config/constant.dart';

class ApiRoutes {
  static const String loginApi = '${AppConstant.deliveryBoyBaseUrl}login';
  static const String registerApi = '${AppConstant.deliveryBoyBaseUrl}register';
  static const String verifyEmailOrMobileApi =
      "${AppConstant.deliveryZoneUrl}verify-user";
  static const String deliveryZoneApi =
      '${AppConstant.deliveryZoneUrl}delivery-zone';
  static const String splashConfigApi = '${AppConstant.deliveryZoneUrl}splash-config';
  static const String onboardingScreensApi =
      '${AppConstant.deliveryZoneUrl}onboarding-screens';
  static const String deliveryBoyStatusApi =
      '${AppConstant.deliveryBoyBaseUrl}status/update';
  static const String deliveryBoyProfileApi =
      '${AppConstant.deliveryBoyBaseUrl}profile';
  static const String availableOrdersStatusApi =
      '${AppConstant.deliveryBoyBaseUrl}orders/available';
  static const String myOrdersApi =
      '${AppConstant.deliveryBoyBaseUrl}orders/my';
  static const String acceptOrderApi =
      '${AppConstant.deliveryBoyBaseUrl}orders';
  static const String updateCurrentLocationApi =
      '${AppConstant.deliveryBoyBaseUrl}update-current-location';
  static const String itemsCollectedApi =
      '${AppConstant.deliveryBoyBaseUrl}order-items';
  static const String orderDetailsApi =
      '${AppConstant.deliveryBoyBaseUrl}orders';
  static const String orderDropApi = '${AppConstant.deliveryBoyBaseUrl}orders';
  static const String deliveryFailedApi =
      '${AppConstant.deliveryBoyBaseUrl}order-items';
  static const String getReturnOrdersApi =
      '${AppConstant.deliveryBoyBaseUrl}return-pickups/available';
  static const String acceptReturnOrderApi =
      '${AppConstant.deliveryBoyBaseUrl}return-pickups/';
  static const String updateReturnOrderApi =
      '${AppConstant.deliveryBoyBaseUrl}return-pickups/';
  static const String listPickupsApi =
      '${AppConstant.deliveryBoyBaseUrl}return-pickups/my';
  static const String pickupDetailsApi =
      '${AppConstant.deliveryBoyBaseUrl}return-pickups/';

  static const String createWithdrawalsReqApi =
      '${AppConstant.deliveryBoyBaseUrl}withdrawals';
  static const String getWithdrawalsApi =
      '${AppConstant.deliveryBoyBaseUrl}withdrawals';
  static const String getWithdrawalByIdApi =
      '${AppConstant.deliveryBoyBaseUrl}withdrawals';
  static const String getSystemSettingApi =
      '${AppConstant.deliveryZoneUrl}settings';
  static const String getDeliveryBoySettingsApi =
      '${AppConstant.deliveryZoneUrl}settings';

  static const String getEarningsApi =
      '${AppConstant.deliveryBoyBaseUrl}earnings';
  static const String getEarningsStatsApi =
      '${AppConstant.deliveryBoyBaseUrl}earnings/statistics';
  static const String getEarningsDateRangeApi =
      '${AppConstant.deliveryBoyBaseUrl}earnings';
  static const String getTransactionsApi =
      "${AppConstant.deliveryBoyBaseUrl}wallet/transactions";

  static const String getCashCollectionApi =
      '${AppConstant.deliveryBoyBaseUrl}cash-collections';
  static const String getCashCollectionStatisticsApi =
      '${AppConstant.deliveryBoyBaseUrl}cash-collection/statistics';

  static const String getHomeStatsApi = '${AppConstant.deliveryBoyBaseUrl}home';
  static const String ratingApi =
      '${AppConstant.deliveryBoyBaseUrl}feedback/ratings';
  static const String feedbackApi = '${AppConstant.deliveryBoyBaseUrl}feedback';
  static const String notificationsApi =
      '${AppConstant.deliveryBoyBaseUrl}notifications';
  static const String customSendOtpApi =
      '${AppConstant.deliveryBoyBaseUrl}auth/send-otp';
  static const String customVerifyOtpApi =
      '${AppConstant.deliveryBoyBaseUrl}auth/verify-otp';
  static const String getReferInfoApi =
      '${AppConstant.deliveryBoyBaseUrl}referral';
  static const String deleteAccountApi =
      "${AppConstant.deliveryBoyBaseUrl}delete-account";
  static const String versionCheckApi =
      '${AppConstant.deliveryZoneUrl}settings/check-version';
  static const String forgetPasswordApi =
      '${AppConstant.deliveryZoneUrl}forget-password';
  static const String phoneCallbackApi =
      '${AppConstant.deliveryZoneUrl}auth/phone/callback';

  static String collectAllApi(dynamic orderId) =>
      '${AppConstant.deliveryBoyBaseUrl}orders/$orderId/collect-all';
  static String deliverAllApi(dynamic orderId) =>
      '${AppConstant.deliveryBoyBaseUrl}orders/$orderId/deliver-all';
  static const String settleOnlineApi =
      '${AppConstant.deliveryBoyBaseUrl}cash-collections/settle-online';

  static const String fetchLanguages = '${AppConstant.deliveryZoneUrl}languages';
  static const String languageLabels = '${AppConstant.deliveryZoneUrl}language-labels';
}
