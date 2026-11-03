import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';

class ForgotPasswordState extends Equatable {
  final ApiStatus status;
  final String message;
  final String errorMessage;

  const ForgotPasswordState({
    this.status = ApiStatus.initial,
    this.message = "",
    this.errorMessage = "",
  });

  ForgotPasswordState copyWith({
    ApiStatus? status,
    String? message,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, message, errorMessage];
}
