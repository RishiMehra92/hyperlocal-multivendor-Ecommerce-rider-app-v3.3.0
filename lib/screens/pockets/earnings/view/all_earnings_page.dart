import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../config/colors.dart';
import '../../../../utils/widgets/custom_scaffold.dart';
import '../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../../utils/widgets/custom_card.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/loading_widget.dart';
import '../../../../utils/widgets/empty_state_widget.dart';
import '../../../../utils/currency_formatter.dart';
import '../bloc/earnings_bloc.dart';
import '../bloc/earnings_event.dart';
import '../bloc/earnings_state.dart';
import '../model/earnings_model.dart';
import 'package:hyper_local/config/helper.dart';

class AllEarningsPage extends StatefulWidget {
  const AllEarningsPage({super.key});

  @override
  State<AllEarningsPage> createState() => _AllEarningsPageState();
}

class _AllEarningsPageState extends State<AllEarningsPage> {
  @override
  void initState() {
    super.initState();

    // Fetch all earnings by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EarningsBloc>().add(FetchYearlyEarnings());
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = context.tr('expectedEarning');

    return CustomScaffold(
      appBar: CustomAppBar(title: title),
      body: BlocConsumer<EarningsBloc, EarningsState>(
        listener: (context, state) {
          /*if (state is EarningsError) {
            ToastManager.show(
              context: context,
              message: state.message,
              type: ToastType.error,
            );
          }*/
        },
        builder: (context, state) {
          if (state.fetchStatus == ApiStatus.loading) {
            return const Center(child: LoadingWidget());
          } else if (state.fetchStatus == ApiStatus.success) {
            return _buildAllEarningsList(state);
          } else if (state.fetchStatus == ApiStatus.failed) {
            return _buildErrorState(state.message);
          }

          return const Center(child: LoadingWidget());
        },
      ),
    );
  }

  Widget _buildAllEarningsList(EarningsState state) {
    if (state.fetchStatus != ApiStatus.success || state.response == null) {
      return const SizedBox.shrink();
    }

    final response = state.response!;
    if (response.data?.earnings == null || response.data!.earnings!.isEmpty) {
      return _buildEmptyState();
    }

    final earnings = response.data!.earnings!;
    final totalEarningsCount = response.data?.total ?? earnings.length;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!state.isFetchingMore &&
            !state.hasReachedMax &&
            isBottom(scrollInfo.metrics)) {
          context.read<EarningsBloc>().add(
            LoadMoreEarnings(dateRange: 'last_365_days'),
          );
        }
        return true;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: earnings.length + (state.hasReachedMax ? 1 : 2),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text:
                      '${context.tr('totalEarnings')}: $totalEarningsCount',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 20.h),
              ],
            );
          }

          if (index <= earnings.length) {
            final earning = earnings[index - 1];
            return _buildEarningCard(earning);
          }

          if (!state.hasReachedMax) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: const Center(child: LoadingWidget()),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEarningCard(EarningsModel earning) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: CustomCard(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: context.tr('orderNumber', positionalArgs: [earning.orderId.toString()]),

                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      earning.paymentStatus,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: CustomText(
                    text:
                        earning.paymentStatus?.toLowerCase() == 'paid'
                            ? context.tr('paid')
                            : context.tr('pending'),

                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(earning.paymentStatus),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Earnings Breakdown
            if (earning.earnings != null) ...[
              _buildEarningsBreakdown(earning.earnings!, isDarkTheme),
              SizedBox(height: 12.h),
            ],

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: context.tr('total'),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                CustomText(
                  text: CurrencyFormatter.formatAmount(
                    context,
                    earning.earnings?.total ?? '0',
                  ),

                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Date
            CustomText(
              text:
                  '${context.tr('date')} ${earning.orderDate ?? earning.createdAt ?? ''}',

              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdown(
    EarningsDetailModel earnings,
    bool isDarkTheme,
  ) {
    return Column(
      children: [
        _buildBreakdownRow('Base Fee', earnings.baseFee ?? '0', isDarkTheme),
        _buildBreakdownRow(
          'Store Pickup',
          earnings.perStorePickupFee ?? '0',
          isDarkTheme,
        ),
        _buildBreakdownRow(
          'Distance Fee',
          earnings.distanceBasedFee ?? '0',
          isDarkTheme,
        ),
        _buildBreakdownRow(
          'Incentive',
          earnings.perOrderIncentive ?? '0',
          isDarkTheme,
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, String amount, bool isDarkTheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: label,
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          CustomText(
            text: CurrencyFormatter.formatAmount(context, amount),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      title: context.tr('noEarningsYet'),
      subtitle: context.tr('completeDeliveriesMessage'),
      icon: Icons.attach_money_outlined,
      showRetryButton: false,
    );
  }

  Widget _buildErrorState(String message) {
    return EmptyStateWidget(
      title: context.tr('errorLoadingEarnings'),
      subtitle: message,
      icon: Icons.error_outline,
      onRetry: () {
        context.read<EarningsBloc>().add(FetchYearlyEarnings());
      },
    );
  }
}
