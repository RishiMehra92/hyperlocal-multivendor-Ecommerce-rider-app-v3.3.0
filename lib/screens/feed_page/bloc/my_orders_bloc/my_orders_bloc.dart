import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../config/api_base_helper.dart';
import 'package:hyper_local/config/helper.dart';

import '../../model/available_orders.dart';
import '../../repo/my_orders.dart';

import 'my_orders_event.dart';
import 'my_orders_state.dart';

class MyOrdersBloc extends Bloc<MyOrdersEvent, MyOrdersState> {
  int _offset = 0;
  final int _limit = 10;
  bool _hasReachedMax = false;
  bool _isLoading = false;
  String _selectedFilter = 'all';

  MyOrdersBloc() : super(const MyOrdersState()) {
    on<AllMyOrdersList>(_onAllMyOrders);
    on<SearchMyOrders>(_onSearchMyOrders);
    on<LoadMoreMyOrders>(_onLoadMoreMyOrders);
  }

  Future<void> _onAllMyOrders(
    AllMyOrdersList event,
    Emitter<MyOrdersState> emit,
  ) async {
    final String newFilter = event.type ?? _selectedFilter;
    final bool isFilterChanged = newFilter != state.selectedFilter;

    // If already loading or refreshing the same filter, ignore duplicate calls (unless forceRefresh is true)
    if ((state.status == ApiStatus.loading || state.isRefreshing) &&
        !isFilterChanged &&
        !event.forceRefresh) {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
      return;
    }

    if (event.type != null) {
      _selectedFilter = event.type!;
    }
    final String filterType = _selectedFilter;
    try {
      if (isFilterChanged) {
        emit(
          state.copyWith(
            status: ApiStatus.loading,
            myOrders: const [],
            totalOrders: 0,
            selectedFilter: _selectedFilter,
            isRefreshing: false,
          ),
        );
      } else if (state.status == ApiStatus.success) {
        emit(
          state.copyWith(isRefreshing: true, selectedFilter: _selectedFilter),
        );
      } else {
        emit(state.copyWith(status: ApiStatus.loading));
      }
      _offset = 0;
      _hasReachedMax = false;

      final response = await MyOrdersRepo().myOrdersList(
        limit: _limit,
        offset: _offset,
        search: '',
        status: filterType == 'all' ? null : filterType,
      );

      // Check if response has error
      if (response['error'] != null) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: 'API Error: ${response['error']}',
            isRefreshing: false,
          ),
        );
        return;
      }

      // Check if response has data
      if (response['data'] == null) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: 'No data received from API',
            isRefreshing: false,
          ),
        );
        return;
      }

      // Safely extract orders with null checks
      final ordersData = response['data']['orders'];
      if (ordersData == null) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: 'Orders data not found',
            isRefreshing: false,
          ),
        );
        return;
      }

      final List<Orders> orders =
          (ordersData as List<dynamic>?)
              ?.map((item) {
                try {
                  if (item == null) {
                    return null;
                  }
                  return Orders.fromJson(item as Map<String, dynamic>);
                } catch (e) {
                  return null;
                }
              })
              .where((order) => order != null) // Filter out null orders
              .cast<Orders>()
              .toList() ??
          [];

      // Safely extract pagination data with null checks
      final currentPage = response['data']['current_page'];
      final lastPage = response['data']['last_page'];
      final totalOrders = response['data']['total'] ?? 0;

      if (currentPage == null || lastPage == null) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: 'Pagination data incomplete',
            isRefreshing: false,
          ),
        );
        return;
      }

      final int currentPageInt = currentPage as int;
      final int lastPageInt = lastPage as int;
      final int totalOrdersInt = totalOrders as int;

      _offset += _limit;
      _hasReachedMax = currentPageInt >= lastPageInt;

      if (response['success'] == true) {
        emit(
          state.copyWith(
            status: ApiStatus.success,
            myOrders: orders,
            hasReachedMax: _hasReachedMax,
            totalOrders: totalOrdersInt,
            selectedFilter: _selectedFilter,
            isRefreshing: false,
          ),
        );
      } else {
        final errorMessage = response['message'] ?? 'Unknown error occurred';

        // Don't increment offset on error, so we can retry the same page
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: errorMessage,
            isRefreshing: false,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "API Error: $e",
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {}
      emit(
        state.copyWith(
          status: ApiStatus.failed,
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

  Future<void> _onSearchMyOrders(
    SearchMyOrders event,
    Emitter<MyOrdersState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ApiStatus.loading));
      _offset = 0;
      _hasReachedMax = false;

      final response = await MyOrdersRepo().myOrdersList(
        limit: _limit,
        offset: _offset,
        search: event.searchQuery,
      );

      // Check if response has error
      if (response['error'] != null) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: 'API Error: ${response['error']}',
          ),
        );
        return;
      }

      // Check if response has data
      if (response['data'] == null) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: 'No data received from API',
          ),
        );
        return;
      }

      // Safely extract orders with null checks
      final ordersData = response['data']['orders'];
      if (ordersData == null) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: 'Orders data not found',
          ),
        );
        return;
      }

      final List<Orders> orders =
          (ordersData as List<dynamic>?)
              ?.map((item) {
                try {
                  if (item == null) {
                    return null;
                  }
                  return Orders.fromJson(item as Map<String, dynamic>);
                } catch (e) {
                  return null;
                }
              })
              .where((order) => order != null) // Filter out null orders
              .cast<Orders>()
              .toList() ??
          [];

      // Safely extract pagination data with null checks
      final currentPage = response['data']['current_page'];
      final lastPage = response['data']['last_page'];
      final totalOrders = response['data']['total'] ?? 0;

      if (currentPage == null || lastPage == null) {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: 'Pagination data incomplete',
          ),
        );
        return;
      }

      final int currentPageInt = currentPage as int;
      final int lastPageInt = lastPage as int;
      final int totalOrdersInt = totalOrders as int;

      _hasReachedMax = currentPageInt >= lastPageInt;

      if (response['success'] == true) {
        emit(
          state.copyWith(
            status: ApiStatus.success,
            myOrders: orders,
            hasReachedMax: _hasReachedMax,
            totalOrders: totalOrdersInt,
            selectedFilter: _selectedFilter,
          ),
        );
      } else {
        final errorMessage = response['message'] ?? 'Unknown error occurred';

        // Don't increment offset on error, so we can retry the same page
        emit(state.copyWith(status: ApiStatus.failed, message: errorMessage));
      }
    } on ApiException catch (e) {
      emit(state.copyWith(status: ApiStatus.failed, message: "API Error: $e"));
    } catch (e) {
      if (kDebugMode) {}
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: "Unexpected error: $e",
        ),
      );
    }
  }

  Future<void> _onLoadMoreMyOrders(
    LoadMoreMyOrders event,
    Emitter<MyOrdersState> emit,
  ) async {
    if (state.status == ApiStatus.success && !_hasReachedMax && !_isLoading) {
      _isLoading = true;
      try {
        List<Orders> currentOrders = List<Orders>.from(state.myOrders);

        final response = await MyOrdersRepo().myOrdersList(
          limit: _limit,
          offset: _offset,
          search: '',
          status: event.currentFilter == 'all' ? null : event.currentFilter,
        );

        // Check if response has error
        if (response['error'] != null) {
          emit(
            state.copyWith(
              status: ApiStatus.failed,
              message: 'API Error: ${response['error']}',
            ),
          );
          return;
        }

        // Check if response has data
        if (response['data'] == null) {
          emit(
            state.copyWith(
              status: ApiStatus.failed,
              message: 'No data received from API',
            ),
          );
          return;
        }

        // Safely extract orders with null checks
        final ordersData = response['data']['orders'];
        if (ordersData == null) {
          emit(
            state.copyWith(
              status: ApiStatus.failed,
              message: 'Orders data not found',
            ),
          );
          return;
        }

        final List<Orders> newOrders =
            (ordersData as List<dynamic>?)
                ?.map((item) {
                  try {
                    if (item == null) {
                      return null;
                    }
                    return Orders.fromJson(item as Map<String, dynamic>);
                  } catch (e) {
                    return null;
                  }
                })
                .where((order) => order != null) // Filter out null orders
                .cast<Orders>()
                .toList() ??
            [];

        // Safely extract pagination data with null checks
        final currentPage = response['data']['current_page'];
        final lastPage = response['data']['last_page'];
        final totalOrders = response['data']['total'] ?? 0;

        if (currentPage == null || lastPage == null) {
          emit(
            state.copyWith(
              status: ApiStatus.failed,
              message: 'Pagination data incomplete',
            ),
          );
          return;
        }

        final int currentPageInt = currentPage as int;
        final int lastPageInt = lastPage as int;
        final int totalOrdersInt = totalOrders as int;

        _offset += _limit;
        // Check if we've reached the last page
        _hasReachedMax = currentPageInt >= lastPageInt;

        currentOrders.addAll(newOrders);

        if (response['success'] == true) {
          emit(
            state.copyWith(
              status: ApiStatus.success,
              myOrders: currentOrders,
              hasReachedMax: _hasReachedMax,
              totalOrders: totalOrdersInt,
              selectedFilter: _selectedFilter,
            ),
          );
        } else {
          final errorMessage = response['message'] ?? 'Unknown error occurred';
          emit(state.copyWith(status: ApiStatus.failed, message: errorMessage));
        }
      } on ApiException catch (e) {
        emit(
          state.copyWith(status: ApiStatus.failed, message: "API Error: $e"),
        );
      } catch (e) {
        if (kDebugMode) {}
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: "Unexpected error: $e",
          ),
        );
      } finally {
        _isLoading = false;
      }
    }
  }
}
