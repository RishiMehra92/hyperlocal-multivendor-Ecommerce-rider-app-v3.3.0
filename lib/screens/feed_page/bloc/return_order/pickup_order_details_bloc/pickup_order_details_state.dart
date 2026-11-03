import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/feed_page/model/return_orders_list_model.dart';

class PickupOrderDetailsState extends Equatable {
  final ApiStatus status;
  final Pickups? pickups;
  final String message;

  const PickupOrderDetailsState({
    this.status = ApiStatus.initial,
    this.pickups,
    this.message = "",
  });

  PickupOrderDetailsState copyWith({
    ApiStatus? status,
    Pickups? pickups,
    String? message,
  }) {
    return PickupOrderDetailsState(
      status: status ?? this.status,
      pickups: pickups ?? this.pickups,
      message: message ?? this.message,
    );
  }

  @override
  // TODO: implement props
  List<Object?> get props => [status, pickups, message];
}
