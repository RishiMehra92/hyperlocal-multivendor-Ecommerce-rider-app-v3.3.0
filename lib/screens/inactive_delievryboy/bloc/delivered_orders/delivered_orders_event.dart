import 'dart:async';
import 'package:equatable/equatable.dart';

abstract class DeliveredOrdersEvent extends Equatable {
  const DeliveredOrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadDeliveredOrders extends DeliveredOrdersEvent {
  final bool forceRefresh;
  final Completer<void>? completer;

  const LoadDeliveredOrders({this.forceRefresh = false, this.completer});

  @override
  List<Object?> get props => [forceRefresh, completer];
}

class LoadMoreDeliveredOrders extends DeliveredOrdersEvent {
  final String searchQuery;

  const LoadMoreDeliveredOrders(this.searchQuery);

  @override
  List<Object?> get props => [searchQuery];
}

class SearchDeliveredOrders extends DeliveredOrdersEvent {
  final String searchQuery;

  const SearchDeliveredOrders(this.searchQuery);

  @override
  List<Object?> get props => [searchQuery];
}
