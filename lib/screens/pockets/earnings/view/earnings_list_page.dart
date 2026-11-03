import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../../config/colors.dart';
import '../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../../utils/widgets/custom_card.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/loading_widget.dart';
import '../../../../utils/widgets/empty_state_widget.dart';
import '../../../../utils/widgets/inactive_account_widget.dart';
import '../../../../utils/currency_formatter.dart';
import '../../../feed_page/widgets/orderdetails_widgets/statistics_row.dart';
import '../bloc/earnings_bloc.dart';
import '../bloc/earnings_event.dart';
import '../bloc/earnings_state.dart';
import '../model/earnings_model.dart';
import 'package:hyper_local/config/helper.dart';
import '../../../../utils/widgets/toast_message.dart';
import 'package:hyper_local/config/app_images.dart';

class EarningsListPage extends StatefulWidget {
  const EarningsListPage({super.key});

  @override
  State<EarningsListPage> createState() => _EarningsListPageState();
}

class _EarningsListPageState extends State<EarningsListPage> {
  String _selectedDateRange = 'last_1_day'; // Default to Day view
  final ScrollController _dayScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Fetch day earnings by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EarningsBloc>().add(FetchEarnings(dateRange: 'last_1_day'));
    });
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = context.tr('myEarnings');

    return CustomScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      appBar: CustomAppBar(
        title: title,
        // additionalActions: [
        //   Container(
        //     margin: EdgeInsets.only(right: 8.w),
        //     decoration: BoxDecoration(
        //       color: AppColors.primaryColor.withValues(alpha: 0.1),
        //       borderRadius: BorderRadius.circular(8.r),
        //     ),
        //     child: TextButton(
        //       onPressed: () {
        //         context.push('/all-earnings');
        //       },
        //       child: CustomText(
        //         text: context.tr('all'),
        //         fontWeight: FontWeight.w600,
        //         color: AppColors.primaryColor,
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: BlocConsumer<EarningsBloc, EarningsState>(
        listener: (context, state) {
          if (state.fetchStatus == ApiStatus.failed && !state.isInactive) {
            ToastManager.show(
              context: context,
              message: state.message,
              type: ToastType.error,
            );
          }
        },
        builder: (context, state) {
          final isInactive =
              state.fetchStatus == ApiStatus.failed && state.isInactive;
          final isFailed =
              state.fetchStatus == ApiStatus.failed && !state.isInactive;
          final isLoading = state.fetchStatus == ApiStatus.loading;

          return Column(
            spacing: 15,
            children: [
              // 1. Tabs always stay at the top and don't reload
              _buildDateRangeTabs(),

              // 2. Rest of the screen shows loading or content
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (isInactive) {
                      return InactiveAccountWidget(
                        message: state.message,
                        onRetry: () {
                          context.read<EarningsBloc>().add(
                            FetchEarnings(dateRange: _selectedDateRange),
                          );
                        },
                      );
                    }

                    if (isFailed) {
                      return _buildErrorState(state.message);
                    }

                    if (isLoading) {
                      return const Center(child: LoadingWidget());
                    }

                    if (state.response == null) {
                      return const Center(child: LoadingWidget());
                    }

                    return _buildEarningsList(state.response!);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEarningsList(EarningsResponse response) {
    if (response.data == null) {
      return _buildEmptyState();
    }

    final state = context.watch<EarningsBloc>().state;
    final bool isFetchingMore =
        state.fetchStatus == ApiStatus.success ? state.isFetchingMore : false;
    final bool hasReachedMax =
        state.fetchStatus == ApiStatus.success ? state.hasReachedMax : true;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.axis == Axis.vertical &&
            !isFetchingMore &&
            !hasReachedMax &&
            isBottom(scrollInfo.metrics)) {
          context.read<EarningsBloc>().add(
            LoadMoreEarnings(dateRange: _selectedDateRange),
          );
        }
        return true;
      },
      child: SingleChildScrollView(
        child: Column(
          spacing: 20,
          children: [
            // Main Summary Blue Card
            _buildSummaryCard(response),

            // Earning Breakdown Section (horizontal days / vertical weeks + Days Active)
            // if (isWeekView || isMonthView) ...[_buildEarningBreakdownStatsCard(response)],

            // Daily Breakdown Card (the 3-column statistics breakdown)
            _buildDailyBreakdownCard(response),

            // Transaction History Section
            _buildRecentEarningsSection(response, isFetchingMore),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(EarningsResponse response) {
    String periodText = 'Today Earning';
    if (_selectedDateRange == 'last_7_days') {
      periodText = '${_getDateRangeDisplayText(_selectedDateRange)} Earning';
    } else if (_selectedDateRange == 'last_30_days') {
      periodText = _getDateRangeDisplayText(_selectedDateRange);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: .7),
            AppColors.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: const DecorationImage(
          image: AssetImage(AppImages.cardBackgroundImage),
          fit: BoxFit.fill,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0056C6).withValues(alpha: 0.25),
            blurRadius: 16.r,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 34.h, horizontal: 16.w),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              text: periodText,
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            CustomText(
              text: CurrencyFormatter.formatAmount(
                context,
                _getTotalEarnings(response),
              ),
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeTabs() {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildDateRangeTab(
                context.tr('day'),
                _selectedDateRange == 'last_1_day',
                () {
                  setState(() {
                    _selectedDateRange = 'last_1_day';
                  });
                  context.read<EarningsBloc>().add(
                    FetchEarnings(dateRange: 'last_1_day'),
                  );
                },
              ),
            ),

            Container(width: .5, color: Colors.grey.shade300),
            Expanded(
              child: _buildDateRangeTab(
                context.tr('week'),
                _selectedDateRange == 'last_7_days',
                () {
                  setState(() {
                    _selectedDateRange = 'last_7_days';
                  });
                  context.read<EarningsBloc>().add(FetchWeeklyEarnings());
                },
              ),
            ),
            Container(width: .5, color: Colors.grey.shade300),

            Expanded(
              child: _buildDateRangeTab(
                context.tr('month'),
                _selectedDateRange == 'last_30_days',
                () {
                  setState(() {
                    _selectedDateRange = 'last_30_days';
                  });
                  context.read<EarningsBloc>().add(FetchMonthlyEarnings());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeTab(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: CustomText(
              text: title,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdownCard(EarningsResponse response) {
    final isDayView = _selectedDateRange == 'last_1_day';
    final sectionTitle =
        isDayView
            ? context.tr('earningsBreakdown')
            : 'Daily Breakdown';

    return Column(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: sectionTitle,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        CustomCard(
          padding: EdgeInsets.zero,
          width: double.infinity,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // 1. Order Earning
                StatisticItem(
                  icon: TablerIcons.shopping_bag,
                  iconColor: const Color(0xFF1A73E8),
                  iconBackgroundColor: const Color(0xFFE8F0FE),
                  label: context.tr('orderEarnings'),
                  value: CurrencyFormatter.formatAmount(
                    context,
                    _getOrderEarnings(response),
                  ),
                ),

                // Divider
                Container(width: .5, color: Colors.grey[200]),

                // 2. Store Pickup Fee
                StatisticItem(
                  icon: TablerIcons.wallet,
                  iconColor: const Color(0xFF137333),
                  iconBackgroundColor: const Color(0xFFE6F4EA),
                  label: context.tr('storePickupFee'),
                  value: CurrencyFormatter.formatAmount(
                    context,
                    _getOtherEarnings(response),
                  ),
                ),

                // Divider
                // Container(width: .5, color: Colors.grey[200]),
                //
                // // 3. Incentives
                // StatisticItem(
                //   icon: TablerIcons.map_pin,
                //   iconColor: const Color(0xFF9333EA),
                //   iconBackgroundColor: const Color(0xFFF3E8FF),
                //   label: context.tr('incentives'),
                //   value:
                //       CurrencyFormatter.formatAmount(
                //         context,
                //         _getIncentiveEarnings(response),
                //       ).replaceAll('₹', '').replaceAll('\$', '').trim(),
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentEarningsSection(
    EarningsResponse response,
    bool isFetchingMore,
  ) {
    final earnings = response.data?.earnings ?? [];
    final sectionTitle =
        _selectedDateRange == 'last_1_day'
            ? 'Transaction History'
            : 'Recent Earning';

    return Column(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomText(
              text: sectionTitle,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            const Spacer(),
            CustomText(
              text:
                  '${earnings.length} ${context.tr('orders').toLowerCase()}',
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: earnings.length + (isFetchingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < earnings.length) {
              return _buildEarningCard(earnings[index]);
            } else {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: const Center(child: LoadingWidget()),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildEarningCard(EarningsModel earning) {
    final isPaid = earning.paymentStatus?.toLowerCase() == 'paid';
    final statusColor =
        isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final statusBgColor = statusColor.withValues(alpha: 0.15);
    final statusTextColor =
        isPaid ? const Color(0xFF059669) : const Color(0xFFD97706);
    final statusText =
        isPaid
            ? context.tr('completed')
            : context.tr('pending');

    String formattedDate = '';
    final dateStr = earning.createdAt ?? earning.orderDate;
    if (dateStr != null) {
      try {
        final date = DateTime.parse(dateStr);
        formattedDate = DateFormat('d MMM').format(date);
      } catch (e) {
        formattedDate = dateStr;
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                TablerIcons.coins,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: context.tr('earningForOrder', positionalArgs: [earning.orderId.toString()]),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        TablerIcons.clock,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      CustomText(
                        text: formattedDate,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Amount and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  text:
                      '+ ${CurrencyFormatter.formatAmount(context, earning.earnings?.total ?? '0')}',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomText(
                    text: statusText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTotalEarnings(EarningsResponse response) {
    return response.data?.totalEarnings?.toString() ?? '0';
  }

  String _getOrderEarnings(EarningsResponse response) {
    if (response.data?.earnings == null || response.data!.earnings!.isEmpty) {
      return '0';
    }

    double total = 0;
    for (var earning in response.data!.earnings!) {
      if (earning.earnings?.baseFee != null) {
        total += double.tryParse(earning.earnings!.baseFee!) ?? 0;
      }
      if (earning.earnings?.distanceBasedFee != null) {
        total += double.tryParse(earning.earnings!.distanceBasedFee!) ?? 0;
      }
    }

    return total.toString();
  }

  String _getOtherEarnings(EarningsResponse response) {
    if (response.data?.earnings == null || response.data!.earnings!.isEmpty) {
      return '0';
    }

    double total = 0;
    for (var earning in response.data!.earnings!) {
      if (earning.earnings?.perStorePickupFee != null) {
        total += double.tryParse(earning.earnings!.perStorePickupFee!) ?? 0;
      }
    }

    return total.toString();
  }

  String _getDateRangeDisplayText(String dateRange) {
    switch (dateRange) {
      case 'last_1_day':
        return '${context.tr('today')} ${_getCurrentDate()}';
      case 'last_7_days':
        return _getDateRangeText(7);
      case 'last_30_days':
        return _getCurrentMonthText();
      case 'last_365_days':
        return 'All Time';
      default:
        return 'Today: ${_getCurrentDate()}';
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day} ${_getMonthName(now.month)}';
  }

  String _getCurrentMonthText() {
    final now = DateTime.now();
    return '${_getMonthName(now.month)} ${now.year}';
  }

  String _getDateRangeText(int days) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));
    final endDate = now;

    final startDay = startDate.day;
    final endDay = endDate.day;
    final startMonth = _getMonthName(startDate.month);
    final endMonth = _getMonthName(endDate.month);

    if (startDate.month != endDate.month) {
      return '$startDay $startMonth - $endDay $endMonth';
    } else {
      return '$startDay $startMonth - $endDay $startMonth';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) {
      return 'Unknown';
    }
    return months[month - 1];
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      title: context.tr('noEarningsYet'),
      subtitle: context.tr('completeDeliveriesMessage'),
      icon: Icons.account_balance_wallet_outlined,
      showRetryButton: false,
    );
  }

  Widget _buildErrorState(String message) {
    return EmptyStateWidget(
      title: context.tr('errorLoadingEarnings'),
      subtitle: message,
      icon: Icons.error_outline_rounded,
      onRetry: () {
        context.read<EarningsBloc>().add(
          FetchEarnings(dateRange: _selectedDateRange),
        );
      },
    );
  }
}
