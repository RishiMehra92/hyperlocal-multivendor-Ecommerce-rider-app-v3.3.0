import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';

class ItemsCollectedState extends Equatable {
  final ApiStatus status;
  final String itemId;
  final bool isDelivery;
  final String message;

  const ItemsCollectedState({
    this.status = ApiStatus.initial,
    this.itemId = "",
    this.isDelivery = false,
    this.message = "",
  });

  ItemsCollectedState copyWith({
    ApiStatus? status,
    String? itemId,
    bool? isDelivery,
    String? message,
  }) {
    return ItemsCollectedState(
      status: status ?? this.status,
      itemId: itemId ?? this.itemId,
      isDelivery: isDelivery ?? this.isDelivery,
      message: message ?? this.message,
    );
  }

  @override
  List<Object> get props => [status, itemId, isDelivery, message];
}
