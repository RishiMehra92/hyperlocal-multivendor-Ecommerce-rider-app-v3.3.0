// widgets/pickup_order/my_pickups_card.dart
import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import '../../model/return_orders_list_model.dart';

class MyPickupsCard extends StatelessWidget {
  final Pickups pickup;

  const MyPickupsCard({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    return _MyPickupsCardContent(pickup: pickup);
  }
}

class _MyPickupsCardContent extends StatelessWidget {
  final Pickups pickup;

  const _MyPickupsCardContent({required this.pickup});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'picked_up':
        return Colors.blue;
      case 'delivered_to_seller':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status, BuildContext context) {
    switch (status) {
      case 'picked_up':
        return context.tr('pickup');
      case 'delivered_to_seller':
        return context.tr('delivered');
      default:
        return context.tr('assigned');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = pickup.store;
    final status = pickup.pickupStatus ?? 'pending';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: CustomCard(
        borderRadius: 12.r,
        onTap: () {
          context.push(
            AppRoutes.pickupOrderDetails,
            extra: {'returnId': pickup.id.toString()},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Pickup ID & Earnings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text:
                      '${context.tr('orderId')} #${pickup.orderId ?? 'N/A'}',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                // if (pickup.earnings?.total != null)
                //   CustomText(
                //     text: CurrencyFormatter.formatAmount(context, pickup.earnings!.total),
                //     fontSize: 16,
                //     fontWeight: FontWeight.bold,
                //     color: const Color(0xFF22C55E), // Green
                //   ),
              ],
            ),
            SizedBox(height: 8.h),

            // Second Row: Store & Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(TablerIcons.map_pin, size: 16.sp, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: CustomText(
                    text:
                        '${store?.name ?? context.tr('unknown')}${store?.address != null ? ', ${store!.address}' : ''}',
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Third Row: Item count & Status/Update Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(TablerIcons.box, size: 16.sp, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    CustomText(
                      text: '1 ${context.tr('item')}',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: CustomText(
                        text: _getStatusText(status, context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                    // if (!isDelivered) ...[
                    //   SizedBox(width: 8.w),
                    //   // Update Status Button
                    //   BlocConsumer<UpdateReturnOrderStatusBloc, UpdateReturnOrderStatusState>(
                    //     listener: (context, state) {
                    //       if (state.returnId == pickup.id.toString()) {
                    //         if (state.status == ApiStatus.success) {
                    //           ToastManager.show(context: context, message: state.message, type: ToastType.success);
                    //           context.read<PickupOrderListBloc>().add(FetchPickupOrders(forceRefresh: true));
                    //         } else if (state.status == ApiStatus.failed) {
                    //           ToastManager.show(context: context, message: state.message, type: ToastType.error);
                    //         }
                    //       }
                    //     },
                    //     builder: (context, state) {
                    //       final isUpdating = state.status == ApiStatus.loading &&
                    //           state.returnId == pickup.id.toString();
                    //
                    //       return InkWell(
                    //         onTap: isUpdating
                    //             ? null
                    //             : () {
                    //                 _showStatusBottomSheet(context, status, pickup.id ?? 0);
                    //               },
                    //         borderRadius: BorderRadius.circular(8.r),
                    //         child: Container(
                    //           padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    //           decoration: BoxDecoration(
                    //             color: AppColors.primaryColor,
                    //             borderRadius: BorderRadius.circular(8.r),
                    //           ),
                    //           child: isUpdating
                    //               ? SizedBox(
                    //                   width: 10.w,
                    //                   height: 10.h,
                    //                   child: const CircularProgressIndicator(
                    //                     color: Colors.white,
                    //                     strokeWidth: 1,
                    //                   ),
                    //                 )
                    //               : Row(
                    //                   mainAxisSize: MainAxisSize.min,
                    //                   children: [
                    //                     Icon(Icons.sync_rounded, size: 10.sp, color: Colors.white),
                    //                     SizedBox(width: 2.w),
                    //                     CustomText(
                    //                       text: context.tr('updateStatus'),
                    //                       color: Colors.white,
                    //                       fontWeight: FontWeight.bold,
                    //                       fontSize: 9,
                    //                     ),
                    //                   ],
                    //                 ),
                    //         ),
                    //       );
                    //     },
                    //   ),
                    // ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
