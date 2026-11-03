import 'package:equatable/equatable.dart';
import '../model/delivery_zone_model.dart';
import 'package:hyper_local/config/helper.dart';

class DeliveryZoneState extends Equatable {
  final ApiStatus status;
  final List<DeliveryZoneModel> zones;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;
  final String searchQuery;
  final DeliveryZoneModel? selectedZone;
  final String message;
  final bool isLoadingMore;

  const DeliveryZoneState({
    this.status = ApiStatus.initial,
    this.zones = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.hasMore = false,
    this.searchQuery = '',
    this.selectedZone,
    this.message = '',
    this.isLoadingMore = false,
  });

  DeliveryZoneState copyWith({
    ApiStatus? status,
    List<DeliveryZoneModel>? zones,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? hasMore,
    String? searchQuery,
    DeliveryZoneModel? selectedZone,
    String? message,
    bool? isLoadingMore,
    bool clearSelectedZone = false,
  }) {
    return DeliveryZoneState(
      status: status ?? this.status,
      zones: zones ?? this.zones,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedZone:
          clearSelectedZone ? null : (selectedZone ?? this.selectedZone),
      message: message ?? this.message,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    status,
    zones,
    currentPage,
    lastPage,
    total,
    hasMore,
    searchQuery,
    selectedZone,
    message,
    isLoadingMore,
  ];
}
