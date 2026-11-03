import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../config/api_base_helper.dart';

import '../../../../config/helper.dart';
import '../../repo/accept_order.dart';
import 'accept_order_event.dart';
import 'accept_order_state.dart';

class AcceptOrderBloc extends Bloc<AcceptOrderEvent, AcceptOrderState> {
  AcceptOrderBloc() : super(const AcceptOrderState()) {
    on<AcceptOrder>(_onAcceptOrder);
  }

  Future<void> _onAcceptOrder(
    AcceptOrder event,
    Emitter<AcceptOrderState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: ApiStatus.loading,
          orderId: event.orderId.toString(),
        ),
      );

      final response = await AcceptOrderRepo().updateAcceptOrder(
        orderId: event.orderId,
      );

      if (response['success'] == true) {
        emit(
          state.copyWith(
            status: ApiStatus.success,
            message: response['message'] ?? 'Order accepted successfully',
            orderId: event.orderId.toString(),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            errorMessage: response['message'] ?? 'Failed to accept order',
          ),
        );
      }
    } on ApiException catch (e) {
      if (kDebugMode) {}
      emit(state.copyWith(status: ApiStatus.failed, errorMessage: "Error: $e"));
    } catch (e) {
      if (kDebugMode) {}
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          errorMessage: "Unexpected error: $e",
        ),
      );
    }
  }
}
