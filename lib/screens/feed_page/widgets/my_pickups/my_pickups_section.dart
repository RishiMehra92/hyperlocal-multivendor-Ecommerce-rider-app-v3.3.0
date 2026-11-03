// widgets/pickup_order/my_pickups_section.dart
import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/pickup_orders_list_bloc/pickup_order_list_bloc.dart';
import 'package:hyper_local/screens/feed_page/widgets/my_pickups/my_pickups_card.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/inactive_delivery_boy_widget.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/config/colors.dart';

class MyPickupsSection extends StatefulWidget {
  final bool isDeliveryBoyActive;

  const MyPickupsSection({super.key, required this.isDeliveryBoyActive});

  @override
  State<MyPickupsSection> createState() => _MyPickupsSectionState();
}

class _MyPickupsSectionState extends State<MyPickupsSection>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.isDeliveryBoyActive) {
      context.read<PickupOrderListBloc>().add(
        FetchPickupOrders(forceRefresh: true),
      );
    }
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (isBottom(_scrollController)) {
      context.read<PickupOrderListBloc>().add(LoadMorePickupOrders());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSelectionContainer(String selectedFilter) {
    final statusTabs = ['on_going', 'done'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children:
            statusTabs.map((status) {
              final isSelected = selectedFilter == status;
              final label = status == 'on_going' ? 'Ongoing' : 'Completed';
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.read<PickupOrderListBloc>().add(
                      FetchPickupOrders(status: status, forceRefresh: true),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primaryColor
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: CustomText(
                      text: label,
                      fontSize: sz(12, seprateTabletSize: 11),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color:
                          isSelected
                              ? Colors.white
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child:
          widget.isDeliveryBoyActive
              ? _buildActiveContent()
              : InactiveDeliveryBoyWidget(
                message:
                    context.tr('activateAccountToViewPickupOrders'),
                buttonText: context.tr('goOnline'),
              ),
    );
  }

  Widget _buildActiveContent() {
    return BlocConsumer<PickupOrderListBloc, PickupOrderListState>(
      listener: (context, state) {},
      builder: (context, state) {
        final orders = state.orders;
        final hasReachedMax = state.hasReachedMax;
        final selectedFilter = state.selectedFilter;

        return Column(
          children: [
            _buildSelectionContainer(selectedFilter),
            Expanded(
              child:
                  state.status == ApiStatus.loading && orders.isEmpty
                      ? const Center(child: LoadingWidget())
                      : state.status == ApiStatus.failed && orders.isEmpty
                      ? EmptyStateWidget(
                        title: context.tr('unableToLoadData'),
                        subtitle:
                            context.tr('checkConnectionAndTryAgain'),
                        icon: Icons.error_outline,
                        onRetry: () {
                          context.read<PickupOrderListBloc>().add(
                            FetchPickupOrders(forceRefresh: true),
                          );
                        },
                      )
                      : orders.isEmpty
                      ? EmptyStateWidget(
                        title: context.tr('noPickupOrders'),
                        subtitle:
                            context.tr('ordersWillAppearHere'),
                        icon: Icons.inbox_outlined,
                        onRetry: () {
                          context.read<PickupOrderListBloc>().add(
                            FetchPickupOrders(forceRefresh: true),
                          );
                        },
                      )
                      : RefreshIndicator(
                        onRefresh: () async {
                          final completer = Completer<void>();
                          context.read<PickupOrderListBloc>().add(
                            FetchPickupOrders(
                              forceRefresh: true,
                              completer: completer,
                            ),
                          );
                          await completer.future;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            vertical: 12.h,
                            horizontal: 8,
                          ),
                          itemCount: orders.length + (hasReachedMax ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index >= orders.length) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(child: LoadingWidget()),
                              );
                            }
                            return MyPickupsCard(
                              key: ValueKey('my_pickup_${orders[index].id}'),
                              pickup: orders[index],
                            );
                          },
                        ),
                      ),
            ),
          ],
        );
      },
    );
  }
}
