part of 'pickup_order_list_bloc.dart';

class PickupOrderListState extends Equatable {
  final ApiStatus status;
  final List<Pickups> orders;
  final bool hasReachedMax;
  final int totalOrders;
  final String message;
  final bool isRefreshing;
  final String selectedFilter;

  const PickupOrderListState({
    this.status = ApiStatus.initial,
    this.orders = const [],
    this.hasReachedMax = false,
    this.totalOrders = 0,
    this.message = "",
    this.isRefreshing = false,
    this.selectedFilter = 'on_going',
  });

  PickupOrderListState copyWith({
    ApiStatus? status,
    List<Pickups>? orders,
    bool? hasReachedMax,
    int? totalOrders,
    String? message,
    bool? isRefreshing,
    String? selectedFilter,
  }) {
    return PickupOrderListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalOrders: totalOrders ?? this.totalOrders,
      message: message ?? this.message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  @override
  List<Object?> get props => [
    status,
    orders,
    hasReachedMax,
    totalOrders,
    message,
    isRefreshing,
    selectedFilter,
  ];
}
