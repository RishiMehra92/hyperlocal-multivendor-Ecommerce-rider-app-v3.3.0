import 'dart:async';
import 'package:equatable/equatable.dart';

abstract class ReturnOrderListEvent extends Equatable {
  const ReturnOrderListEvent();

  @override
  List<Object?> get props => [];
}

class FetchReturnOrders extends ReturnOrderListEvent {
  final bool forceRefresh;
  final Completer<void>? completer;

  const FetchReturnOrders({this.forceRefresh = false, this.completer});

  @override
  List<Object?> get props => [forceRefresh, completer];
}

class LoadMoreReturnOrders extends ReturnOrderListEvent {
  const LoadMoreReturnOrders();
}

class RefreshReturnOrders extends ReturnOrderListEvent {
  const RefreshReturnOrders();
}
