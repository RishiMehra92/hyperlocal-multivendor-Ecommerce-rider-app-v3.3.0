import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/screens/feed_page/widgets/my_orders/my_order_card.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/empty_state_widget.dart';
import '../../../../utils/widgets/inactive_delivery_boy_widget.dart';
import '../../bloc/my_orders_bloc/my_orders_bloc.dart';
import '../../bloc/my_orders_bloc/my_orders_event.dart';
import '../../bloc/my_orders_bloc/my_orders_state.dart';

class MyOrdersSection extends StatefulWidget {
  final bool isDarkTheme;
  final bool isDeliveryBoyActive;

  const MyOrdersSection({
    super.key,
    required this.isDarkTheme,
    required this.isDeliveryBoyActive,
  });

  @override
  State<MyOrdersSection> createState() => _MyOrdersSectionState();
}

class _MyOrdersSectionState extends State<MyOrdersSection>
    with AutomaticKeepAliveClientMixin<MyOrdersSection> {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Only load my orders when the delivery boy is active and if not already loaded
    if (widget.isDeliveryBoyActive) {
      final state = context.read<MyOrdersBloc>().state;
      if (state.status == ApiStatus.initial) {
        context.read<MyOrdersBloc>().add(AllMyOrdersList());
      }
    }

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (isBottom(_scrollController)) {
      final currentState = context.read<MyOrdersBloc>().state;
      if (currentState.status == ApiStatus.success) {
        context.read<MyOrdersBloc>().add(
          LoadMoreMyOrders(currentState.selectedFilter),
        );
      }
    }
  }

  void _showFilterBottomSheet(String currentFilter) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: context.tr('filter'),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      _buildFilterOption(
                        currentFilter,
                        'all',
                        context.tr('all'),
                        Icons.done_all_sharp,
                      ),
                      _buildFilterOption(
                        currentFilter,
                        'assigned',
                        context.tr('assigned'),
                        Icons.assignment,
                      ),
                      _buildFilterOption(
                        currentFilter,
                        'in_progress',
                        context.tr('outForDelivery'),
                        Icons.delivery_dining,
                      ),
                      _buildFilterOption(
                        currentFilter,
                        'completed',
                        context.tr('delivered'),
                        Icons.check_circle,
                      ),
                      // _buildFilterOption(
                      //   currentFilter,
                      //   'canceled',
                      //   context.tr('cancelled'),
                      //   Icons.cancel,
                      // ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
    String currentFilter,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = currentFilter == value;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // Reload orders with new filter
        context.read<MyOrdersBloc>().add(
          AllMyOrdersList(type: value, forceRefresh: true),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).iconTheme.color,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: CustomText(
                text: label,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: Theme.of(context).primaryColor,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(String currentFilter) {
    switch (currentFilter) {
      case 'all':
        return context.tr('all');
      case 'assigned':
        return context.tr('assigned');
      case 'in_progress':
        return context.tr('outForDelivery');
      case 'completed':
        return context.tr('delivered');
      case 'canceled':
        return context.tr('cancelled');
      default:
        return context.tr('all');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<MyOrdersBloc, MyOrdersState>(
      listener: (context, state) {
        /*if (state is MyOrdersError) {
          ToastManager.show(
            context: context,
            message: state.errorMessage,
            type: ToastType.error,
          );
        }*/
        if (state.status == ApiStatus.loading) {
          setState(() {
            _isRefreshing = true;
          });
        } else if (state.status == ApiStatus.success ||
            state.status == ApiStatus.failed) {
          setState(() {
            _isRefreshing = false;
          });
        }
      },
      builder: (context, state) {
        if (!widget.isDeliveryBoyActive) {
          return InactiveDeliveryBoyWidget(
            message: context.tr('activateAccountToViewOrders'),
            buttonText: context.tr('goOnline'),
          );
        }

        if (state.status == ApiStatus.loading && state.myOrders.isEmpty) {
          return const Center(child: LoadingWidget());
        }

        if (state.status == ApiStatus.failed && state.myOrders.isEmpty) {
          return EmptyStateWidget(
            title: context.tr('unableToLoadData'),
            subtitle: state.message,
            icon: Icons.error_outline,
            onRetry: () {
              context.read<MyOrdersBloc>().add(
                AllMyOrdersList(forceRefresh: true),
              );
            },
          );
        }

        final myOrders = state.myOrders;
        final hasReachedMax = state.hasReachedMax;
        final totalOrders = state.totalOrders;
        final selectedFilter = state.selectedFilter;
        final isRefreshing = state.isRefreshing;

        final filteredOrders = () {
          final list = myOrders.toList();
          if (selectedFilter == 'all') {
            return list;
          } else if (selectedFilter == 'completed') {
            return list.where((order) {
              final status = order.status?.toLowerCase();
              return status == 'delivered' || status == 'completed';
            }).toList();
          } else if (selectedFilter == 'canceled') {
            return list.where((order) {
              final status = order.status?.toLowerCase();
              return status == 'canceled' || status == 'cancelled';
            }).toList();
          } else if (selectedFilter == 'in_progress') {
            return list.where((order) {
              final status = order.status?.toLowerCase();
              return status == 'in_progress' ||
                  status == 'out_for_delivery' ||
                  status == 'on_the_way';
            }).toList();
          }

          return list.where((order) {
            final status = order.status?.toLowerCase();
            return status != 'delivered' &&
                status != 'completed' &&
                status != 'canceled' &&
                status != 'cancelled';
          }).toList();
        }();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 16.0.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: context.tr('myOrders'),
                    fontSize: sz(20, seprateTabletSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                  Row(
                    children: [
                      CustomText(
                        text: context.tr('ordersCount', positionalArgs: [totalOrders.toString()]),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      SizedBox(width: 12.w),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentGeometry.centerRight,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0.h),
                child: InkWell(
                  onTap: () => _showFilterBottomSheet(selectedFilter),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 18.sp,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 4.w),
                        CustomText(
                          text: _getFilterLabel(selectedFilter),
                          fontSize: sz(12),
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      final completer = Completer<void>();
                      context.read<MyOrdersBloc>().add(
                        AllMyOrdersList(
                          forceRefresh: true,
                          completer: completer,
                        ),
                      );
                      await completer.future;
                    },
                    child: Builder(
                      builder: (context) {
                        if (filteredOrders.isEmpty) {
                          return EmptyStateWidget(
                            title: context.tr('noOrdersFound'),
                            subtitle:
                                context.tr('noOrdersAcceptedYet'),
                            icon: Icons.inbox_outlined,
                            isLoading: _isRefreshing,
                            onRetry: () {
                              context.read<MyOrdersBloc>().add(
                                AllMyOrdersList(forceRefresh: true),
                              );
                            },
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(bottom: 16.h),
                          itemCount:
                              filteredOrders.length + (hasReachedMax ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index >= filteredOrders.length) {
                              return Padding(
                                padding: EdgeInsets.all(16.0.w),
                                child: const Center(child: LoadingWidget()),
                              );
                            }

                            final order = filteredOrders[index];
                            return MyOrderCard(
                              key: ValueKey('my_order_${order.id}'),
                              order: order,
                              isDarkTheme: widget.isDarkTheme,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (isRefreshing)
                    Align(
                      alignment: AlignmentGeometry.topCenter,
                      child: Container(
                        padding: EdgeInsets.all(8.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4.r,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
