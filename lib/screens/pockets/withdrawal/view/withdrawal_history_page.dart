import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/settings/bloc/profile_bloc/profile_bloc.dart';
import 'package:hyper_local/screens/settings/bloc/profile_bloc/profile_event.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';

import '../../../../config/colors.dart';
import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_scaffold.dart';
import '../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../../utils/widgets/loading_widget.dart';
import '../bloc/withdrawal_bloc.dart';
import '../bloc/withdrawal_event.dart';
import '../bloc/withdrawal_state.dart';
import '../model/withdrawal_model.dart';
import '../view/widgets/withdrawal_card.dart';
import '../view/widgets/create_withdrawal_sheet.dart';

class WithdrawalHistoryPage extends StatefulWidget {
  const WithdrawalHistoryPage({super.key});

  @override
  State<WithdrawalHistoryPage> createState() => _WithdrawalHistoryPageState();
}

class _WithdrawalHistoryPageState extends State<WithdrawalHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Fetch withdrawals when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WithdrawalBloc>().add(FetchWithdrawals());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (isBottom(_scrollController)) {
      context.read<WithdrawalBloc>().add(LoadMoreWithdrawals());
    }
  }

  void _showCreateWithdrawalDialog() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => const CreateWithdrawalSheet(),
    );

    if (result == true && mounted) {
      context.read<WithdrawalBloc>().add(FetchWithdrawals());
      context.read<ProfileBloc>().add(const LoadProfile());
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBar(
        title: context.tr('withdrawalHistory'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final completer = Completer<void>();
          context.read<WithdrawalBloc>().add(
            FetchWithdrawals(completer: completer),
          );
          await completer.future;
        },
        child: BlocConsumer<WithdrawalBloc, WithdrawalState>(
          listener: (context, state) {
            if (state.fetchStatus == ApiStatus.failed) {
              // Handle error if needed
            }
          },
          builder: (context, state) {
            if (state.fetchStatus == ApiStatus.loading &&
                state.response == null) {
              return const Center(child: LoadingWidget());
            } else if (state.fetchStatus == ApiStatus.success &&
                state.response != null) {
              return _buildWithdrawalsList(
                state.response!,
                state.isFetchingMore,
              );
            } else if (state.fetchStatus == ApiStatus.failed) {
              return ErrorStateWidget(
                onRetry: () {
                  context.read<WithdrawalBloc>().add(FetchWithdrawals());
                },
              );
              // return WithdrawalErrorState(errorMessage: state.errorMessage);
            } else {
              return EmptyStateWidget(
                title: context.tr('noWithdrawalsYet'),
                subtitle:
                    context.tr('noWithdrawalsYetDescription'),
                icon: Icons.account_balance_wallet_outlined,
                showRetryButton: false,
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'request-withdrawal',
        onPressed: _showCreateWithdrawalDialog,
        backgroundColor: AppColors.primaryColor,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onPrimary,
          size: sz(28, seprateTabletSize: 22).sp,
        ),
      ),
    );
  }

  Widget _buildWithdrawalsList(
    WithdrawalResponse response,
    bool isFetchingMore,
  ) {
    if (response.data?.data.isEmpty ?? true) {
      return EmptyStateWidget(
        title: context.tr('noWithdrawalsYet'),
        subtitle: context.tr('noWithdrawalsYetDescription'),
        icon: Icons.account_balance_wallet_outlined,
        showRetryButton: false,
      );
    }

    final withdrawals = response.data?.data ?? [];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: withdrawals.length + (isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == withdrawals.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: const Center(child: LoadingWidget()),
          );
        }
        final withdrawal = withdrawals[index];
        return WithdrawalCard(withdrawal: withdrawal);
      },
    );
  }
}
