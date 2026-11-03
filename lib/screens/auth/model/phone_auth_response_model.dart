class PhoneAuthResponseModel {
  final bool success;
  final String message;
  final String? accessToken;
  final Map<String, dynamic>? data;

  PhoneAuthResponseModel({
    required this.success,
    required this.message,
    this.accessToken,
    this.data,
  });

  factory PhoneAuthResponseModel.fromJson(Map<String, dynamic> json) {
    String? accessToken;

    // data may be a Map or an empty List [] — only treat it as a Map if it actually is one
    final dynamic rawData = json['data'];
    final Map<String, dynamic>? dataMap =
        rawData is Map<String, dynamic> ? rawData : null;

    // Check if access_token is directly in the response
    if (json['access_token'] != null) {
      accessToken = json['access_token'] as String?;
    }
    // Check if it's nested in data
    else if (dataMap != null && dataMap['access_token'] != null) {
      accessToken = dataMap['access_token'] as String?;
    }
    // Check if it's in data.token
    else if (dataMap != null && dataMap['token'] != null) {
      accessToken = dataMap['token'] as String?;
    }

    return PhoneAuthResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      accessToken: accessToken,
      data: dataMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'access_token': accessToken,
      'data': data,
    };
  }
}
