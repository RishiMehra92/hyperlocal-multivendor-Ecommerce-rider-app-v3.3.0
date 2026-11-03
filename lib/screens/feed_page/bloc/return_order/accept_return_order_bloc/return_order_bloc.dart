import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/screens/feed_page/repo/return_order_repo.dart';
import 'package:hyper_local/config/helper.dart';

import 'return_order_event.dart';
import 'return_order_state.dart';

class ReturnOrderBloc extends Bloc<ReturnOrderEvent, ReturnOrderState> {
  final ReturnOrderRepo _repo = ReturnOrderRepo();

  ReturnOrderBloc() : super(const ReturnOrderState()) {
    on<AcceptReturnOrder>(_onAcceptReturnOrder);
  }

  Future<void> _onAcceptReturnOrder(
    AcceptReturnOrder event,
    Emitter<ReturnOrderState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ApiStatus.loading));

      final response = await _repo.acceptReturnOrder(event.returnId);

      if (response['success'] == true) {
        final String message =
            response['message'] ?? 'Return order accepted successfully';

        emit(
          state.copyWith(
            status: ApiStatus.success,
            message: message,
            returnId: event.returnId,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            errorMessage:
                response['message'] ?? 'Failed to accept return order',
          ),
        );
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            errorMessage: "Network error: $e",
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            errorMessage: "Something went wrong. Please try again.",
          ),
        );
      }
    }
  }
}
