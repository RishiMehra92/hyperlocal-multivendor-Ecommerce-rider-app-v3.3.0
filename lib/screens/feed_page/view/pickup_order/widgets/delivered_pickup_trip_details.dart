import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/feed_page/model/return_orders_list_model.dart';
import 'package:hyper_local/utils/currency_formatter.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/config/colors.dart';

class DeliveredPickupTripDetails extends StatelessWidget {
  final Pickups pickup;

  const DeliveredPickupTripDetails({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalEarnings = CurrencyFormatter.formatAmount(context, pickup.earnings?.total ?? 0);
    final isCancelled =
        pickup.pickupStatus?.toLowerCase() == 'cancelled' || pickup.pickupStatus?.toLowerCase() == 'canceled';

    // Store Details for Drop
    final store = pickup.store;
    String storeName = 'N/A';
    String storeAddress = 'N/A';
    if (store != null) {
      storeName = store.name ?? 'Store';
      List<String> addressParts = [];
      if (store.address != null && store.address!.trim().isNotEmpty) {
        addressParts.add(store.address!.trim());
      }
      if (store.city != null && store.city!.trim().isNotEmpty) {
        addressParts.add(store.city!.trim());
      }
      if (store.state != null && store.state!.trim().isNotEmpty) {
        addressParts.add(store.state!.trim());
      }
      if (store.zipcode != null && store.zipcode!.trim().isNotEmpty) {
        addressParts.add(store.zipcode!.trim());
      }
      if (addressParts.isNotEmpty) {
        storeAddress = addressParts.join(', ');
      }
    }

    // Customer Name for Pickup
    final order = pickup.order;
    final String customerName = order?.shippingName ?? context.tr('customer', fallback: 'Customer');

    return Column(
      children: [
        // Earnings Card
        CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Teal/Primary Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: isCancelled ? AppColors.errorColor : AppColors.primaryColor,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(16.r), topLeft: Radius.circular(16.r)),
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
                    CustomText(text: totalEarnings, fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
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
                      CurrencyFormatter.formatAmount(context, pickup.earnings?.breakdown?.baseFee ?? 0),
                      isDark,
                    ),
                    _buildEarningsRow(
                      context,
                      context.tr('perStorePickupFee', fallback: 'Store pickup fee'),
                      CurrencyFormatter.formatAmount(context, pickup.earnings?.breakdown?.perStorePickupFee ?? 0),
                      isDark,
                    ),
                    _buildEarningsRow(
                      context,
                      context.tr('distanceBasedFee', fallback: 'Distance fee'),
                      CurrencyFormatter.formatAmount(context, pickup.earnings?.breakdown?.distanceBasedFee ?? 0),
                      isDark,
                    ),
                    _buildEarningsRow(
                      context,
                      context.tr('perOrderIncentive', fallback: 'Order incentive'),
                      CurrencyFormatter.formatAmount(context, pickup.earnings?.breakdown?.perOrderIncentive ?? 0),
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
              // Banner inside card
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isCancelled ? AppColors.errorColor : AppColors.primaryColor,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16.r), topRight: Radius.circular(16.r)),
                ),
                child: CustomText(
                  text: '${context.tr('pickupDetails', fallback: 'Pickup Details')} #${pickup.id}',
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
                    // Pickup Section (Customer Name)
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[400], thickness: 0.5)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: CustomText(
                            text: (context.tr('pickup', fallback: 'PICKUP')).toUpperCase(),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[400], thickness: 0.5)),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    CustomText(
                      text: customerName,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),

                    SizedBox(height: 24.h),

                    // Drop Section (Store Name & Address)
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[400], thickness: 0.5)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: CustomText(
                            text: (context.tr('drop', fallback: 'DROP')).toUpperCase(),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[400], thickness: 0.5)),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    CustomText(
                      text: storeName,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(text: storeAddress, fontSize: 13, color: Colors.grey[600]),
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

  Widget _buildEarningsRow(BuildContext context, String label, String amount, bool isDark, {bool isLast = false}) {
    if (amount == '₹0.00' || amount == '0' || amount == '₹0') {
      return const SizedBox();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Column(
        spacing: 2,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(text: label, fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[700]),
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
