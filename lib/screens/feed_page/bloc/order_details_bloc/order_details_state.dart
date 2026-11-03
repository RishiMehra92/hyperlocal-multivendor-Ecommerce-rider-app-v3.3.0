import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../../model/available_orders.dart';

class OrderDetailsState extends Equatable {
  final ApiStatus status;
  final Orders? order;
  final String errorMessage;

  const OrderDetailsState({
    this.status = ApiStatus.initial,
    this.order,
    this.errorMessage = "",
  });

  OrderDetailsState copyWith({
    ApiStatus? status,
    Orders? order,
    String? errorMessage,
  }) {
    return OrderDetailsState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, order, errorMessage];
}
