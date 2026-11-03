import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../config/api_base_helper.dart';
import '../../../../config/helper.dart';

import '../../model/available_orders.dart';
import '../../repo/available_orders.dart';

import 'available_orders_event.dart';
import 'available_orders_state.dart';

class AvailableOrdersBloc
    extends Bloc<AvailableOrdersEvent, AvailableOrdersState> {
  int _currentPage = 1;
  final int _limit = 10;
  bool _hasReachedMax = false;

  AvailableOrdersBloc() : super(const AvailableOrdersState()) {
    on<AllAvailableOrdersList>(_onAllAvailableOrders);
    on<SearchAvailableOrders>(_onSearchAvailableOrders);
    on<LoadMoreAvailableOrders>(_onLoadMoreAvailableOrders);
  }

  Future<void> _onAllAvailableOrders(
    AllAvailableOrdersList event,
    Emitter<AvailableOrdersState> emit,
  ) async {
    // If already loading or refreshing, ignore duplicate calls UNLESS forceRefresh is true
    if ((state.fetchStatus == ApiStatus.loading || state.isRefreshing) &&
        !event.forceRefresh) {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
      return;
    }

    try {
      // Only load if we don't have data or if explicitly requested
      if (state.fetchStatus == ApiStatus.success) {
        // If we already have data, don't reload unless it's a manual refresh
        if (!event.forceRefresh) {
          if (event.completer != null && !event.completer!.isCompleted) {
            event.completer!.complete();
          }
          return; // Keep existing data
        }
        emit(state.copyWith(isRefreshing: true));
      } else {
        emit(state.copyWith(fetchStatus: ApiStatus.loading));
      }

      _currentPage = 1;
      _hasReachedMax = false;

      final response = await AvailableOrdersRepo().availableOrdersList(
        limit: _limit,
        offset: (_currentPage - 1) * _limit,
        search: '',
      );

      final List<Orders> orders =
          (response['data']['orders'] as List<dynamic>?)
              ?.map((item) => Orders.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      final int responseCurrentPage = response['data']['current_page'] as int;
      final int responseLastPage = response['data']['last_page'] as int;

      _hasReachedMax = responseCurrentPage >= responseLastPage;
      if (!_hasReachedMax) {
        _currentPage = responseCurrentPage + 1;
      }

      if (response['success'] == true) {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.success,
            availableOrders: orders,
            hasReachedMax: _hasReachedMax,
            totalOrders: response['data']['total'] as int,
            isRefreshing: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            message: response['message'],
            isRefreshing: false,
          ),
        );
      }
    } on ApiException catch (e) {
      if (kDebugMode) {}
      emit(
        state.copyWith(
          fetchStatus: ApiStatus.failed,
          message: "Error: $e",
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {}
      emit(
        state.copyWith(
          fetchStatus: ApiStatus.failed,
          message: "Unexpected error: $e",
          isRefreshing: false,
        ),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onSearchAvailableOrders(
    SearchAvailableOrders event,
    Emitter<AvailableOrdersState> emit,
  ) async {
    try {
      emit(state.copyWith(fetchStatus: ApiStatus.loading));
      _currentPage = 1;
      _hasReachedMax = false;

      final response = await AvailableOrdersRepo().availableOrdersList(
        limit: _limit,
        offset: (_currentPage - 1) * _limit,
        search: event.searchQuery,
      );

      final List<Orders> orders =
          (response['data']['orders'] as List<dynamic>?)
              ?.map((item) => Orders.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      final int responseCurrentPage = response['data']['current_page'] as int;
      final int responseLastPage = response['data']['last_page'] as int;

      _hasReachedMax = responseCurrentPage >= responseLastPage;
      if (!_hasReachedMax) {
        _currentPage = responseCurrentPage + 1;
      }

      if (response['success'] == true) {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.success,
            availableOrders: orders,
            hasReachedMax: _hasReachedMax,
            totalOrders: response['data']['total'] as int,
          ),
        );
      } else {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            message: response['message'],
          ),
        );
      }
    } on ApiException catch (e) {
      emit(state.copyWith(fetchStatus: ApiStatus.failed, message: "Error: $e"));
    } catch (e) {
      if (kDebugMode) {}
      emit(
        state.copyWith(
          fetchStatus: ApiStatus.failed,
          message: "Unexpected error: $e",
        ),
      );
    }
  }

  Future<void> _onLoadMoreAvailableOrders(
    LoadMoreAvailableOrders event,
    Emitter<AvailableOrdersState> emit,
  ) async {
    // Drop queued events if another pagination request already modified the list
    if (event.currentLength > 0 &&
        state.availableOrders.length != event.currentLength) {
      return;
    }

    if (state.isPaginating) return;

    if (state.fetchStatus == ApiStatus.success && !_hasReachedMax) {
      emit(state.copyWith(isPaginating: true));
      try {
        List<Orders> currentOrders = List<Orders>.from(state.availableOrders);

        final response = await AvailableOrdersRepo().availableOrdersList(
          limit: _limit,
          offset: (_currentPage - 1) * _limit,
          search: '',
        );

        final List<Orders> newOrders =
            (response['data']['orders'] as List<dynamic>?)
                ?.map((item) => Orders.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [];
        final int responseCurrentPage = response['data']['current_page'] as int;
        final int responseLastPage = response['data']['last_page'] as int;

        _hasReachedMax = responseCurrentPage >= responseLastPage;
        if (!_hasReachedMax) {
          _currentPage = responseCurrentPage + 1;
        }

        currentOrders.addAll(newOrders);

        if (response['success'] == true) {
          emit(
            state.copyWith(
              fetchStatus: ApiStatus.success,
              availableOrders: currentOrders,
              hasReachedMax: _hasReachedMax,
              totalOrders: response['data']['total'] as int,
              isPaginating: false,
            ),
          );
        } else {
          emit(
            state.copyWith(
              fetchStatus: ApiStatus.failed,
              message: response['message'],
              isPaginating: false,
            ),
          );
        }
      } on ApiException catch (e) {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            message: "Error: $e",
            isPaginating: false,
          ),
        );
      } catch (e) {
        if (kDebugMode) {}
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            message: "Unexpected error: $e",
            isPaginating: false,
          ),
        );
      }
    }
  }
}
