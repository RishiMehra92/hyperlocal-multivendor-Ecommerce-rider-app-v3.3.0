import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import 'package:hyper_local/config/helper.dart';
import '../../../../utils/widgets/loading_widget.dart';
import '../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../../utils/widgets/custom_scaffold.dart';
import '../bloc/wallet_transactions_bloc.dart';
import '../widgets/empty_transaction_widget.dart';
import '../widgets/transaction_card.dart';

class ViewTransactionsPage extends StatefulWidget {
  const ViewTransactionsPage({super.key});

  @override
  State<ViewTransactionsPage> createState() => _ViewTransactionsPageState();
}

class _ViewTransactionsPageState extends State<ViewTransactionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<WalletTransactionsBloc>().add(FetchWalletTransactions());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBar(title: context.tr('transactions')),

      body: BlocBuilder<WalletTransactionsBloc, WalletTransactionsState>(
        builder: (BuildContext context, WalletTransactionsState state) {
          if (state.status == WalletTransactionsStatus.loading &&
              state.transactions.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          if (state.status == WalletTransactionsStatus.failure &&
              state.transactions.isEmpty) {
            return EmptyTransactionsState(
              onRetry: () {
                context.read<WalletTransactionsBloc>().add(
                  FetchWalletTransactions(),
                );
              },
            );
          }

          final transactions = state.transactions;
          final hasReachedMax = state.hasReachedMax;

          if (transactions.isEmpty) {
            return EmptyTransactionsState(
              onRetry: () {
                context.read<WalletTransactionsBloc>().add(
                  FetchWalletTransactions(),
                );
              },
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo is ScrollUpdateNotification &&
                  !hasReachedMax &&
                  isBottom(scrollInfo.metrics)) {
                context.read<WalletTransactionsBloc>().add(
                  FetchMoreWalletTransactions(),
                );
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () async {
                final completer = Completer<void>();
                context.read<WalletTransactionsBloc>().add(
                  FetchWalletTransactions(completer: completer),
                );
                await completer.future;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: transactions.length + (hasReachedMax ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index >= transactions.length) {
                    return const Center(child: LoadingWidget());
                  }

                  return TransactionCard(transaction: transactions[index]);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
