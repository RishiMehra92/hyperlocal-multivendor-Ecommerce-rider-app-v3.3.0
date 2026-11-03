import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/l10n/default_en_labels.dart';
import 'package:hyper_local/model/language_model/language_model.dart';
import 'package:hyper_local/model/language_model/language_list_model.dart';

class LanguageRepo {
  static const String _boxName = 'LanguageCacheBox';
  static const String _languagesCacheKey = 'languages_list';
  static const String _labelsCachePrefix = 'labels_';

  /// Synchronous in-memory active labels for immediate access (0ms fallback)
  static Map<String, dynamic> activeLabels = {};
  static String activeLocale = 'en';

  static bool get isBoxOpen => Hive.isBoxOpen(_boxName);
  static Box get _box => Hive.box(_boxName);

  Future<Box> _getBox() async {
    if (isBoxOpen) {
      return _box;
    }
    return await Hive.openBox(_boxName);
  }

  /// Initialize cache box and pre-load active labels into memory synchronously
  static Future<void> initCache() async {
    try {
      if (!isBoxOpen) {
        await Hive.openBox(_boxName);
      }
      loadActiveLabelsSync(Global.currentLanguage);
    } catch (e) {
      debugPrint('Failed to initialize LanguageRepo cache: $e');
    }
  }

  /// Load active labels into in-memory storage synchronously from open Hive box
  static void loadActiveLabelsSync(String locale) {
    activeLocale = locale;
    final cached = getCachedLanguageLabelsSync(locale);
    if (cached != null &&
        cached.data != null &&
        cached.data!.labels != null &&
        cached.data!.labels!.isNotEmpty) {
      activeLabels = Map<String, dynamic>.from(cached.data!.labels!);
    } else {
      activeLabels = Map<String, dynamic>.from(defaultEnglishLabels);
    }
  }

  static LanguageModel? getCachedLanguagesSync() {
    try {
      if (isBoxOpen) {
        final raw = _box.get(_languagesCacheKey);
        if (raw != null) {
          if (raw is String) {
            final decoded = jsonDecode(raw);
            if (decoded is Map) {
              return LanguageModel.fromJson(decoded);
            }
          } else if (raw is Map) {
            return LanguageModel.fromJson(raw);
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading cached languages sync: $e');
    }
    return null;
  }

  Future<LanguageModel?> getCachedLanguages() async {
    final syncModel = getCachedLanguagesSync();
    if (syncModel != null) return syncModel;
    try {
      final box = await _getBox();
      final raw = box.get(_languagesCacheKey);
      if (raw != null) {
        if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return LanguageModel.fromJson(decoded);
          }
        } else if (raw is Map) {
          return LanguageModel.fromJson(raw);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCachedLanguages(Map<String, dynamic> data) async {
    try {
      final box = await _getBox();
      await box.put(_languagesCacheKey, jsonEncode(data));
    } catch (_) {}
  }

  static LanguageLabelsModel? getCachedLanguageLabelsSync(String locale) {
    try {
      if (isBoxOpen) {
        final raw = _box.get('$_labelsCachePrefix$locale');
        if (raw != null) {
          if (raw is String) {
            final decoded = jsonDecode(raw);
            if (decoded is Map) {
              return LanguageLabelsModel.fromJson(decoded);
            }
          } else if (raw is Map) {
            return LanguageLabelsModel.fromJson(raw);
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading cached language labels sync: $e');
    }
    return null;
  }

  Future<LanguageLabelsModel?> getCachedLanguageLabels(String locale) async {
    final syncModel = getCachedLanguageLabelsSync(locale);
    if (syncModel != null) return syncModel;
    try {
      final box = await _getBox();
      final raw = box.get('$_labelsCachePrefix$locale');
      if (raw != null) {
        if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return LanguageLabelsModel.fromJson(decoded);
          }
        } else if (raw is Map) {
          return LanguageLabelsModel.fromJson(raw);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCachedLanguageLabels(
      String locale, Map<String, dynamic> data) async {
    try {
      final box = await _getBox();
      await box.put('$_labelsCachePrefix$locale', jsonEncode(data));
      if (locale == activeLocale || locale == Global.currentLanguage) {
        if (data['data'] != null && data['data']['labels'] is Map) {
          final labelsMap = data['data']['labels'] as Map;
          activeLabels =
              labelsMap.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      }
    } catch (_) {}
  }

  Future<LanguageModel> fetchLanguages() async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: ApiRoutes.fetchLanguages,
        useAuthToken: false,
        params: {'surface': 'rider_app'},
      );

      if (response['data'] != null) {
        unawaited(saveCachedLanguages(response));
        return LanguageModel.fromJson(response);
      } else {
        return LanguageModel();
      }
    } catch (e) {
      debugPrint('fetchLanguages error: $e');
      return LanguageModel();
    }
  }

  Future<LanguageLabelsModel> fetchLanguageLabels(String locale) async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: ApiRoutes.languageLabels,
        useAuthToken: false,
        params: {
          'surface': 'rider_app',
          'locale': locale,
        },
      );

      if (response['data'] != null) {
        unawaited(saveCachedLanguageLabels(locale, response));
        return LanguageLabelsModel.fromJson(response);
      } else {
        return LanguageLabelsModel(success: false);
      }
    } catch (e) {
      debugPrint('fetchLanguageLabels error: $e');
      return LanguageLabelsModel(success: false);
    }
  }
}
