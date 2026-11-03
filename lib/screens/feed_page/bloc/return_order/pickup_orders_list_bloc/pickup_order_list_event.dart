part of 'pickup_order_list_bloc.dart';

abstract class PickupOrderListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchPickupOrders extends PickupOrderListEvent {
  final String? status;
  final bool forceRefresh;
  final Completer<void>? completer;

  FetchPickupOrders({this.status, this.forceRefresh = false, this.completer});
}

class LoadMorePickupOrders extends PickupOrderListEvent {}

class RefreshPickupOrders extends PickupOrderListEvent {}
