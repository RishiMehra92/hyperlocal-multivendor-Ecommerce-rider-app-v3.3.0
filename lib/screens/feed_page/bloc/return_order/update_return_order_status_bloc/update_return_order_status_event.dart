part of 'update_return_order_status_bloc.dart';

abstract class UpdateReturnOrderStatusEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

final class UpdateReturnOrderStatus extends UpdateReturnOrderStatusEvent {
  final String returnId;
  final String status;
  final String? otp;
  final List<File>? images;
  final String? pickupCondition;
  final String? pickupRemarks;

  UpdateReturnOrderStatus({
    required this.status,
    required this.returnId,
    this.otp,
    this.images,
    this.pickupCondition,
    this.pickupRemarks,
  });

  @override
  List<Object?> get props => [
    returnId,
    status,
    otp,
    images,
    pickupCondition,
    pickupRemarks,
  ];
}
