import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/helper.dart';
import '../../../../config/api_base_helper.dart';
import '../../../feed_page/model/available_orders.dart';
import '../../../feed_page/repo/my_orders.dart';

import 'delivered_orders_event.dart';
import 'delivered_orders_state.dart';

class DeliveredOrdersBloc
    extends Bloc<DeliveredOrdersEvent, DeliveredOrdersState> {
  int _offset = 0;
  final int _limit = 10;
  bool _hasReachedMax = false;
  bool _isLoading = false;

  DeliveredOrdersBloc() : super(const DeliveredOrdersState()) {
    on<LoadDeliveredOrders>(_onLoadDeliveredOrders);
    on<SearchDeliveredOrders>(_onSearchDeliveredOrders);
    on<LoadMoreDeliveredOrders>(_onLoadMoreDeliveredOrders);
  }

  Future<void> _onLoadDeliveredOrders(
    LoadDeliveredOrders event,
    Emitter<DeliveredOrdersState> emit,
  ) async {
    try {
      // Only load if we don't have data or if explicitly requested
      if (state.status == ApiStatus.success) {
        // If we already have data, don't reload unless it's a manual refresh
        if (!event.forceRefresh) {
          if (event.completer != null && !event.completer!.isCompleted) {
            event.completer!.complete();
          }
          return; // Keep existing data
        }
        emit(state.copyWith(isRefreshing: true));
      } else {
        emit(state.copyWith(status: ApiStatus.loading));
      }

      _offset = 0;
      _hasReachedMax = false;

      final response = await MyOrdersRepo().getDeliveredOrders(
        limit: _limit,
        offset: _offset,
        search: '',
      );

      final List<Orders> orders =
          (response['data']['orders'] as List<dynamic>?)
              ?.map((item) => Orders.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      final int currentPage = response['data']['current_page'] as int;
      final int lastPage = response['data']['last_page'] as int;
      final int totalOrders = response['data']['total'] ?? 0;

      _offset += _limit;
      _hasReachedMax = currentPage >= lastPage;

      if (response['success'] == true) {
        emit(
          state.copyWith(
            status: ApiStatus.success,
            deliveredOrders: orders,
            hasReachedMax: _hasReachedMax,
            totalOrders: totalOrders,
            isRefreshing: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            errorMessage:
                response['message'] ?? 'Failed to load delivered orders',
            isRefreshing: false,
          ),
        );
      }
    } on ApiException catch (e) {
      if (kDebugMode) {}
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          errorMessage: "Error: $e",
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {}
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          errorMessage: "Unexpected error: $e",
          isRefreshing: false,
        ),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onSearchDeliveredOrders(
    SearchDeliveredOrders event,
    Emitter<DeliveredOrdersState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ApiStatus.loading));
      _offset = 0;
      _hasReachedMax = false;

      final response = await MyOrdersRepo().getDeliveredOrders(
        limit: _limit,
        offset: _offset,
        search: event.searchQuery,
      );

      final List<Orders> orders =
          (response['data']['orders'] as List<dynamic>?)
              ?.map((item) => Orders.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      final int currentPage = response['data']['current_page'] as int;
      final int lastPage = response['data']['last_page'] as int;
      final int totalOrders = response['data']['total'] ?? 0;

      _hasReachedMax = currentPage >= lastPage;

      if (response['success'] == true) {
        emit(
          state.copyWith(
            status: ApiStatus.success,
            deliveredOrders: orders,
            hasReachedMax: _hasReachedMax,
            totalOrders: totalOrders,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            errorMessage:
                response['message'] ?? 'Failed to search delivered orders',
          ),
        );
      }
    } on ApiException catch (e) {
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

  Future<void> _onLoadMoreDeliveredOrders(
    LoadMoreDeliveredOrders event,
    Emitter<DeliveredOrdersState> emit,
  ) async {
    if (state.status == ApiStatus.success && !_hasReachedMax && !_isLoading) {
      _isLoading = true;
      try {
        List<Orders> currentOrders = List<Orders>.from(state.deliveredOrders);

        final response = await MyOrdersRepo().getDeliveredOrders(
          limit: _limit,
          offset: _offset,
          search: '',
        );

        final List<Orders> newOrders =
            (response['data']['orders'] as List<dynamic>?)
                ?.map((item) => Orders.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [];
        final int currentPage = response['data']['current_page'] as int;
        final int lastPage = response['data']['last_page'] as int;
        final int totalOrders = response['data']['total'] ?? 0;

        _offset += _limit;
        _hasReachedMax = currentPage >= lastPage;

        currentOrders.addAll(newOrders);

        if (response['success'] == true) {
          emit(
            state.copyWith(
              status: ApiStatus.success,
              deliveredOrders: currentOrders,
              hasReachedMax: _hasReachedMax,
              totalOrders: totalOrders,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: ApiStatus.failed,
              errorMessage:
                  response['message'] ??
                  'Failed to load settings delivered orders',
            ),
          );
        }
      } on ApiException catch (e) {
        emit(
          state.copyWith(status: ApiStatus.failed, errorMessage: "Error: $e"),
        );
      } catch (e) {
        if (kDebugMode) {}
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            errorMessage: "Unexpected error: $e",
          ),
        );
      } finally {
        _isLoading = false;
      }
    }
  }
}
