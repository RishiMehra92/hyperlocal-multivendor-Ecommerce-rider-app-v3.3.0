class LanguageModel {
  bool? success;
  String? message;
  Languages? data;

  LanguageModel({
    this.success,
    this.message,
    this.data,
  });

  LanguageModel.fromJson(Map<dynamic, dynamic> json) {
    success = json['success'] as bool? ?? (json['success']?.toString() == 'true');
    message = json['message']?.toString() ?? '';
    if (json['data'] is Map) {
      data = Languages.fromJson(json['data'] as Map);
    } else {
      data = Languages.fromJson({});
    }
  }
}

class Languages {
  String? defaultLanguage;
  List<LanguageData>? languages;

  Languages({
    this.defaultLanguage,
    this.languages,
  });

  Languages.fromJson(Map<dynamic, dynamic> json) {
    defaultLanguage = json['default']?.toString() ?? 'en';
    if (json['languages'] is List) {
      languages = (json['languages'] as List)
          .whereType<Map>()
          .map((e) => LanguageData.fromJson(e))
          .toList();
    } else {
      languages = [];
    }
  }
}

class LanguageData {
  String? code;
  String? name;
  String? nativeName;
  String? direction;

  LanguageData({
    this.code,
    this.name,
    this.nativeName,
    this.direction,
  });

  LanguageData.fromJson(Map<dynamic, dynamic> json) {
    code = json['code']?.toString() ?? '';
    name = json['name']?.toString() ?? '';
    nativeName = json['native_name']?.toString() ?? '';
    direction = json['direction']?.toString() ?? 'ltr';
  }
}
