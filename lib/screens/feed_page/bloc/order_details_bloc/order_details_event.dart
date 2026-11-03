import 'dart:async';
import 'package:equatable/equatable.dart';

abstract class OrderDetailsEvent extends Equatable {
  const OrderDetailsEvent();

  @override
  List<Object?> get props => [];
}

class FetchOrderDetails extends OrderDetailsEvent {
  final int orderId;
  final Completer<void>? completer;

  const FetchOrderDetails(this.orderId, {this.completer});

  @override
  List<Object?> get props => [orderId, completer];
}

class MarkItemReachedDestination extends OrderDetailsEvent {
  final int orderId;
  final int itemId;

  const MarkItemReachedDestination(this.orderId, this.itemId);

  @override
  List<Object?> get props => [orderId, itemId];
}

class CheckPaymentStatus extends OrderDetailsEvent {
  final int orderId;

  const CheckPaymentStatus(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class CancelPaymentLink extends OrderDetailsEvent {
  final int orderId;

  const CancelPaymentLink(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
