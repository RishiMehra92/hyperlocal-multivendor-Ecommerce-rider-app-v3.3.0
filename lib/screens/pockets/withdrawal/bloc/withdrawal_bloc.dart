import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/helper.dart';
import 'withdrawal_event.dart';
import 'withdrawal_state.dart';
import '../repo/withdrawal_repo.dart';
import '../model/withdrawal_model.dart';

class WithdrawalBloc extends Bloc<WithdrawalEvent, WithdrawalState> {
  final WithdrawalRepo _withdrawalRepo;

  WithdrawalBloc(this._withdrawalRepo) : super(const WithdrawalState()) {
    on<CreateWithdrawal>(_onCreateWithdrawal);
    on<FetchWithdrawals>(_onFetchWithdrawals);
    on<FetchWithdrawalById>(_onFetchWithdrawalById);
    on<LoadMoreWithdrawals>(_onLoadMoreWithdrawals);
  }

  Future<void> _onCreateWithdrawal(
    CreateWithdrawal event,
    Emitter<WithdrawalState> emit,
  ) async {
    emit(
      state.copyWith(createStatus: ApiStatus.loading, clearErrorMessage: true),
    );
    try {
      final request = CreateWithdrawalRequest(
        amount: event.amount,
        requestNote: event.note,
      );
      final response = await _withdrawalRepo.createWithdrawal(request);

      if (response['success'] == true) {
        emit(
          state.copyWith(
            createStatus: ApiStatus.success,
            createResponse: response,
          ),
        );
      } else {
        emit(
          state.copyWith(
            createStatus: ApiStatus.failed,
            errorMessage: response['message'] ?? 'Failed to create withdrawal',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          createStatus: ApiStatus.failed,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onFetchWithdrawals(
    FetchWithdrawals event,
    Emitter<WithdrawalState> emit,
  ) async {
    if (state.response == null) {
      emit(
        state.copyWith(fetchStatus: ApiStatus.loading, clearErrorMessage: true),
      );
    } else {
      emit(state.copyWith(clearErrorMessage: true));
    }
    try {
      final response = await _withdrawalRepo.getWithdrawals(
        perPage: 10,
        page: 1,
      );
      if (response['success'] == true) {
        try {
          final withdrawalResponse = WithdrawalResponse.fromJson(response);
          emit(
            state.copyWith(
              fetchStatus: ApiStatus.success,
              response: withdrawalResponse,
              currentPage: 1,
              hasReachedMax: (withdrawalResponse.data?.data.length ?? 0) < 10,
            ),
          );
        } catch (parseError) {
          emit(
            state.copyWith(
              fetchStatus: ApiStatus.failed,
              errorMessage: 'Data format error: Please contact support',
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            errorMessage: response['message'] ?? 'Failed to fetch withdrawals',
          ),
        );
      }
    } catch (error) {
      if (error.toString().contains(
            'Map<String, dynamic> is not a subtype of',
          ) ||
          error.toString().contains(
            'type \'String\' is not a subtype of type \'int\'',
          )) {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            errorMessage: 'Data format error: Please contact support',
          ),
        );
      } else {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            errorMessage: error.toString(),
          ),
        );
      }
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onFetchWithdrawalById(
    FetchWithdrawalById event,
    Emitter<WithdrawalState> emit,
  ) async {
    emit(
      state.copyWith(
        singleFetchStatus: ApiStatus.loading,
        clearErrorMessage: true,
      ),
    );
    try {
      final response = await _withdrawalRepo.getWithdrawalById(event.id);

      if (response['success'] == true) {
        try {
          final singleWithdrawalResponse = SingleWithdrawalResponse.fromJson(
            response,
          );

          emit(
            state.copyWith(
              singleFetchStatus: ApiStatus.success,
              singleResponse: singleWithdrawalResponse,
            ),
          );
        } catch (parseError) {
          emit(
            state.copyWith(
              singleFetchStatus: ApiStatus.failed,
              errorMessage: 'Data format error: Please contact support',
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            singleFetchStatus: ApiStatus.failed,
            errorMessage:
                response['message'] ?? 'Failed to fetch withdrawal details',
          ),
        );
      }
    } catch (error) {
      if (error.toString().contains(
            'Map<String, dynamic> is not a subtype of',
          ) ||
          error.toString().contains(
            'type \'String\' is not a subtype of type \'int\'',
          )) {
        emit(
          state.copyWith(
            singleFetchStatus: ApiStatus.failed,
            errorMessage: 'Data format error: Please contact support',
          ),
        );
      } else {
        emit(
          state.copyWith(
            singleFetchStatus: ApiStatus.failed,
            errorMessage: error.toString(),
          ),
        );
      }
    }
  }

  Future<void> _onLoadMoreWithdrawals(
    LoadMoreWithdrawals event,
    Emitter<WithdrawalState> emit,
  ) async {
    try {
      if (state.fetchStatus == ApiStatus.success && state.response != null) {
        final currentState = state;
        if (currentState.hasReachedMax || currentState.isFetchingMore) return;

        emit(currentState.copyWith(isFetchingMore: true));

        final response = await _withdrawalRepo.getWithdrawals(
          perPage: 10,
          page: currentState.currentPage + 1,
        );

        if (response['success'] == true) {
          final withdrawalResponse = WithdrawalResponse.fromJson(response);
          final newWithdrawals = withdrawalResponse.data?.data ?? [];

          if (newWithdrawals.isEmpty) {
            emit(
              currentState.copyWith(isFetchingMore: false, hasReachedMax: true),
            );
          } else {
            final updatedWithdrawals = List<WithdrawalModel>.from(
              currentState.response!.data?.data ?? [],
            )..addAll(newWithdrawals);

            emit(
              currentState.copyWith(
                isFetchingMore: false,
                currentPage: currentState.currentPage + 1,
                hasReachedMax: newWithdrawals.length < 10,
                response: WithdrawalResponse(
                  success: withdrawalResponse.success,
                  message: withdrawalResponse.message,
                  data: WithdrawalPaginationData(
                    currentPage: withdrawalResponse.data!.currentPage,
                    data: updatedWithdrawals,
                    firstPageUrl: withdrawalResponse.data!.firstPageUrl,
                    from: withdrawalResponse.data?.from,
                    lastPage: withdrawalResponse.data!.lastPage,
                    lastPageUrl: withdrawalResponse.data!.lastPageUrl,
                    links: withdrawalResponse.data!.links,
                    nextPageUrl: withdrawalResponse.data?.nextPageUrl,
                    path: withdrawalResponse.data!.path,
                    perPage: withdrawalResponse.data!.perPage,
                    prevPageUrl: withdrawalResponse.data?.prevPageUrl,
                    to: withdrawalResponse.data?.to,
                    total: withdrawalResponse.data!.total,
                  ),
                ),
              ),
            );
          }
        } else {
          emit(currentState.copyWith(isFetchingMore: false));
        }
      }
    } catch (e) {
      // Potentially silent or show minimal error for "load more"
    }
  }
}
