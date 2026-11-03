import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';

class UpdateReturnOrderStatusState extends Equatable {
  final ApiStatus status;
  final String message;
  final String returnId;

  const UpdateReturnOrderStatusState({
    this.status = ApiStatus.initial,
    this.message = "",
    this.returnId = "",
  });

  UpdateReturnOrderStatusState copyWith({
    ApiStatus? status,
    String? message,
    String? returnId,
  }) {
    return UpdateReturnOrderStatusState(
      status: status ?? this.status,
      message: message ?? this.message,
      returnId: returnId ?? this.returnId,
    );
  }

  @override
  List<Object?> get props => [status, message, returnId];
}
