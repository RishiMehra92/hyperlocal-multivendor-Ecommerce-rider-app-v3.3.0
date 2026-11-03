class LanguageLabelsModel {
  bool? success;
  String? message;
  LanguageLabels? data;

  LanguageLabelsModel({this.success, this.message, this.data});

  LanguageLabelsModel.fromJson(Map<dynamic, dynamic> json) {
    success = json['success'] as bool? ?? (json['success']?.toString() == 'true');
    message = json['message']?.toString();
    if (json['data'] is Map) {
      data = LanguageLabels.fromJson(json['data'] as Map);
    }
  }
}

/// Backward compatibility alias
typedef LanguageListModel = LanguageLabelsModel;

class LanguageLabels {
  String? locale;
  String? direction;
  Map<String, String>? labels;

  LanguageLabels({this.locale, this.direction, this.labels});

  factory LanguageLabels.fromJson(Map<dynamic, dynamic> json) {
    final rawLabels = json['labels'];
    final Map<String, String> convertedLabels = {};
    if (rawLabels is Map) {
      rawLabels.forEach((key, val) {
        convertedLabels[key.toString()] = val.toString();
      });
    }

    return LanguageLabels(
      locale: json['locale']?.toString(),
      direction: json['direction']?.toString(),
      labels: convertedLabels,
    );
  }
}
