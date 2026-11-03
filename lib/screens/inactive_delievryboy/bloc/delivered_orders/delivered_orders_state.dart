import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../../../feed_page/model/available_orders.dart';

class DeliveredOrdersState extends Equatable {
  final ApiStatus status;
  final List<Orders> deliveredOrders;
  final bool hasReachedMax;
  final int totalOrders;
  final String errorMessage;
  final bool isRefreshing;

  const DeliveredOrdersState({
    this.status = ApiStatus.initial,
    this.deliveredOrders = const [],
    this.hasReachedMax = false,
    this.totalOrders = 0,
    this.errorMessage = "",
    this.isRefreshing = false,
  });

  DeliveredOrdersState copyWith({
    ApiStatus? status,
    List<Orders>? deliveredOrders,
    bool? hasReachedMax,
    int? totalOrders,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return DeliveredOrdersState(
      status: status ?? this.status,
      deliveredOrders: deliveredOrders ?? this.deliveredOrders,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalOrders: totalOrders ?? this.totalOrders,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    deliveredOrders,
    hasReachedMax,
    totalOrders,
    errorMessage,
    isRefreshing,
  ];
}
