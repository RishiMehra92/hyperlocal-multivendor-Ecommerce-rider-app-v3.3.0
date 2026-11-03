import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/helper.dart';
import 'order_details_event.dart';
import 'order_details_state.dart';
import '../../repo/order_details.dart';
import '../../model/available_orders.dart';

class OrderDetailsBloc extends Bloc<OrderDetailsEvent, OrderDetailsState> {
  final OrderDetailsRepo _orderDetailsRepo;

  static const String _reachedDestinationPrefix = 'reached_destination_';

  OrderDetailsBloc(this._orderDetailsRepo) : super(const OrderDetailsState()) {
    on<FetchOrderDetails>(_onFetchOrderDetails);
    on<MarkItemReachedDestination>(_onMarkItemReachedDestination);
    on<CheckPaymentStatus>(_onCheckPaymentStatus);
    on<CancelPaymentLink>(_onCancelPaymentLink);
  }

  // Helper method to get the storage key for an item
  String _getStorageKey(int orderId, int itemId) =>
      '${_reachedDestinationPrefix}order_${orderId}_item_$itemId';

  // Helper method to save reachedDestination status
  Future<void> _saveReachedDestinationStatus(
    int orderId,
    int itemId,
    bool status,
  ) async {
    final storageKey = _getStorageKey(orderId, itemId);
    // await _prefs!.setBool(storageKey, status);

    await Global.setReachedDestinationStatus(storageKey, status);
  }

  // Helper method to get reachedDestination status
  Future<bool?> _getReachedDestinationStatus(int orderId, int itemId) async {
    final storageKey = _getStorageKey(orderId, itemId);
    // final status = _prefs!.getBool(storageKey);
    final status = await Global.getReachedDestinationStatus(storageKey);

    return status;
  }

  Future<void> _onFetchOrderDetails(
    FetchOrderDetails event,
    Emitter<OrderDetailsState> emit,
  ) async {
    if (state.order == null) {
      emit(state.copyWith(status: ApiStatus.loading));
    }
    try {
      final response = await _orderDetailsRepo.getOrderDetails(event.orderId);

      if (response['success'] == true && response['data'] != null) {
        final order = Orders.fromJson(response['data']['order']);

        if (order.items != null) {
          final updatedItems = await Future.wait(
            order.items!.map((item) async {
              if (item.id != null) {
                final savedStatus = await _getReachedDestinationStatus(
                  event.orderId,
                  item.id!,
                );

                if (savedStatus == true) {
                  return item.copyWith(reachedDestination: true);
                }
              }
              return item;
            }),
          );

          final updatedOrder = order.copyWith(items: updatedItems);
          emit(state.copyWith(status: ApiStatus.success, order: updatedOrder));
        } else {
          emit(state.copyWith(status: ApiStatus.success, order: order));
        }
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            errorMessage:
                response['message'] ?? 'Failed to fetch order details',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onMarkItemReachedDestination(
    MarkItemReachedDestination event,
    Emitter<OrderDetailsState> emit,
  ) async {
    // Get current state
    if (state.status == ApiStatus.success && state.order != null) {
      final currentOrder = state.order!;

      // Update the specific item's reachedDestination status
      final updatedItems =
          currentOrder.items?.map((item) {
            if (item.id == event.itemId) {
              return item.copyWith(reachedDestination: true);
            }
            return item;
          }).toList();

      if (updatedItems != null) {
        await _saveReachedDestinationStatus(event.orderId, event.itemId, true);

        // Create updated order with modified items
        final updatedOrder = currentOrder.copyWith(items: updatedItems);
        emit(state.copyWith(status: ApiStatus.success, order: updatedOrder));
      }
    } else {
      //
    }
  }

  Future<void> _onCheckPaymentStatus(
    CheckPaymentStatus event,
    Emitter<OrderDetailsState> emit,
  ) async {
    try {
      final response = await _orderDetailsRepo.checkPaymentStatus(
        event.orderId,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final isCodPaidOnline = data['is_cod_paid_online'] == true;
        final paymentStatus = data['payment_status']?.toString();

        final currentOrder = state.order ?? Orders(id: event.orderId);
        final updatedOrder = currentOrder.copyWith(
          isCodPaidOnline: isCodPaidOnline,
          paymentStatus: paymentStatus,
        );
        emit(state.copyWith(status: ApiStatus.success, order: updatedOrder));
      }
    } catch (error) {
      debugPrint('Error polling payment status in Bloc: $error');
    }
  }

  Future<void> _onCancelPaymentLink(
    CancelPaymentLink event,
    Emitter<OrderDetailsState> emit,
  ) async {
    try {
      await _orderDetailsRepo.cancelPaymentLink(event.orderId);
    } catch (error) {
      debugPrint('Error cancelling payment link in Bloc: $error');
    }
  }
}
