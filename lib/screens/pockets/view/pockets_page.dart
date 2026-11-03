// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/settings/bloc/profile_bloc/profile_bloc.dart';
import 'package:hyper_local/screens/settings/bloc/profile_bloc/profile_state.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import '../../../utils/widgets/custom_card.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../settings/bloc/profile_bloc/profile_event.dart';
import '../earnings/bloc/earnings_bloc.dart';
import '../earnings/bloc/earnings_event.dart';
import '../earnings/bloc/earnings_state.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../../../utils/widgets/loading_widget.dart';
import '../widgets/pockets_widgets.dart';
import '../Transactions/bloc/wallet_transactions_bloc.dart';
import '../Transactions/widgets/transaction_card.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/utils/currency_formatter.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_event.dart';

class PocketsPage extends StatefulWidget {
  const PocketsPage({super.key});

  @override
  State<PocketsPage> createState() => _PocketsPageState();
}

class _PocketsPageState extends State<PocketsPage> {
  @override
  void initState() {
    super.initState();

    // Initial API fetches using global shell providers
    context.read<EarningsBloc>().add(FetchEarningsStats());
    context.read<ProfileBloc>().add(const LoadProfile());
    context.read<DeliveryBoyStatusBloc>().add(const CheckApiStatus());
    context.read<WalletTransactionsBloc>().add(FetchWalletTransactions());
    context.read<SystemSettingsBloc>().add(FetchSystemSettings());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync with current delivery boy status when page becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryBoyStatusBloc>().add(const CheckApiStatus());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final earningsCompleter = Completer<void>();
          final profileCompleter = Completer<void>();
          final transactionsCompleter = Completer<void>();
          context.read<EarningsBloc>().add(
            FetchEarningsStats(completer: earningsCompleter),
          );
          context.read<ProfileBloc>().add(
            LoadProfile(completer: profileCompleter),
          );
          context.read<WalletTransactionsBloc>().add(
            FetchWalletTransactions(completer: transactionsCompleter),
          );
          await Future.wait([
            earningsCompleter.future,
            profileCompleter.future,
            transactionsCompleter.future,
          ]);
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, profileState) {
            return BlocBuilder<EarningsBloc, EarningsState>(
              builder: (context, earningsState) {
                final profileLoading =
                    profileState.fetchStatus == ApiStatus.loading &&
                    profileState.profile == null;
                final earningsLoading =
                    earningsState.statsFetchStatus == ApiStatus.loading &&
                    earningsState.statsResponse == null;

                if (profileLoading || earningsLoading) {
                  return const Center(child: LoadingWidget());
                }

                final hasProfileData = profileState.profile?.user != null;
                final hasEarningsData =
                    earningsState.statsResponse?.data != null;

                if (!hasProfileData &&
                    profileState.fetchStatus == ApiStatus.failed) {
                  return _buildEarningsErrorState(profileState.message);
                }
                if (!hasEarningsData &&
                    earningsState.statsFetchStatus == ApiStatus.failed) {
                  return _buildEarningsErrorState(earningsState.message);
                }

                final user = profileState.profile?.user;
                final stats = earningsState.statsResponse?.data;

                final availableBalance =
                    (user?.availableBalance ?? 0).toDouble();
                final blockedBalance = (user?.blockedBalance ?? 0).toDouble();
                final totalBalance = (user?.walletBalance ?? 0).toDouble();

                final totalEarnings = (stats?.totalEarnings ?? 0).toDouble();
                final pendingEarnings =
                    (stats?.pendingEarnings ?? 0).toDouble();
                final paidEarnings = (stats?.paidEarnings ?? 0).toDouble();
                final remainingCashAmount =
                    (stats?.remainingCashAmount ?? 0).toDouble();

                final systemSettings =
                    context.watch<SystemSettingsBloc>().state.settings;
                final isCashLimitEnabled =
                    (stats?.isCashlimitEnabled ??
                        systemSettings?.cashCollectionLimitStatus) ??
                    true;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Available Balance Card
                      AvailableBalanceCard(
                        availableBalance: availableBalance,
                        titleText: context.tr('availableBalance'),
                        buttonText: context.tr('requestWithdraw'),
                        onWithdrawRequested: () {
                          context.push(AppRoutes.withdrawalHistory);
                        },
                      ),

                      // 2. Blocked & Total Balance Cards side-by-side
                      Row(
                        children: [
                          Expanded(
                            child: BalanceMetricCard(
                              title: context.tr('blocked'),
                              amount: blockedBalance,
                              titleColor: Colors.red,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: BalanceMetricCard(
                              title: context.tr('totalBalance'),
                              amount: totalBalance,
                              titleColor: const Color(0xFF0A7205),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // 3. Earning Summary Title
                      CustomText(
                        text: context.tr('earningsSummary'),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),

                      // 4. Order Earning Tile
                      PocketsNavigationTile(
                        title: context.tr('orderEarning'),
                        subtitle: context.tr('basePayForDeliveries'),
                        icon: TablerIcons.motorbike,
                        amount: totalEarnings,
                        isPrimaryColorTinted: true,
                        onTap: () {
                          context.push(AppRoutes.earnings);
                        },
                      ),

                      // 5. Pending & Paid cards side-by-side
                      Row(
                        children: [
                          Expanded(
                            child: EarningSummaryCard(
                              title: context.tr('pending'),
                              amount: pendingEarnings,
                              icon: TablerIcons.dots_circle_horizontal,
                              iconBgColor: const Color(0xFFFFDEC4),
                              cardBgColor: const Color(0xFFFDF4ED),
                              amountColor: const Color(0xFFE36300),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: EarningSummaryCard(
                              title: context.tr('paid'),
                              amount: paidEarnings,
                              icon: TablerIcons.circle_check,
                              iconBgColor: const Color(0xFFAEF4CD),
                              cardBgColor: const Color(0xFFF3F9F2),
                              amountColor: const Color(0xFF0A7205),
                            ),
                          ),
                        ],
                      ),

                      // 6. COD Cash Collection Card
                      PocketsNavigationTile(
                        title: context.tr('codCashCollection'),
                        subtitle:
                            isCashLimitEnabled
                                ? (remainingCashAmount <= 0
                                    ? context.tr('cashLimitReached')
                                    : context.tr('remainingCashLimit', positionalArgs: [
                                      CurrencyFormatter.formatAmount(
                                        context,
                                        remainingCashAmount,
                                      ),
                                    ]))
                                : '',
                        subtitleColor:
                            remainingCashAmount <= 0
                                ? Colors.red
                                : AppColors.primaryColor,
                        showAmount: isCashLimitEnabled,
                        icon: TablerIcons.cash,
                        onTap: () {
                          context.push(AppRoutes.cashCollection);
                        },
                      ),
                      const SizedBox(height: 5),

                      // 7. Transaction History Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            text: context.tr('transactionHistory'),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          GestureDetector(
                            onTap: () {
                              context.push(AppRoutes.viewTransactions);
                            },
                            child: CustomText(
                              text: context.tr('seeAll'),
                              fontWeight: FontWeight.bold,
                              color:
                                  context.isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      // 8. Transaction List (First 5 records)
                      BlocBuilder<
                        WalletTransactionsBloc,
                        WalletTransactionsState
                      >(
                        builder: (context, transactionState) {
                          if (transactionState.status ==
                                  WalletTransactionsStatus.loading &&
                              transactionState.transactions.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: LoadingWidget()),
                            );
                          }

                          if (transactionState.status ==
                                  WalletTransactionsStatus.failure &&
                              transactionState.transactions.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CustomText(
                                  text:
                                      transactionState.errorMessage ??
                                      'Failed to load transactions',
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }

                          final transactions = transactionState.transactions;
                          if (transactions.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CustomText(
                                  text: context.tr('noTransactionYet'),
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }

                          final displayTransactions =
                              transactions.take(5).toList();

                          return Column(
                            children:
                                displayTransactions.map((transaction) {
                                  return TransactionCard(
                                    transaction: transaction,
                                    isOutside: true,
                                  );
                                }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEarningsErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: CustomCard(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 36.sp,
              ),
              SizedBox(height: 12.h),
              CustomText(
                text: context.tr('somethingWentWrong'),
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: message,
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
