import '../../../config/helper.dart';

class MobileAndEmailCheck {
  bool? success;
  String? message;
  Data? data;

  MobileAndEmailCheck({this.success, this.message, this.data});

  MobileAndEmailCheck.fromJson(Map<String, dynamic> json) {
    success = parseBool(json['success']);
    message = parseString(json['message']);
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  bool? exists;
  String? type;
  String? value;

  Data({this.exists, this.type, this.value});

  Data.fromJson(Map<String, dynamic> json) {
    exists = parseBool(json['exists']);
    type = parseString(json['type']);
    value = parseString(json['value']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['exists'] = exists;
    data['type'] = type;
    data['value'] = value;
    return data;
  }
}
