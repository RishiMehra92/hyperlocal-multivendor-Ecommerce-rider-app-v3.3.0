import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/pockets/cash_collection/model/cash_collection_model.dart';
import '../repo/cash_collection_repo.dart';
import 'cash_collection_event.dart';
import 'cash_collection_state.dart';

class CashCollectionBloc
    extends Bloc<CashCollectionEvent, CashCollectionState> {
  final CashCollectionRepo _cashCollectionRepo;

  CashCollectionBloc(this._cashCollectionRepo)
    : super(const CashCollectionState()) {
    on<FetchCashCollection>(_onFetchCashCollection);
    on<FetchCashCollectionStats>(_onFetchCashCollectionStats);
    on<FetchCashCollectionByDateRange>(_onFetchCashCollectionByDateRange);
    on<FetchLast30Minutes>(_onFetchLast30Minutes);
    on<FetchLast1Hour>(_onFetchLast1Hour);
    on<FetchLast5Hours>(_onFetchLast5Hours);
    on<FetchLast1Day>(_onFetchLast1Day);
    on<FetchLast7Days>(_onFetchLast7Days);
    on<FetchLast30Days>(_onFetchLast30Days);
    on<FetchLast365Days>(_onFetchLast365Days);
    on<LoadMoreCashCollection>(_onLoadMoreCashCollection);
    on<SettleOnlineEvent>(_onSettleOnline);
    on<ResetSettleStatusEvent>((event, emit) {
      emit(
        state.copyWith(settleStatus: ApiStatus.initial, clearCheckoutUrl: true),
      );
    });
  }

  Future<void> _onFetchCashCollection(
    FetchCashCollection event,
    Emitter<CashCollectionState> emit,
  ) async {
    try {
      if (state.response == null) {
        emit(
          state.copyWith(fetchStatus: ApiStatus.loading, clearMessage: true),
        );
      } else {
        emit(state.copyWith(clearMessage: true));
      }
      final response = await _cashCollectionRepo.getCashCollection(
        dateRange: event.dateRange,
        perPage: 10,
        page: 1,
      );
      emit(
        state.copyWith(
          fetchStatus: ApiStatus.success,
          response: response,
          selectedDateRange: event.dateRange ?? 'all',
          currentPage: 1,
          hasReachedMax: (response.data?.cashCollections?.length ?? 0) < 10,
          submissionStatus: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(fetchStatus: ApiStatus.failed, message: e.toString()),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onFetchCashCollectionStats(
    FetchCashCollectionStats event,
    Emitter<CashCollectionState> emit,
  ) async {
    try {
      emit(
        state.copyWith(statsFetchStatus: ApiStatus.loading, clearMessage: true),
      );
      final response = await _cashCollectionRepo.getCashCollectionStats();
      emit(
        state.copyWith(
          statsFetchStatus: ApiStatus.success,
          statsResponse: response,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          statsFetchStatus: ApiStatus.failed,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onFetchCashCollectionByDateRange(
    FetchCashCollectionByDateRange event,
    Emitter<CashCollectionState> emit,
  ) async {
    try {
      if (event.completer == null) {
        emit(
          state.copyWith(fetchStatus: ApiStatus.loading, clearMessage: true),
        );
      } else {
        emit(state.copyWith(clearMessage: true));
      }
      final response = await _cashCollectionRepo.getCashCollection(
        dateRange: event.dateRange,
        submissionStatus: event.submissionStatus,
        perPage: 10,
        page: 1,
      );
      emit(
        state.copyWith(
          fetchStatus: ApiStatus.success,
          response: response,
          selectedDateRange: event.dateRange,
          submissionStatus: event.submissionStatus,
          currentPage: 1,
          hasReachedMax: (response.data?.cashCollections?.length ?? 0) < 10,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(fetchStatus: ApiStatus.failed, message: e.toString()),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onFetchLast30Minutes(
    FetchLast30Minutes event,
    Emitter<CashCollectionState> emit,
  ) async {
    add(FetchCashCollectionByDateRange('last_30_minutes'));
  }

  Future<void> _onFetchLast1Hour(
    FetchLast1Hour event,
    Emitter<CashCollectionState> emit,
  ) async {
    add(FetchCashCollectionByDateRange('last_1_hour'));
  }

  Future<void> _onFetchLast5Hours(
    FetchLast5Hours event,
    Emitter<CashCollectionState> emit,
  ) async {
    add(FetchCashCollectionByDateRange('last_5_hours'));
  }

  Future<void> _onFetchLast1Day(
    FetchLast1Day event,
    Emitter<CashCollectionState> emit,
  ) async {
    add(FetchCashCollectionByDateRange('last_1_day'));
  }

  Future<void> _onFetchLast7Days(
    FetchLast7Days event,
    Emitter<CashCollectionState> emit,
  ) async {
    add(FetchCashCollectionByDateRange('last_7_days'));
  }

  Future<void> _onFetchLast30Days(
    FetchLast30Days event,
    Emitter<CashCollectionState> emit,
  ) async {
    add(FetchCashCollectionByDateRange('last_30_days'));
  }

  Future<void> _onFetchLast365Days(
    FetchLast365Days event,
    Emitter<CashCollectionState> emit,
  ) async {
    add(FetchCashCollectionByDateRange('last_365_days'));
  }

  Future<void> _onLoadMoreCashCollection(
    LoadMoreCashCollection event,
    Emitter<CashCollectionState> emit,
  ) async {
    try {
      if (state.fetchStatus == ApiStatus.success && state.response != null) {
        final currentState = state;
        if (currentState.hasReachedMax || currentState.isFetchingMore) return;

        emit(currentState.copyWith(isFetchingMore: true));

        final response = await _cashCollectionRepo.getCashCollection(
          dateRange: currentState.selectedDateRange,
          submissionStatus: currentState.submissionStatus,
          perPage: 10,
          page: currentState.currentPage + 1,
        );

        final newCollections = response.data?.cashCollections ?? [];
        if (newCollections.isEmpty) {
          emit(
            currentState.copyWith(isFetchingMore: false, hasReachedMax: true),
          );
        } else {
          final updatedCollections = List<CashCollectionModel>.from(
            currentState.response!.data?.cashCollections ?? [],
          )..addAll(newCollections);

          emit(
            currentState.copyWith(
              isFetchingMore: false,
              currentPage: currentState.currentPage + 1,
              hasReachedMax: newCollections.length < 10,
              response: CashCollectionResponse(
                success: response.success,
                message: response.message,
                data: CashCollectionData(
                  total: response.data?.total,
                  perPage: response.data?.perPage,
                  currentPage: response.data?.currentPage,
                  lastPage: response.data?.lastPage,
                  cashCollections: updatedCollections,
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Potentially silent or show minimal error for "load more"
    }
  }

  Future<void> _onSettleOnline(
    SettleOnlineEvent event,
    Emitter<CashCollectionState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          settleStatus: ApiStatus.loading,
          settleCollectionIds: event.collectionIds,
          clearCheckoutUrl: true,
          clearMessage: true,
        ),
      );

      final response = await _cashCollectionRepo.settleOnline(
        event.collectionIds,
      );

      final data = response['data'];
      final checkoutUrl =
          data != null ? (data['payment_link'] ?? data['checkout_url']) : null;

      if (response['success'] == true && checkoutUrl != null) {
        emit(
          state.copyWith(
            settleStatus: ApiStatus.success,
            checkoutUrl: checkoutUrl as String,
          ),
        );
      } else {
        final errorMessage =
            response['message'] ?? 'Failed to initiate payment session';
        emit(
          state.copyWith(settleStatus: ApiStatus.failed, message: errorMessage),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(settleStatus: ApiStatus.failed, message: e.toString()),
      );
    }
  }
}
