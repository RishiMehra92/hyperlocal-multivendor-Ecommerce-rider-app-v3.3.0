import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/pockets/Transactions/repo/transaction_repo.dart';

import '../model/Transaction_model.dart';

part 'wallet_transactions_event.dart';
part 'wallet_transactions_state.dart';

class WalletTransactionsBloc
    extends Bloc<WalletTransactionsEvent, WalletTransactionsState> {
  WalletTransactionsBloc() : super(const WalletTransactionsState()) {
    on<FetchWalletTransactions>(_onFetchWalletTransactions);
    on<FetchMoreWalletTransactions>(_onFetchMoreWalletTransactions);
  }

  final repository = TransactionRepo();
  static const int _perPage = 10;

  /// ✅ Initial fetch - resets pagination
  Future<void> _onFetchWalletTransactions(
    FetchWalletTransactions event,
    Emitter<WalletTransactionsState> emit,
  ) async {
    if (state.transactions.isEmpty) {
      emit(
        state.copyWith(
          status: WalletTransactionsStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
      );
    } else {
      emit(state.copyWith(currentPage: 1, hasReachedMax: false));
    }

    try {
      final response = await repository.fetchWalletTransactions(
        page: 1,
        perPage: _perPage,
      );

      if (response['success'] == true) {
        final transactions = List<Transaction>.from(
          (response['data']['data'] as List).map(
            (data) => Transaction.fromJson(data),
          ),
        );

        final currentTotal = int.parse(
          response['data']['current_page'].toString(),
        );
        final lastPageNum = int.parse(response['data']['last_page'].toString());
        final hasReachedMax =
            currentTotal >= lastPageNum || transactions.length < _perPage;

        emit(
          state.copyWith(
            status: WalletTransactionsStatus.success,
            transactions: transactions,
            hasReachedMax: hasReachedMax,
            currentPage: 1,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: WalletTransactionsStatus.failure,
            errorMessage: response['message'],
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: WalletTransactionsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  /// ✅ Load more transactions
  Future<void> _onFetchMoreWalletTransactions(
    FetchMoreWalletTransactions event,
    Emitter<WalletTransactionsState> emit,
  ) async {
    if (state.hasReachedMax ||
        state.status == WalletTransactionsStatus.loading) {
      return;
    }

    try {
      final nextPage = state.currentPage + 1;

      final response = await repository.fetchWalletTransactions(
        page: nextPage,
        perPage: _perPage,
      );

      if (response['success'] == true) {
        final newTransactions = List<Transaction>.from(
          (response['data']['data'] as List).map(
            (data) => Transaction.fromJson(data),
          ),
        );

        final currentTotal = int.parse(
          response['data']['current_page'].toString(),
        );
        final lastPageNum = int.parse(response['data']['last_page'].toString());
        final hasReachedMax =
            currentTotal >= lastPageNum || newTransactions.length < _perPage;

        final updatedTransactions = List<Transaction>.from(state.transactions);

        for (final newTransaction in newTransactions) {
          if (!updatedTransactions.any(
            (existing) => existing.id == newTransaction.id,
          )) {
            updatedTransactions.add(newTransaction);
          }
        }

        emit(
          state.copyWith(
            status: WalletTransactionsStatus.success,
            transactions: updatedTransactions,
            hasReachedMax: hasReachedMax,
            currentPage: nextPage,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: WalletTransactionsStatus.failure,
            errorMessage: response['message'],
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: WalletTransactionsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
