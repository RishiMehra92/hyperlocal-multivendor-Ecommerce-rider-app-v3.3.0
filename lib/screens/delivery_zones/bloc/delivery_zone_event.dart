import 'package:equatable/equatable.dart';

abstract class DeliveryZoneEvent extends Equatable {
  const DeliveryZoneEvent();

  @override
  List<Object?> get props => [];
}

class FetchDeliveryZonesEvent extends DeliveryZoneEvent {
  final int page;
  final String? search;

  const FetchDeliveryZonesEvent({this.page = 1, this.search});

  @override
  List<Object?> get props => [page, search];
}

class SearchDeliveryZonesEvent extends DeliveryZoneEvent {
  final String query;

  const SearchDeliveryZonesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadMoreDeliveryZonesEvent extends DeliveryZoneEvent {
  const LoadMoreDeliveryZonesEvent();
}

class SelectDeliveryZoneEvent extends DeliveryZoneEvent {
  final int zoneId;

  const SelectDeliveryZoneEvent(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}

class ClearSelectedZoneEvent extends DeliveryZoneEvent {
  const ClearSelectedZoneEvent();
}
