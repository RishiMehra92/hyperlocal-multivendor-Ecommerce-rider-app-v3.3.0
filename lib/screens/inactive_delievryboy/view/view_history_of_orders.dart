import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import '../../../config/helper.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/loading_widget.dart';
import '../../../utils/widgets/toast_message.dart';
import '../../../utils/currency_formatter.dart';
import '../../feed_page/model/available_orders.dart';
import '../bloc/delivered_orders/delivered_orders_bloc.dart';

import '../bloc/delivered_orders/delivered_orders_event.dart';
import '../bloc/delivered_orders/delivered_orders_state.dart';

class ViewHistoryOfOrders extends StatefulWidget {
  const ViewHistoryOfOrders({super.key});

  @override
  State<ViewHistoryOfOrders> createState() => _ViewHistoryOfOrdersState();
}

class _ViewHistoryOfOrdersState extends State<ViewHistoryOfOrders> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Load completed orders when the page is initialized
    context.read<DeliveredOrdersBloc>().add(const LoadDeliveredOrders());

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (isBottom(_scrollController)) {
      context.read<DeliveredOrdersBloc>().add(
        const LoadMoreDeliveredOrders(''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveredOrdersBloc, DeliveredOrdersState>(
      builder: (context, state) {
        return CustomScaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(
            title:
                "${context.tr('viewHistory')} (${state.totalOrders})",
          ),
          body: Column(
            children: [
              Expanded(
                child: BlocConsumer<DeliveredOrdersBloc, DeliveredOrdersState>(
                  listener: (context, state) {
                    if (state.status == ApiStatus.failed) {
                      ToastManager.show(
                        context: context,
                        message: state.errorMessage,
                        type: ToastType.error,
                      );
                    }
                    // Update loading state based on bloc state
                    if (state.status == ApiStatus.loading ||
                        state.isRefreshing) {
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
                    if (state.status == ApiStatus.loading &&
                        state.deliveredOrders.isEmpty) {
                      return const Center(child: LoadingWidget());
                    }

                    if (state.status == ApiStatus.failed &&
                        state.deliveredOrders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64.w,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16.h),
                            CustomText(
                              text:
                                  context.tr('errorLoadingOrders'),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                            SizedBox(height: 8.h),
                            CustomText(
                              text: state.errorMessage,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24.h),
                            ElevatedButton(
                              onPressed: () {
                                context.read<DeliveredOrdersBloc>().add(
                                  const LoadDeliveredOrders(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 12.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: CustomText(
                                text: context.tr('retry'),
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final deliveredOrders = state.deliveredOrders;
                    final hasReachedMax = state.hasReachedMax;

                    if (deliveredOrders.isEmpty) {
                      return EmptyStateWidget(
                        title: context.tr('noDeliveredOrders'),
                        subtitle:
                            context.tr('noDeliveredOrdersYet'),
                        icon: Icons.inbox_outlined,
                        isLoading: _isRefreshing,
                        onRetry: () {
                          context.read<DeliveredOrdersBloc>().add(
                            const LoadDeliveredOrders(forceRefresh: true),
                          );
                        },
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        final completer = Completer<void>();
                        context.read<DeliveredOrdersBloc>().add(
                          LoadDeliveredOrders(
                            forceRefresh: true,
                            completer: completer,
                          ),
                        );
                        await completer.future;
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(bottom: 16.h),
                        itemCount:
                            deliveredOrders.length + (hasReachedMax ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (index >= deliveredOrders.length) {
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: const Center(child: LoadingWidget()),
                            );
                          }

                          final order = deliveredOrders[index];
                          return _DeliveredOrderCard(order: order);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeliveredOrderCard extends StatelessWidget {
  final Orders order;

  const _DeliveredOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section with gradient
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.withValues(alpha: 0.08),
                  Colors.green.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Order ID with icon
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: context.tr('orderId'),
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            SizedBox(height: 2.h),
                            CustomText(
                              text: "#${order.id ?? 'N/A'}",
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // Status badge with shadow
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green,
                        Colors.green.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        text: context.tr('completed'),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Info with enhanced styling
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 18.sp,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: CustomText(
                              text: order.shippingName ?? 'N/A',
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10.h),

                      // Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 18.sp,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: CustomText(
                              text: _buildAddressText(),
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10.h),

                      // Phone
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.phone_rounded,
                              size: 18.sp,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          CustomText(
                            text:
                                "${order.shippingPhonecode ?? ''} ${order.shippingPhone ?? 'N/A'}",
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Order Details with cards
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard(
                        context,
                        order.items != null && order.items!.length > 1
                            ? context.tr('items')
                            : context.tr('item'),

                        "${order.items?.length ?? 0}",
                        Icons.inventory_2_rounded,
                        Colors.purple,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildDetailCard(
                        context,
                        context.tr('total'),
                        CurrencyFormatter.formatAmount(
                          context,
                          order.finalTotal ?? '0',
                        ),
                        Icons.payments_rounded,
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Delivery date with icon
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.event_available_rounded,
                          size: 18.sp,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: context.tr('deliveredOn'),
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            SizedBox(height: 2.h),
                            CustomText(
                              text: _formatDate(order.updatedAt),
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp, color: color),
          SizedBox(height: 8.h),
          CustomText(
            text: value,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          CustomText(
            text: label,
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _buildAddressText() {
    final parts = <String>[];
    if (order.shippingAddress1?.isNotEmpty == true) {
      parts.add(order.shippingAddress1!);
    }
    if (order.shippingAddress2?.isNotEmpty == true) {
      parts.add(order.shippingAddress2!);
    }
    if (order.shippingLandmark?.isNotEmpty == true) {
      parts.add(order.shippingLandmark!);
    }
    if (order.shippingCity?.isNotEmpty == true) parts.add(order.shippingCity!);
    if (order.shippingState?.isNotEmpty == true) {
      parts.add(order.shippingState!);
    }

    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
