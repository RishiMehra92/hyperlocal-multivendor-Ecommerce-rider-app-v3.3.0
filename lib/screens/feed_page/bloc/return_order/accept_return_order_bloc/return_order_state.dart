import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';

class ReturnOrderState extends Equatable {
  final ApiStatus status;
  final String message;
  final String returnId;
  final String errorMessage;

  const ReturnOrderState({
    this.status = ApiStatus.initial,
    this.message = "",
    this.returnId = "",
    this.errorMessage = "",
  });

  ReturnOrderState copyWith({
    ApiStatus? status,
    String? message,
    String? returnId,
    String? errorMessage,
  }) {
    return ReturnOrderState(
      status: status ?? this.status,
      message: message ?? this.message,
      returnId: returnId ?? this.returnId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, message, returnId, errorMessage];
}
