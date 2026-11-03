import 'dart:async';
import 'package:equatable/equatable.dart';

abstract class AvailableOrdersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AllAvailableOrdersList extends AvailableOrdersEvent {
  final String? type;
  final int? typeId;
  final bool forceRefresh;
  final Completer<void>? completer;

  AllAvailableOrdersList({
    this.type,
    this.typeId,
    this.forceRefresh = false,
    this.completer,
  });

  @override
  List<Object?> get props => [type, typeId, forceRefresh, completer];
}

class SearchAvailableOrders extends AvailableOrdersEvent {
  final String searchQuery;
  final String? type;
  final int? typeId;

  SearchAvailableOrders(this.searchQuery, this.typeId, this.type);

  @override
  List<Object?> get props => [searchQuery, typeId, type];
}

class LoadMoreAvailableOrders extends AvailableOrdersEvent {
  final String searchWord;
  final int currentLength;

  LoadMoreAvailableOrders(this.searchWord, {this.currentLength = 0});

  @override
  List<Object?> get props => [searchWord, currentLength];
}
