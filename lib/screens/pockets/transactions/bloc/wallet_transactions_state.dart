part of 'wallet_transactions_bloc.dart';

enum WalletTransactionsStatus { initial, loading, success, failure }

class WalletTransactionsState extends Equatable {
  final WalletTransactionsStatus status;
  final List<Transaction> transactions;
  final bool hasReachedMax;
  final String? errorMessage;
  final int currentPage;

  const WalletTransactionsState({
    this.status = WalletTransactionsStatus.initial,
    this.transactions = const [],
    this.hasReachedMax = false,
    this.errorMessage,
    this.currentPage = 1,
  });

  WalletTransactionsState copyWith({
    WalletTransactionsStatus? status,
    List<Transaction>? transactions,
    bool? hasReachedMax,
    String? errorMessage,
    int? currentPage,
  }) {
    return WalletTransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    hasReachedMax,
    errorMessage,
    currentPage,
  ];
}
