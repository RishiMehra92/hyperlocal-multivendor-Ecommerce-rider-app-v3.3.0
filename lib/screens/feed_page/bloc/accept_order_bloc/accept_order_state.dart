import 'package:equatable/equatable.dart';
import '../../../../config/helper.dart';

class AcceptOrderState extends Equatable {
  final ApiStatus status;
  final String message;
  final String orderId;
  final String errorMessage;

  const AcceptOrderState({
    this.status = ApiStatus.initial,
    this.message = "",
    this.orderId = "",
    this.errorMessage = "",
  });

  AcceptOrderState copyWith({
    ApiStatus? status,
    String? message,
    String? orderId,
    String? errorMessage,
  }) {
    return AcceptOrderState(
      status: status ?? this.status,
      message: message ?? this.message,
      orderId: orderId ?? this.orderId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, message, orderId, errorMessage];
}
