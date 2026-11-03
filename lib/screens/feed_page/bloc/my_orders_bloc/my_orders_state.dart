import 'package:equatable/equatable.dart';
import '../../model/available_orders.dart';
import 'package:hyper_local/config/helper.dart';

class MyOrdersState extends Equatable {
  final ApiStatus status;
  final List<Orders> myOrders;
  final bool hasReachedMax;
  final int totalOrders;
  final String selectedFilter;
  final String message;
  final bool isRefreshing;

  const MyOrdersState({
    this.status = ApiStatus.initial,
    this.myOrders = const [],
    this.hasReachedMax = false,
    this.totalOrders = 0,
    this.selectedFilter = 'all',
    this.message = "",
    this.isRefreshing = false,
  });

  MyOrdersState copyWith({
    ApiStatus? status,
    List<Orders>? myOrders,
    bool? hasReachedMax,
    int? totalOrders,
    String? selectedFilter,
    String? message,
    bool? isRefreshing,
  }) {
    return MyOrdersState(
      status: status ?? this.status,
      myOrders: myOrders ?? this.myOrders,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalOrders: totalOrders ?? this.totalOrders,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      message: message ?? this.message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object> get props => [
    status,
    myOrders,
    hasReachedMax,
    totalOrders,
    selectedFilter,
    message,
    isRefreshing,
  ];
}
