import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/feed_page/model/available_orders.dart';
import 'package:hyper_local/utils/currency_formatter.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import '../../bloc/my_orders_bloc/my_orders_bloc.dart';
import '../../bloc/my_orders_bloc/my_orders_event.dart';

class MyOrderCard extends StatelessWidget {
  final Orders order;
  final bool isDarkTheme;

  const MyOrderCard({super.key, required this.order, required this.isDarkTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.0.h),
      child: GestureDetector(
        onTap: () {
          final status = order.status?.toLowerCase();
          final bool isCompleted =
              status == 'delivered' || status == 'completed' || status == 'cancelled' || status == 'canceled';

          if (isCompleted) {
            context.push(AppRoutes.orderDetails, extra: {'orderId': order.id!, 'from': true, 'sourceTab': 1}).then((_) {
              if (context.mounted) {
                context.read<MyOrdersBloc>().add(AllMyOrdersList(forceRefresh: true));
              }
            });
          } else {
            context.push(AppRoutes.mapDelivery, extra: {'order': order, 'sourceTab': 1}).then((_) {
              if (context.mounted) {
                context.read<MyOrdersBloc>().add(AllMyOrdersList(forceRefresh: true));
              }
            });
          }
        },
        child: CustomCard(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CustomText(
                        text:
                            '${context.tr('orderId')} #${order.id ?? context.tr('na')}',
                        fontSize: sz(16, seprateTabletSize: 14),
                        fontWeight: FontWeight.bold,
                      ),
                      if (order.riderTipAmount != null && order.riderTipAmount! > 0) ...[
                        SizedBox(width: 8.w),
                        CustomImageContainer(imagePath: 'assets/png/heart_in_hand.png', width: 14.sp, height: 14.sp),
                        SizedBox(width: 2.w),
                        CustomText(
                          text: CurrencyFormatter.formatAmount(context, order.riderTipAmount!.toStringAsFixed(2)),
                          fontSize: sz(13, seprateTabletSize: 11),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF308001),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status ?? '').withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: CustomText(
                      text: _getLocalizedStatus(order.status ?? '', context),
                      fontSize: sz(12, seprateTabletSize: 10),
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(order.status ?? ''),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

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
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.storefront_outlined, size: 16.w, color: AppColors.primaryColor),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: CustomText(
                                text: store.storeName ?? 'Store',
                                fontSize: sz(13, seprateTabletSize: 11),
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }(),
                  if (order.shippingAddress1 != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16.w,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: CustomText(
                            text:
                                '${order.shippingAddress1}${order.shippingAddress2 != null ? ', ${order.shippingAddress2}' : ''}',
                            fontSize: sz(13, seprateTabletSize: 11),
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              SizedBox(height: 12.h),

              // Order details
              Row(
                children: [
                  // Items count
                  if (order.items != null)
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 16.w,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        SizedBox(width: 4.w),
                        CustomText(
                          text: "${context.tr('items')} ${order.items!.length.toString()}",
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ],
                    ),

                  SizedBox(width: 16.w),

                  // Distance
                  if (order.deliveryRoute?.totalDistance != null)
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 16.sp,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        SizedBox(width: 4.w),
                        CustomText(
                          text:
                              '${order.deliveryRoute!.totalDistance!.toStringAsFixed(1)} ${context.tr('km')}',
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                ],
              ),

              SizedBox(height: 16.h),

              // Earnings
              if (order.earnings?.total != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: context.tr('earnings'),
                      fontSize: sz(12, seprateTabletSize: 10),
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    CustomText(
                      text: CurrencyFormatter.formatAmount(context, order.earnings!.total),
                      fontSize: sz(18, seprateTabletSize: 16),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedStatus(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'pending':
        return context.tr('pending');
      case 'confirmed':
        return context.tr('confirmed');
      case 'preparing':
        return context.tr('preparing');
      case 'ready':
        return context.tr('ready');
      case 'delivered':
        return context.tr('delivered');
      case 'assigned':
        return context.tr('assigned');
      case 'out_for_delivery':
        return context.tr('outForDelivery');
      case 'canceled':
      case 'cancelled':
        return context.tr('cancelled');
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'out_for_delivery':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
      case 'delivered':
        return Colors.green;
      case 'canceled':
      case 'cancelled':
        return AppColors.errorColor;
      default:
        return Colors.grey;
    }
  }
}
