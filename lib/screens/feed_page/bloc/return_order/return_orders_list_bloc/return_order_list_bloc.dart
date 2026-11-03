// ignore_for_file: empty_catches

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/feed_page/model/return_orders_list_model.dart';
import 'package:hyper_local/screens/feed_page/repo/return_order_repo.dart';

import 'return_order_list_event.dart';
import 'return_order_list_state.dart';

class ReturnOrderListBloc
    extends Bloc<ReturnOrderListEvent, ReturnOrderListState> {
  final ReturnOrderRepo _repo = ReturnOrderRepo();

  int _offset = 0;
  final int _limit = 10;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  ReturnOrderListBloc() : super(const ReturnOrderListState()) {
    on<FetchReturnOrders>(_onFetchReturnOrders);
    on<LoadMoreReturnOrders>(_onLoadMoreReturnOrders);
  }

  Future<void> _onFetchReturnOrders(
    FetchReturnOrders event,
    Emitter<ReturnOrderListState> emit,
  ) async {
    // If already loading or refreshing, ignore duplicate calls
    if (state.status == ApiStatus.loading || state.isRefreshing) {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
      return;
    }

    // If not force refresh and already loaded → do nothing (pull-to-refresh protection)

    if (!event.forceRefresh && state.status == ApiStatus.success) {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
      return;
    }

    if (event.forceRefresh && state.status == ApiStatus.success) {
      emit(state.copyWith(isRefreshing: true));
    } else {
      emit(state.copyWith(status: ApiStatus.loading));
    }

    _offset = 0;
    _hasReachedMax = false;

    try {
      final response = await _repo.getReturnOrder(
        limit: _limit,
        offset: _offset,
      );

      if (response['success'] != true) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: response['message'] ?? 'Failed to load return orders',
            isRefreshing: false,
          ),
        );
        return;
      }

      final data = response['data'];
      final pickupsJson = data['pickups'] as List<dynamic>? ?? [];
      final orders =
          pickupsJson
              .map((json) => Pickups.fromJson(json as Map<String, dynamic>))
              .toList();

      final int totalOrders = data['total'] ?? 0;
      final int currentPage = data['current_page'] ?? 1;
      final int lastPage = data['last_page'] ?? 1;
      _hasReachedMax = currentPage >= lastPage;

      _offset += _limit;

      emit(
        state.copyWith(
          orders: orders,
          hasReachedMax: _hasReachedMax,
          totalOrders: totalOrders,
          status: ApiStatus.success,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {}

      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: e.toString(),
          isRefreshing: false,
        ),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onLoadMoreReturnOrders(
    LoadMoreReturnOrders event,
    Emitter<ReturnOrderListState> emit,
  ) async {
    if (_isLoadingMore || _hasReachedMax || state.status != ApiStatus.success) {
      return;
    }

    _isLoadingMore = true;

    try {
      final currentOrders = List<Pickups>.from(state.orders);

      final response = await _repo.getReturnOrder(
        limit: _limit,
        offset: _offset,
      );

      if (response['success'] != true) {
        // Don't change state on error during load more (or show snackbar via event)
        return;
      }

      final pickupsJson = response['data']['pickups'] as List<dynamic>? ?? [];
      final newOrders =
          pickupsJson
              .map((json) => Pickups.fromJson(json as Map<String, dynamic>))
              .toList();

      final int totalOrders = response['data']['total'] ?? 0;
      final int currentPage = response['data']['current_page'] ?? 1;
      final int lastPage = response['data']['last_page'] ?? 1;
      _hasReachedMax = currentPage >= lastPage;
      _offset += _limit;

      currentOrders.addAll(newOrders);

      emit(
        state.copyWith(
          status: ApiStatus.success,
          orders: currentOrders,
          totalOrders: totalOrders,
          hasReachedMax: _hasReachedMax,
        ),
      );
    } catch (e) {
    } finally {
      _isLoadingMore = false;
    }
  }
}
