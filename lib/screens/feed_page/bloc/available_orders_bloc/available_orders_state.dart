import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../../model/available_orders.dart';

class AvailableOrdersState extends Equatable {
  final ApiStatus fetchStatus;
  final List<Orders> availableOrders;
  final bool hasReachedMax;
  final int totalOrders;
  final String message;
  final bool isRefreshing;
  final bool isPaginating;

  const AvailableOrdersState({
    this.fetchStatus = ApiStatus.initial,
    this.availableOrders = const [],
    this.hasReachedMax = false,
    this.totalOrders = 0,
    this.message = '',
    this.isRefreshing = false,
    this.isPaginating = false,
  });

  AvailableOrdersState copyWith({
    ApiStatus? fetchStatus,
    List<Orders>? availableOrders,
    bool? hasReachedMax,
    int? totalOrders,
    String? message,
    bool? isRefreshing,
    bool? isPaginating,
    bool clearMessage = false,
  }) {
    return AvailableOrdersState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      availableOrders: availableOrders ?? this.availableOrders,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalOrders: totalOrders ?? this.totalOrders,
      message: clearMessage ? '' : (message ?? this.message),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isPaginating: isPaginating ?? this.isPaginating,
    );
  }

  @override
  List<Object?> get props => [
    fetchStatus,
    availableOrders,
    hasReachedMax,
    totalOrders,
    message,
    isRefreshing,
    isPaginating,
  ];
}
