import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/feed_page/model/return_orders_list_model.dart';
import 'package:hyper_local/screens/feed_page/repo/return_order_repo.dart';

part 'pickup_order_list_event.dart';
part 'pickup_order_list_state.dart';

class PickupOrderListBloc
    extends Bloc<PickupOrderListEvent, PickupOrderListState> {
  final ReturnOrderRepo _repo = ReturnOrderRepo();

  int _offset = 0;
  final int _limit = 10;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  PickupOrderListBloc() : super(const PickupOrderListState()) {
    on<FetchPickupOrders>(_onFetchPickupOrders);
    on<LoadMorePickupOrders>(_onLoadMorePickupOrders);
  }

  Future<void> _onFetchPickupOrders(
    FetchPickupOrders event,
    Emitter<PickupOrderListState> emit,
  ) async {
    final statusFilter = event.status ?? state.selectedFilter;
    final isNewStatus =
        event.status != null && event.status != state.selectedFilter;

    if (!event.forceRefresh &&
        !isNewStatus &&
        state.status == ApiStatus.success) {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
      return;
    }

    if (isNewStatus) {
      emit(
        state.copyWith(
          status: ApiStatus.loading,
          orders: [],
          selectedFilter: statusFilter,
        ),
      );
    } else if (event.forceRefresh && state.status == ApiStatus.success) {
      emit(state.copyWith(isRefreshing: true, selectedFilter: statusFilter));
    } else {
      emit(
        state.copyWith(status: ApiStatus.loading, selectedFilter: statusFilter),
      );
    }

    _offset = 0;
    _hasReachedMax = false;

    try {
      final response = await _repo.getReturnPickups(
        limit: _limit,
        offset: _offset,
        status: statusFilter,
      );

      if (response['success'] != true) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: response['message'] ?? 'Failed to load pickup orders',
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

      final int currentPage = data['current_page'] ?? 1;
      final int lastPage = data['last_page'] ?? 1;
      final int totalOrders = data['total'] ?? 0;
      _hasReachedMax = currentPage >= lastPage;
      _offset += _limit;

      emit(
        state.copyWith(
          status: ApiStatus.success,
          orders: orders,
          hasReachedMax: _hasReachedMax,
          totalOrders: totalOrders,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: e.toString(),
            isRefreshing: false,
          ),
        );
      }
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onLoadMorePickupOrders(
    LoadMorePickupOrders event,
    Emitter<PickupOrderListState> emit,
  ) async {
    if (_isLoadingMore || _hasReachedMax || state.status != ApiStatus.success) {
      return;
    }

    _isLoadingMore = true;

    try {
      final currentOrders = List<Pickups>.from(state.orders);

      final response = await _repo.getReturnPickups(
        limit: _limit,
        offset: _offset,
        status: state.selectedFilter,
      );

      if (response['success'] != true) return;

      final pickupsJson = response['data']['pickups'] as List<dynamic>? ?? [];
      final newOrders =
          pickupsJson
              .map((json) => Pickups.fromJson(json as Map<String, dynamic>))
              .toList();

      final int currentPage = response['data']['current_page'] ?? 1;
      final int lastPage = response['data']['last_page'] ?? 1;
      final int totalOrders = response['data']['total'] ?? 0;
      _hasReachedMax = currentPage >= lastPage;
      _offset += _limit;

      currentOrders.addAll(newOrders);

      emit(
        state.copyWith(
          status: ApiStatus.success,
          orders: currentOrders,
          hasReachedMax: _hasReachedMax,
          totalOrders: totalOrders,
        ),
      );
    } catch (e) {
      //
    } finally {
      _isLoadingMore = false;
    }
  }
}
