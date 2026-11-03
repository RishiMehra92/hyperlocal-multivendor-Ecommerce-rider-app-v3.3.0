import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/api_base_helper.dart';
import 'package:hyper_local/config/helper.dart';

import '../../repo/items_collected.dart';
import 'items_collected_event.dart';
import 'items_collected_state.dart';

class ItemsCollectedBloc
    extends Bloc<ItemsCollectedEvent, ItemsCollectedState> {
  ItemsCollectedBloc() : super(const ItemsCollectedState()) {
    on<ItemsCollected>((event, emit) => _onItemsCollected(event, emit));
    on<ItemsCollectedWithOtp>(
      (event, emit) => _onItemsCollectedWithOtp(event, emit),
    );
    on<ItemsDelivered>((event, emit) => _onItemsDelivered(event, emit));
    on<CollectAllItems>((event, emit) => _onCollectAllItems(event, emit));
    on<DeliverAllItems>((event, emit) => _onDeliverAllItems(event, emit));
  }

  Future<void> _onItemsCollected(
    ItemsCollected event,
    Emitter<ItemsCollectedState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: ApiStatus.loading,
          itemId: event.orderItemId,
          isDelivery: false,
        ),
      );

      final response = await ItemsCollectedRepo().itemsCollected(
        event.orderItemId,
      );

      // Check if success is true OR if message contains "already has this status"
      bool isSuccess = response['success'] == true;
      String message = response['message'] ?? 'Failed to collect items';
      bool isAlreadyCollected = message.contains('already has this status');

      if (isSuccess || isAlreadyCollected) {
        // Both cases should be treated as success
        String successMessage =
            isAlreadyCollected
                ? 'Item already collected'
                : (response['message'] ?? 'Items collected successfully');
        emit(
          state.copyWith(
            status: ApiStatus.success,
            message: successMessage,
            itemId: event.orderItemId,
            isDelivery: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: message,
            itemId: event.orderItemId,
            isDelivery: false,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "Error: $e",
          itemId: event.orderItemId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "Unexpected error: $e",
          itemId: event.orderItemId,
        ),
      );
    }
  }

  Future<void> _onItemsCollectedWithOtp(
    ItemsCollectedWithOtp event,
    Emitter<ItemsCollectedState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: ApiStatus.loading,
          itemId: event.orderItemId,
          isDelivery: true,
        ),
      );

      final response = await ItemsCollectedRepo().itemsDelivered(
        event.orderItemId,
        event.otp,
      );

      // Check if success is true OR if message contains "already has this status"
      bool isSuccess = response['success'] == true;
      String message = response['message'] ?? 'Failed to collect item with OTP';
      bool isAlreadyCollected = message.contains('already has this status');

      if (isSuccess || isAlreadyCollected) {
        // Both cases should be treated as success
        String successMessage =
            isAlreadyCollected
                ? 'Item already delivered'
                : (response['message'] ??
                    'Item collected with OTP successfully');
        emit(
          state.copyWith(
            status: ApiStatus.success,
            message: successMessage,
            itemId: event.orderItemId,
            isDelivery: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: message,
            itemId: event.orderItemId,
            isDelivery: true,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "Error: $e",
          itemId: event.orderItemId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "Unexpected error: $e",
          itemId: event.orderItemId,
        ),
      );
    }
  }

  Future<void> _onItemsDelivered(
    ItemsDelivered event,
    Emitter<ItemsCollectedState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: ApiStatus.loading,
          itemId: event.orderItemId,
          isDelivery: true,
        ),
      );

      final response = await ItemsCollectedRepo().itemsDelivered(
        event.orderItemId,
        null,
      );

      // Check if success is true OR if message contains "already has this status"
      bool isSuccess = response['success'] == true;
      String message = response['message'] ?? 'Failed to deliver item';
      bool isAlreadyDelivered = message.contains('already has this status');

      if (isSuccess || isAlreadyDelivered) {
        // Both cases should be treated as success
        String successMessage =
            isAlreadyDelivered
                ? 'Item already delivered'
                : (response['message'] ?? 'Item delivered successfully');

        emit(
          state.copyWith(
            status: ApiStatus.success,
            message: successMessage,
            itemId: event.orderItemId,
            isDelivery: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: message,
            itemId: event.orderItemId,
            isDelivery: true,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "Error: $e",
          itemId: event.orderItemId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "Unexpected error: $e",
          itemId: event.orderItemId,
        ),
      );
    }
  }

  Future<void> _onCollectAllItems(
    CollectAllItems event,
    Emitter<ItemsCollectedState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: ApiStatus.loading,
          itemId: "ALL_STORE_${event.storeId}",
          isDelivery: false,
        ),
      );

      final response = await ItemsCollectedRepo().collectAll(
        orderId: event.orderId,
        storeId: event.storeId,
      );

      bool isSuccess = response['success'] == true;
      String message = response['message'] ?? 'Failed to collect all items';

      if (isSuccess) {
        emit(
          state.copyWith(
            status: ApiStatus.success,
            message: message,
            itemId: "ALL_STORE_${event.storeId}",
            isDelivery: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: message,
            itemId: "ALL_STORE_${event.storeId}",
            isDelivery: false,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "Error: $e",
          itemId: "ALL_STORE_${event.storeId}",
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "Unexpected error: $e",
          itemId: "ALL_STORE_${event.storeId}",
        ),
      );
    }
  }

  Future<void> _onDeliverAllItems(
    DeliverAllItems event,
    Emitter<ItemsCollectedState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: ApiStatus.loading,
          itemId: "ALL_DELIVER",
          isDelivery: true,
        ),
      );

      final response = await ItemsCollectedRepo().deliverAll(
        orderId: event.orderId,
        otp: event.otp,
      );

      bool isSuccess = response['success'] == true;
      String message = response['message'] ?? 'Failed to deliver all items';

      if (isSuccess) {
        emit(
          state.copyWith(
            status: ApiStatus.success,
            message: message,
            itemId: "ALL_DELIVER",
            isDelivery: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: message,
            itemId: "ALL_DELIVER",
            isDelivery: true,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "Error: $e",
          itemId: "ALL_DELIVER",
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "Unexpected error: $e",
          itemId: "ALL_DELIVER",
        ),
      );
    }
  }
}
