import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/feed_page/bloc/my_orders_bloc/my_orders_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/my_orders_bloc/my_orders_event.dart';
import 'package:hyper_local/screens/feed_page/bloc/my_orders_bloc/my_orders_state.dart';
import 'package:hyper_local/screens/feed_page/model/available_orders.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/utils/currency_formatter.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/config/helper.dart';

class MyOrdersPage extends StatefulWidget {
  final String? initialTabStatus;

  const MyOrdersPage({super.key, this.initialTabStatus});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final ScrollController _scrollController = ScrollController();
  String _selectedStatus = 'assigned';
  final List<String> _statusTabs = ['assigned', 'in_progress', 'completed', 'canceled'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    if (widget.initialTabStatus != null && _statusTabs.contains(widget.initialTabStatus)) {
      _selectedStatus = widget.initialTabStatus!;
    }
    _loadOrdersForTab(_selectedStatus, forceRefresh: true);
  }

  void _onScroll() {
    if (isBottom(_scrollController)) {
      final state = context.read<MyOrdersBloc>().state;
      if (state.status == ApiStatus.success && !state.hasReachedMax) {
        context.read<MyOrdersBloc>().add(LoadMoreMyOrders(_selectedStatus));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadOrdersForTab(String status, {bool forceRefresh = false, Completer<void>? completer}) {
    context.read<MyOrdersBloc>().add(AllMyOrdersList(type: status, forceRefresh: forceRefresh, completer: completer));
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'assigned':
        return context.tr('assigned');
      case 'in_progress':
        return context.tr('inProgress');
      case 'completed':
        return context.tr('delivered');
      case 'canceled':
        return context.tr('canceled');

      default:
        return status;
    }
  }

  ScrollController sc = ScrollController();

  Widget _buildSelectionContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: sc,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    _statusTabs.map((status) {
                      final isSelected = _selectedStatus == status;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStatus = status;
                          });

                          sc.animateTo(
                            ["canceled", "completed"].contains(_selectedStatus)
                                ? sc.position.maxScrollExtent
                                : sc.position.minScrollExtent,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeIn,
                          );

                          _loadOrdersForTab(status, forceRefresh: true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: CustomText(
                            text: _getStatusDisplayName(status),
                            fontSize: sz(12, seprateTabletSize: 11),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color:
                                isSelected
                                    ? Colors.white
                                    : Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Orders order, bool isDarkTheme) {
    final bool isDeliveredOrCanceledTab =
        _selectedStatus == 'completed' ||
        _selectedStatus == 'canceled' ||
        order.status?.toLowerCase() == 'delivered' ||
        order.status?.toLowerCase() == 'completed' ||
        order.status?.toLowerCase() == 'cancelled' ||
        order.status?.toLowerCase() == 'canceled';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: CustomCard(
        borderRadius: 12.r,
        onTap: () {
          final status = order.status?.toLowerCase();
          final bool isCompleted =
              status == 'delivered' ||
              status == 'completed' ||
              status == 'cancelled' ||
              status == 'canceled' ||
              _selectedStatus == 'completed' ||
              _selectedStatus == 'canceled';

          if (isCompleted) {
            context.push(AppRoutes.orderDetails, extra: {'orderId': order.id!, 'from': true, 'sourceTab': 1}).then((_) {
              if (mounted) {
                _loadOrdersForTab(_selectedStatus, forceRefresh: true);
              }
            });
          } else {
            context.push(AppRoutes.mapDelivery, extra: {'order': order, 'sourceTab': 1}).then((_) {
              if (mounted) {
                _loadOrdersForTab(_selectedStatus, forceRefresh: true);
              }
            });
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Order ID & Earnings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomText(
                      text: '${context.tr('order')} #${order.id ?? 'N/A'}',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    if (order.riderTipAmount != null && order.riderTipAmount! > 0) ...[
                      SizedBox(width: 8.w),
                      CustomImageContainer(imagePath: 'assets/png/heart_in_hand.png', width: 14.sp, height: 14.sp),
                      SizedBox(width: 2.w),
                      CustomText(
                        text: CurrencyFormatter.formatAmount(context, order.riderTipAmount!.toStringAsFixed(2)),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF308001),
                      ),
                    ],
                  ],
                ),

                if (order.status?.toLowerCase() == 'delivered' || order.status?.toLowerCase() == 'completed')
                  CustomText(
                    text: CurrencyFormatter.formatAmount(context, order.earnings?.total ?? 0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
              ],
            ),
            SizedBox(height: 8.h),

            // Delivery route details (Stores + Customer)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...() {
                  final validStores =
                      order.deliveryRoute?.routeDetails?.where((detail) {
                        if (detail.storeId == null || detail.storeId == 0) {
                          return false;
                        }
                        final name = detail.storeName?.toLowerCase();
                        if (name == null || name == 'null' || name == 'customer location') {
                          return false;
                        }
                        return true;
                      }).toList() ??
                      [];

                  return validStores.map(
                    (store) => Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.storefront_outlined, size: 16.sp, color: AppColors.primaryColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: CustomText(
                              text: store.storeName ?? 'Store',
                              fontSize: 13,
                              color: Colors.grey[600],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }(),
                if (!isDeliveredOrCanceledTab && order.shippingAddress1 != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(TablerIcons.map_pin, size: 16.sp, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomText(
                          text:
                              '${order.shippingAddress1}, ${order.shippingAddress2 ?? ''}, ${order.shippingCity ?? ''}',
                          fontSize: 13,
                          color: Colors.grey[600],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (!isDeliveredOrCanceledTab) ...[
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(TablerIcons.box, size: 16.sp, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      CustomText(
                        text: '${order.items?.length ?? 0} ${context.tr('items')}',
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return CustomScaffold(
      appBar: CustomAppBar(title: context.tr('myOrders')),
      body: Column(
        spacing: 10,
        children: [
          // Status tabs matching custom UI
          _buildSelectionContainer(),

          // List content
          Expanded(
            child: BlocBuilder<MyOrdersBloc, MyOrdersState>(
              builder: (context, state) {
                if (state.status == ApiStatus.loading && state.myOrders.isEmpty) {
                  return const Center(child: LoadingWidget());
                }

                if (state.status == ApiStatus.failed && state.myOrders.isEmpty) {
                  return ErrorStateWidget(onRetry: () => _loadOrdersForTab(_selectedStatus, forceRefresh: true));
                }

                final myOrders = state.myOrders;
                final hasReachedMax = state.hasReachedMax;

                if (myOrders.isEmpty) {
                  return EmptyStateWidget(
                    title:
                        '${context.tr('no')} ${_getStatusDisplayName(_selectedStatus).toLowerCase()} ${context.tr('orders')}',
                    subtitle: context.tr('ordersWillAppearHere'),
                    icon: TablerIcons.inbox,
                    showRetryButton: false,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final completer = Completer<void>();
                    _loadOrdersForTab(_selectedStatus, forceRefresh: true, completer: completer);
                    await completer.future;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: myOrders.length + (hasReachedMax ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index >= myOrders.length) {
                        return const Center(child: LoadingWidget());
                      }
                      final order = myOrders[index];
                      return _buildOrderCard(order, isDarkTheme);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
