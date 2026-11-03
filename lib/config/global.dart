import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constant.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

class Global {
  static const String _boxName = 'UserDataBox';
  static const String _tokenKey = 'userToken';
  static const String _idTokenKey = 'firebaseIdToken';
  static const String _statusBoxName = 'DeliveryBoyStatusBox';
  static const String _statusKey = 'isOnline';
  static const String _locationAgreeKey = 'location_agree';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _loggedinOnceKey = 'isLoggedinonce';

  static const String _languageNameBox = "_languageBoxLanguageDataBox";
  static const String _languageKey = 'selected_language';

  static const String _destinationName = "DestinationStatusBox";

  static const String _themeBoxName = "theme_box";
  static const String _themeKey = 'selected_theme';

  static const String _settingsBoxName = 'SettingsBox';
  static const String _customSmsKey = 'customSms';
  static const String _httpInspectorKey = 'httpInspectorEnabled';

  /// Controls the secret HTTP Inspector overlay visibility
  static final ValueNotifier<bool> httpInspectorEnabledNotifier =
      ValueNotifier<bool>(false);

  /// Toggle or set HTTP inspector overlay state
  static Future<bool> toggleHttpInspector([bool? enable]) async {
    final newValue = enable ?? !httpInspectorEnabledNotifier.value;
    httpInspectorEnabledNotifier.value = newValue;
    try {
      final box = await _settingsBox;
      await box.put(_httpInspectorKey, newValue);
    } catch (e) {
      debugPrint('❌ Failed to save httpInspector setting: $e');
    }
    return newValue;
  }

  static Future<Box> get _userBox async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  static Future<Box> get _statusBox async {
    if (Hive.isBoxOpen(_statusBoxName)) {
      return Hive.box(_statusBoxName);
    }
    return await Hive.openBox(_statusBoxName);
  }

  static Future<Box> get _destinationBox async {
    if (Hive.isBoxOpen(_destinationName)) {
      return Hive.box(_destinationName);
    }
    return await Hive.openBox(_destinationName);
  }

  static Future<Box> get _languageBox async {
    if (Hive.isBoxOpen(_languageNameBox)) {
      return Hive.box(_languageNameBox);
    }

    return await Hive.openBox(_languageNameBox);
  }

  static Future<Box> get _themeBox async {
    if (Hive.isBoxOpen(_themeBoxName)) {
      return Hive.box(_themeBoxName);
    }

    return await Hive.openBox(_themeBoxName);
  }

  static Future<Box> get _settingsBox async {
    if (Hive.isBoxOpen(_settingsBoxName)) {
      return Hive.box(_settingsBoxName);
    }
    return await Hive.openBox(_settingsBoxName);
  }

  static Future<void> setUserToken(String token) async {
    final box = await _userBox;
    await box.put(_tokenKey, token);
    _cachedToken = token;
  }

  static Future<void> refreshCachedToken() async {
    final box = await _userBox;
    final tokenFromStorage = box.get(_tokenKey);

    _cachedToken = tokenFromStorage;

    // if (_cachedToken == null) {
    //   final allKeys = box.keys.toList();
    // }
  }

  static Future<String?> getUserToken() async {
    final box = await _userBox;
    final token = box.get(_tokenKey);

    return token;
  }

  static String? _cachedToken;

  static Future<void> initializeToken() async {
    final box = await _userBox;
    final tokenFromBox = box.get(_tokenKey);

    _cachedToken = tokenFromBox;
  }

  static String? get userToken {
    return _cachedToken;
  }

  static bool? _cachedCustomSms;

  static Future<void> saveSettings({required bool customSms}) async {
    final box = await _settingsBox;
    await box.put(_customSmsKey, customSms);

    _cachedCustomSms = customSms;
  }

  static Future<void> initializeSettings() async {
    final box = await _settingsBox;
    _cachedCustomSms = box.get(_customSmsKey) as bool?;
    final bool isInspectorEnabled =
        box.get(_httpInspectorKey, defaultValue: false) as bool? ?? false;
    httpInspectorEnabledNotifier.value = isInspectorEnabled;
  }

  static bool get isCustomSmsEnabled => _cachedCustomSms ?? false;

  static Future<void> clearUserToken() async {
    final box = await _userBox;
    await box.delete(_tokenKey);
    _cachedToken = null;
  }
  //////Location Agree Status

  static bool? _cachedLocationAgree;

  static Future<void> initializeLocationRequest() async {
    final box = await _userBox;
    _cachedLocationAgree = box.get(_locationAgreeKey) ?? false;
  }

  static Future<void> setLocationAgree(bool value) async {
    final box = await _userBox;
    await box.put(_locationAgreeKey, value);
    _cachedLocationAgree = value;
  }

  static bool get isLocationAccepted {
    return _cachedLocationAgree ?? false;
  }

  // Onboarding Status
  static bool? _cachedOnboardingComplete;

  static Future<void> initializeOnboardingComplete() async {
    final box = await _userBox;
    _cachedOnboardingComplete = box.get(_onboardingCompleteKey) ?? false;
  }

  static Future<void> setOnboardingComplete(bool value) async {
    final box = await _userBox;
    await box.put(_onboardingCompleteKey, value);
    _cachedOnboardingComplete = value;
  }

  static bool get isOnboardingComplete {
    return _cachedOnboardingComplete ?? false;
  }

  static const String _onboardingConfigKey = 'onboarding_config_cache';

  static Map<String, dynamic>? get cachedOnboardingConfig {
    if (Hive.isBoxOpen(_boxName)) {
      final data = Hive.box(_boxName).get(_onboardingConfigKey);
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    }
    return null;
  }

  static Future<void> saveCachedOnboardingConfig(
      Map<String, dynamic>? json) async {
    final box = await _userBox;
    if (json == null) {
      await box.delete(_onboardingConfigKey);
    } else {
      await box.put(_onboardingConfigKey, json);
    }
  }

  // First-time login status
  static bool? _cachedLoggedinOnce;

  static Future<void> initializeLoggedinOnce() async {
    final box = await _userBox;
    _cachedLoggedinOnce = box.get(_loggedinOnceKey) ?? false;
  }

  static Future<void> setLoggedinOnce(bool value) async {
    final box = await _userBox;
    await box.put(_loggedinOnceKey, value);
    _cachedLoggedinOnce = value;
  }

  static bool get isLoggedinOnce {
    return _cachedLoggedinOnce ?? false;
  }

  // Firebase ID Token management
  static String? _cachedIdToken;

  static Future<void> setIdToken(String idToken) async {
    final box = await _userBox;
    await box.put(_idTokenKey, idToken);
    _cachedIdToken = idToken;
    debugPrint('🔐 FIREBASE ID TOKEN SAVED TO HIVE');
  }

  static Future<String?> getIdToken() async {
    if (_cachedIdToken != null) {
      return _cachedIdToken;
    }

    final box = await _userBox;
    final idToken = box.get(_idTokenKey);
    _cachedIdToken = idToken;

    return idToken;
  }

  static Future<void> initializeIdToken() async {
    final box = await _userBox;
    _cachedIdToken = box.get(_idTokenKey);
  }

  static String? get idToken => _cachedIdToken;

  static Future<void> clearIdToken() async {
    final box = await _userBox;
    await box.delete(_idTokenKey);
    _cachedIdToken = null;
  }

  static const String _fcmTokenKey = 'fcmTokenValue';
  static String? _cachedFcmToken;

  static Future<void> setFCMToken(String token) async {
    final box = await _userBox;
    await box.put(_fcmTokenKey, token);
    _cachedFcmToken = token;
    debugPrint('🔔 FCM TOKEN SAVED TO HIVE: $token');
  }

  static Future<String?> getFCMToken() async {
    if (_cachedFcmToken != null) {
      return _cachedFcmToken;
    }

    final box = await _userBox;
    final token = box.get(_fcmTokenKey);
    _cachedFcmToken = token;

    if (token != null) {
      log('TOKEN :::: $token');
    } else {}

    return token;
  }

  static Future<void> printFCMToken() async {
    final token = await getFCMToken();
    if (token != null) {
      log('TOKEN :::::::::: $token');
    } else {}
  }

  static Future<void> setDeliveryBoyStatus(bool isOnline) async {
    final box = await _statusBox;
    await box.put(_statusKey, isOnline);
  }

  static Future<bool?> getDeliveryBoyStatus() async {
    final box = await _statusBox;
    return box.get(_statusKey) ?? false;
  }

  static bool? _cachedStatus;

  static Future<void> initializeStatus() async {
    final box = await _statusBox;
    _cachedStatus = box.get(_statusKey) ?? false;
  }

  static bool? get deliveryBoyStatus => _cachedStatus;

  static Future<void> debugTokenState() async {
    // final userBox = await _userBox;
    // final tokenFromBox = userBox.get(_tokenKey);
  }

  static Future<void> clearDeliveryBoyStatus() async {
    final box = await _statusBox;
    await box.delete(_statusKey);
    _cachedStatus = null;
  }

  //////////////////////////////

  static Future<void> setReachedDestinationStatus(
    String key,
    bool status,
  ) async {
    final box = await _destinationBox;
    await box.put(key, status);
  }

  static Future<bool?> getReachedDestinationStatus(String key) async {
    final box = await _destinationBox;
    return box.get(key) ?? false;
  }
  //////////////////////////////////

  static String? _cachedLanguage;

  static Future<void> initializeLanguage() async {
    try {
      final box = await _languageBox;
      _cachedLanguage = (box.get(_languageKey) as String?) ?? 'en';
    } catch (_) {
      _cachedLanguage = 'en';
    }
  }

  static String get currentLanguage => _cachedLanguage ?? 'en';

  static Future<void> setLanguage(String value) async {
    _cachedLanguage = value;
    final box = await _languageBox;
    await box.put(_languageKey, value);
  }

  static Future<String?> getLanguage() async {
    if (_cachedLanguage != null && _cachedLanguage!.isNotEmpty) {
      return _cachedLanguage;
    }
    final box = await _languageBox;
    _cachedLanguage = box.get(_languageKey) as String? ?? 'en';
    return _cachedLanguage;
  }

  static List<Map<String, String>> get supportedLanguages => [
        {'code': 'en', 'name': 'English', 'nativeName': 'English'},
        {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
        {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
        {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिंदी'},
        {'code': 'gu', 'name': 'Gujarati', 'nativeName': 'ગુજરાતી'},
        {'code': 'te', 'name': 'Telugu', 'nativeName': 'తెలుగు'},
      ];

  static Future<String> getTheme() async {
    final box = await _themeBox;
    return box.get(_themeKey, defaultValue: AppConstant.defaultTheme);
  }

  static Future<void> setTheme(String theme) async {
    final box = await _themeBox;
    await box.put(_themeKey, theme);
  }

  // ── Splash Screen Cache ───────────────────────────────────────────────────
  static const String _activeSplashKey = 'cached_active_splash_config_json';
  static const String _stagedSplashKey = 'cached_staged_splash_config_json';

  static Map<String, dynamic>? get cachedActiveSplashConfig {
    if (!Hive.isBoxOpen(_settingsBoxName)) return null;
    final box = Hive.box(_settingsBoxName);
    final val = box.get(_activeSplashKey);
    if (val is String && val.trim().isNotEmpty) {
      try {
        return jsonDecode(val) as Map<String, dynamic>?;
      } catch (e) {
        debugPrint('❌ Failed to decode active splash json: $e');
      }
    }
    return null;
  }

  static Future<void> saveCachedActiveSplashConfig(Map<String, dynamic>? config) async {
    final box = await _settingsBox;
    if (config == null) {
      await box.delete(_activeSplashKey);
    } else {
      await box.put(_activeSplashKey, jsonEncode(config));
    }
  }

  static Map<String, dynamic>? get cachedStagedSplashConfig {
    if (!Hive.isBoxOpen(_settingsBoxName)) return null;
    final box = Hive.box(_settingsBoxName);
    final val = box.get(_stagedSplashKey);
    if (val is String && val.trim().isNotEmpty) {
      try {
        return jsonDecode(val) as Map<String, dynamic>?;
      } catch (e) {
        debugPrint('❌ Failed to decode staged splash json: $e');
      }
    }
    return null;
  }

  static Future<void> saveCachedStagedSplashConfig(Map<String, dynamic>? config) async {
    final box = await _settingsBox;
    if (config == null) {
      await box.delete(_stagedSplashKey);
    } else {
      await box.put(_stagedSplashKey, jsonEncode(config));
    }
  }
}

