import 'dart:ui';

class AppConstant {
  static const String appName = 'Nezit Delivery Partner';
  static const String packageName = 'com.nezit.deliverypartner';
  static  const String domainBaseUrl = 'https://api.nezit.in';
  static  const String baseUrl = '$domainBaseUrl';
  static const String deliveryZoneUrl = '$domainBaseUrl/api/';
  static const String defaultTheme = 'light';
  static const String systemVersion = '3.3.0';

   static const String deliveryBoyBaseUrl = '$baseUrl/api/delivery-boy/';
   static const bool isDemoMode = false;
  static const Color myprimaryColor = Color(0xFFFF6A1A);
  static final RegExp _baseUrlRegex = RegExp(r'^https://', caseSensitive: false);
  static bool get hasValidBaseUrl => _baseUrlRegex.hasMatch(baseUrl.trim());
}
