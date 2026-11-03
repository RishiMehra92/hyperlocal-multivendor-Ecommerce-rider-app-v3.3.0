import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../config/helper.dart';
import '../../../../../config/colors.dart';
import '../../../model/available_orders.dart';

class StoreGroup {
  final int? storeId;
  final String storeName;
  final String? storeAddress;
  final List<Widget> itemCards;

  StoreGroup({required this.storeId, required this.storeName, this.storeAddress, required this.itemCards});
}

class OrderItemsSection extends StatelessWidget {
  final Orders order;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<StoreGroup> storeGroups;
  final VoidCallback? onCollectAll;
  final Set<int> collectingStoreIds;
  final Set<String>? collectedItems;
  final Function(int)? onCollectAllForStore;
  final Function(int)? onNavigateToStore;
  final int? navigatingStoreId;
  final Function(Items)? onItemOtpTap;

  const OrderItemsSection({
    super.key,
    required this.order,
    required this.isExpanded,
    required this.onToggle,
    required this.storeGroups,
    this.onCollectAll,
    this.collectingStoreIds = const {},
    this.collectedItems,
    this.onCollectAllForStore,
    this.onNavigateToStore,
    this.navigatingStoreId,
    this.onItemOtpTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Icon(
                  TablerIcons.box,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  size: sz(22, seprateTabletSize: 18).sp,
                ),
                SizedBox(width: 8.w),
                CustomText(
                  text: context.tr('orderItems'),
                  fontSize: sz(16, seprateTabletSize: 13),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6B6B),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),

          // Items List
          Column(
            children: [
              if (storeGroups.isNotEmpty) ...[
                for (int i = 0; i < storeGroups.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Divider(height: 1, thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store Header
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                                  : AppColors.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  TablerIcons.building_store,
                                  color: AppColors.primaryColor,
                                  size: sz(20, seprateTabletSize: 16).sp,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: CustomText(
                                                    text: storeGroups[i].storeName,
                                                    fontSize: sz(14, seprateTabletSize: 12),
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                ),
                                                if (onNavigateToStore != null && storeGroups[i].storeId != null) ...[
                                                  SizedBox(width: 8.w),
                                                  InkWell(
                                                    onTap:
                                                        navigatingStoreId != null
                                                            ? null
                                                            : () => onNavigateToStore!(storeGroups[i].storeId!),
                                                    borderRadius: BorderRadius.circular(12.r),
                                                    child: Padding(
                                                      padding: EdgeInsets.all(4.r),
                                                      child:
                                                          navigatingStoreId == storeGroups[i].storeId
                                                              ? SizedBox(
                                                                width: 14.w,
                                                                height: 14.h,
                                                                child: const CircularProgressIndicator(
                                                                  strokeWidth: 2,
                                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                                    AppColors.primaryColor,
                                                                  ),
                                                                ),
                                                              )
                                                              : Icon(
                                                                TablerIcons.navigation_filled,
                                                                color: AppColors.primaryColor,
                                                                size: sz(16, seprateTabletSize: 13).sp,
                                                              ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                            child: CustomText(
                                              text:
                                                  storeGroups[i].itemCards.length == 1
                                                      ? '1 ${context.tr('item')}'
                                                      : '${storeGroups[i].itemCards.length} ${context.tr('items')}',
                                              fontSize: sz(11, seprateTabletSize: 9),
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (storeGroups[i].storeAddress != null &&
                                          storeGroups[i].storeAddress!.isNotEmpty) ...[
                                        SizedBox(height: 2.h),
                                        CustomText(
                                          text: storeGroups[i].storeAddress!,
                                          fontSize: sz(11, seprateTabletSize: 9),
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            Builder(
                              builder: (context) {
                                final orderStatus = order.status?.toLowerCase();
                                if (orderStatus == 'cancelled' || orderStatus == 'canceled') {
                                  return const SizedBox.shrink();
                                }

                                final storeId = storeGroups[i].storeId;
                                if (storeId == null) {
                                  return const SizedBox.shrink();
                                }

                                final hasUncollectedItems =
                                    order.items?.any((item) {
                                      if (item.storeId != storeId) return false;
                                      final s = item.status?.toLowerCase();
                                      return s != 'collected' &&
                                          s != 'delivered' &&
                                          s != 'returning_to_store' &&
                                          !(collectedItems?.contains(item.id.toString()) ?? false);
                                    }) ??
                                    false;

                                if (hasUncollectedItems && onCollectAllForStore != null) {
                                  final isThisStoreCollecting = collectingStoreIds.contains(storeId);

                                  return Padding(
                                    padding: EdgeInsets.only(top: 8.h, right: 10.w),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors:
                                                isThisStoreCollecting
                                                    ? [Colors.grey[400]!, Colors.grey[500]!]
                                                    : [
                                                      AppColors.primaryColor,
                                                      AppColors.primaryColor.withValues(alpha: 0.85),
                                                    ],
                                          ),
                                          borderRadius: BorderRadius.circular(20.r),
                                          boxShadow:
                                              isThisStoreCollecting
                                                  ? null
                                                  : [
                                                    BoxShadow(
                                                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20.r),
                                          onTap: isThisStoreCollecting ? null : () => onCollectAllForStore!(storeId),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isThisStoreCollecting) ...[
                                                  SizedBox(
                                                    width: sz(12, seprateTabletSize: 10).sp,
                                                    height: sz(12, seprateTabletSize: 10).sp,
                                                    child: const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  ),
                                                ] else ...[
                                                  Icon(
                                                    TablerIcons.circle_check,
                                                    color: Colors.white,
                                                    size: sz(15, seprateTabletSize: 12).sp,
                                                  ),
                                                ],
                                                SizedBox(width: 6.w),
                                                CustomText(
                                                  text: context.tr('collectAllItems'),
                                                  fontSize: sz(12, seprateTabletSize: 10),
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 8.h),
                      // Store Items List
                      Padding(padding: const EdgeInsets.all(10), child: Column(children: storeGroups[i].itemCards)),
                    ],
                  ),
                ],
              ] else
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: CustomText(
                    text: context.tr('noData'),
                    fontSize: sz(16, seprateTabletSize: 12),
                    color: Colors.grey,
                  ),
                ),
            ],
          ),

          // // Optional Price Breakdown (Subtotal, Delivery, Handling, etc.)
          // if (itemsCount > 0) ...[
          //   Divider(height: 1, thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          //   Padding(
          //     padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          //     child: Column(
          //       children: [
          //         _buildPriceRow(
          //           context,
          //           '${context.tr('subtotal')} :',
          //           CurrencyFormatter.formatAmount(context, order.subtotal ?? '0'),
          //         ),
          //         if (deliveryVal > 0)
          //           _buildPriceRow(
          //             context,
          //             '${context.tr('deliveryCharges')} :',
          //             CurrencyFormatter.formatAmount(context, order.deliveryCharge ?? '0'),
          //           ),
          //         if (otherFeesVal > 0.01)
          //           _buildPriceRow(
          //             context,
          //             '${context.tr('otherCharges')} :',
          //             CurrencyFormatter.formatAmount(context, otherFeesVal.toStringAsFixed(2)),
          //           ),
          //       ],
          //     ),
          //   ),
          // ],
          //
          // // Divider above Total
          // Divider(height: 1, thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          //
          // // Bottom Total Container
          // Container(
          //   width: double.infinity,
          //   padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       CustomText(
          //         text: '${context.tr('total')} ($itemsText)',
          //         fontSize: sz(15, seprateTabletSize: 12),
          //         fontWeight: FontWeight.w500,
          //       ),
          //       CustomText(
          //         text: CurrencyFormatter.formatAmount(context, order.finalTotal ?? '0'),
          //         fontSize: sz(18, seprateTabletSize: 14),
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
