class DeleteAccountResponse {
  final bool success;
  final String message;

  DeleteAccountResponse({required this.success, required this.message});

  factory DeleteAccountResponse.fromJson(Map<String, dynamic> json) {
    return DeleteAccountResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message};
  }
}
