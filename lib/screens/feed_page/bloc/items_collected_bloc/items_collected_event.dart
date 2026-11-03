import 'package:equatable/equatable.dart';

abstract class ItemsCollectedEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ItemsCollected extends ItemsCollectedEvent {
  final String orderItemId;

  ItemsCollected(this.orderItemId);

  @override
  List<Object> get props => [orderItemId];
}

class ItemsCollectedWithOtp extends ItemsCollectedEvent {
  final String orderItemId;
  final String otp;

  ItemsCollectedWithOtp({required this.orderItemId, required this.otp});

  @override
  List<Object> get props => [orderItemId, otp];
}

class ItemsDelivered extends ItemsCollectedEvent {
  final String orderItemId;

  ItemsDelivered(this.orderItemId);

  @override
  List<Object> get props => [orderItemId];
}

class CollectAllItems extends ItemsCollectedEvent {
  final int orderId;
  final int storeId;

  CollectAllItems({required this.orderId, required this.storeId});

  @override
  List<Object> get props => [orderId, storeId];
}

class DeliverAllItems extends ItemsCollectedEvent {
  final int orderId;
  final String? otp;

  DeliverAllItems({required this.orderId, this.otp});

  @override
  List<Object?> get props => [orderId, otp];
}
