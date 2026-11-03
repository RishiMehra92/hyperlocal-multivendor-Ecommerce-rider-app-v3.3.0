import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/update_return_order_status_bloc/update_return_order_status_state.dart';
import 'package:hyper_local/screens/feed_page/repo/return_order_repo.dart';
import 'package:hyper_local/config/helper.dart';

part 'update_return_order_status_event.dart';

class UpdateReturnOrderStatusBloc
    extends Bloc<UpdateReturnOrderStatusEvent, UpdateReturnOrderStatusState> {
  final ReturnOrderRepo _repo = ReturnOrderRepo();

  UpdateReturnOrderStatusBloc() : super(const UpdateReturnOrderStatusState()) {
    on<UpdateReturnOrderStatus>(_onUpdateReturnOrderStatus);
  }

  Future<void> _onUpdateReturnOrderStatus(
    UpdateReturnOrderStatus event,
    Emitter<UpdateReturnOrderStatusState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ApiStatus.loading, returnId: event.returnId));

      final response = await _repo.updateReturnOrderStatus(
        event.returnId,
        event.status,
        otp: event.otp,
        images: event.images,
        pickupCondition: event.pickupCondition,
        pickupRemarks: event.pickupRemarks,
      );

      if (response['success'] == true) {
        final String message =
            response['message'] ?? 'Status updated successfully';

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
            message: response['message'] ?? 'Failed to update status',
            returnId: event.returnId,
          ),
        );
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: "Network error: $e",
            returnId: event.returnId,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: "Something went wrong. Please try again.",
            returnId: event.returnId,
          ),
        );
      }
    }
  }
}
