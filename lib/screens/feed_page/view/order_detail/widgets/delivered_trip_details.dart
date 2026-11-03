import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/currency_formatter.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/config/colors.dart';
import '../../../model/available_orders.dart';

class DeliveredTripDetails extends StatelessWidget {
  final Orders order;

  const DeliveredTripDetails({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalEarnings = CurrencyFormatter.formatAmount(
      context,
      order.earnings?.total ?? '0',
    );
    final isCancelled =
        order.status?.toLowerCase() == 'cancelled' ||
        order.status?.toLowerCase() == 'canceled';

    // Extract unique stores
    final Set<int> uniqueStoreIds = {};
    final List<Widget> storeWidgets = [];

    if (order.deliveryRoute?.routeDetails != null) {
      for (var detail in order.deliveryRoute!.routeDetails!) {
        final bool isCustomer =
            detail.storeId == null ||
            detail.storeId == 0 ||
            detail.storeName?.toLowerCase().contains('customer') == true;

        if (!isCustomer && !uniqueStoreIds.contains(detail.storeId)) {
          uniqueStoreIds.add(detail.storeId!);
          storeWidgets.add(
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text:
                        detail.storeName ??
                        context.tr('store', fallback: 'Store'),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: detail.address ?? '',
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          );
        }
      }
    } else if (order.items != null) {
      for (var item in order.items!) {
        final bool isCustomer = item.storeId == null || item.storeId == 0;

        if (!isCustomer && !uniqueStoreIds.contains(item.storeId)) {
          uniqueStoreIds.add(item.storeId!);
          storeWidgets.add(
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text:
                        item.store?.name ??
                        context.tr('store', fallback: 'Store'),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text:
                        context.tr('storeAddress', fallback: 'Store Address'), // Fallback if no route details
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    // Build customer address string
    String customerAddress = '';
    if (order.shippingAddress1 != null) {
      customerAddress += order.shippingAddress1!;
    }
    if (order.shippingAddress2 != null && order.shippingAddress2!.isNotEmpty) {
      if (customerAddress.isNotEmpty) customerAddress += ', ';
      customerAddress += order.shippingAddress2!;
    }
    if (order.shippingCity != null && order.shippingCity!.isNotEmpty) {
      if (customerAddress.isNotEmpty) customerAddress += ', ';
      customerAddress += order.shippingCity!;
    }
    if (order.shippingZip != null && order.shippingZip!.isNotEmpty) {
      if (customerAddress.isNotEmpty) customerAddress += ' - ';
      customerAddress += order.shippingZip!;
    }

    return Column(
      children: [
        // Earnings Card
        CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Teal Top Section (Red if cancelled)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color:
                      isCancelled
                          ? AppColors.errorColor
                          : AppColors.primaryColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16.r),
                    topLeft: Radius.circular(16.r),
                  ),
                ),
                child: Column(
                  children: [
                    CustomText(
                      text:
                          isCancelled
                              ? '${context.tr('cancelled', fallback: 'Cancelled')} - ${context.tr('totalEarnings', fallback: 'Total earnings')}'
                              : (context.tr('totalEarnings', fallback: 'Total earnings')),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8.h),
                    CustomText(
                      text: totalEarnings,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              // Breakdown Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
                child: Column(
                  children: [
                    _buildEarningsRow(
                      context,
                      context.tr('baseFee', fallback: 'Base fee'),
                      CurrencyFormatter.formatAmount(
                        context,
                        order.earnings?.breakdown?.baseFee ?? '0',
                      ),
                      isDark,
                    ),
                    _buildEarningsRow(
                      context,
                      context.tr('perStorePickupFee', fallback: 'Store pickup fee'),
                      CurrencyFormatter.formatAmount(
                        context,
                        order.earnings?.breakdown?.perStorePickupFee ?? '0',
                      ),
                      isDark,
                    ),

                    _buildEarningsRow(
                      context,
                      context.tr('distanceBasedFee', fallback: 'Distance fee'),
                      CurrencyFormatter.formatAmount(
                        context,
                        order.earnings?.breakdown?.distanceBasedFee ?? '0',
                      ),
                      isDark,
                    ),

                    _buildEarningsRow(
                      context,
                      context.tr('perOrderIncentive', fallback: 'Order incentive'),
                      CurrencyFormatter.formatAmount(
                        context,
                        order.earnings?.breakdown?.perOrderIncentive ?? '0',
                      ),
                      isDark,
                      isLast:
                          order.riderTipAmount == null ||
                          order.riderTipAmount! <= 0,
                    ),
                    if (order.riderTipAmount != null &&
                        order.riderTipAmount! > 0)
                      _buildEarningsRow(
                        context,
                        context.tr('riderTip', fallback: 'Rider Tip'),
                        CurrencyFormatter.formatAmount(
                          context,
                          order.riderTipAmount!.toStringAsFixed(2),
                        ),
                        isDark,
                        isLast: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // PickUp & Drop Details Card
        CustomCard(
          padding: EdgeInsets.zero,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID banner inside card (Red if cancelled)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color:
                      isCancelled
                          ? AppColors.errorColor
                          : AppColors.primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: CustomText(
                  text:
                      '${context.tr('order', fallback: 'Order')}: ${order.id}',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pickup Section Title
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey[400],
                            thickness: 0.5,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: CustomText(
                            text:
                                (context.tr('pickup', fallback: 'PICKUP'))
                                    .toUpperCase(),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey[400],
                            thickness: 0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    if (storeWidgets.isNotEmpty)
                      ...storeWidgets
                    else
                      CustomText(
                        text:
                            context.tr('storeDetailsNotAvailable', fallback: 'Store details not available'),
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),

                    SizedBox(height: 24.h),

                    // Drop Section Title
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey[400],
                            thickness: 0.5,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: CustomText(
                            text:
                                (context.tr('drop', fallback: 'DROP'))
                                    .toUpperCase(),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey[400],
                            thickness: 0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Customer Name instead of Customer Address
                    CustomText(
                      text:
                          order.shippingName != null &&
                                  order.shippingName!.isNotEmpty
                              ? order.shippingName!
                              : (context.tr('customer', fallback: 'Customer')),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsRow(
    BuildContext context,
    String label,
    String amount,
    bool isDark, {
    bool isLast = false,
  }) {
    if (amount == '₹0.00' || amount == '0') return const SizedBox();

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Column(
        spacing: 2,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: label,
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              CustomText(
                text: amount,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
          if (!isLast) const Divider(thickness: .15),
        ],
      ),
    );
  }
}
