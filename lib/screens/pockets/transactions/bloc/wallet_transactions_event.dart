part of 'wallet_transactions_bloc.dart';

abstract class WalletTransactionsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchWalletTransactions extends WalletTransactionsEvent {
  final Completer<void>? completer;

  FetchWalletTransactions({this.completer});

  @override
  List<Object?> get props => [completer];
}

class FetchMoreWalletTransactions extends WalletTransactionsEvent {}
