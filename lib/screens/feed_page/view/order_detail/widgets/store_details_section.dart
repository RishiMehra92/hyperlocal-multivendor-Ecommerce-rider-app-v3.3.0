import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../../utils/widgets/custom_card.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../config/helper.dart';
import '../../../model/available_orders.dart';

class StoreDetailsSection extends StatelessWidget {
  final Orders order;
  final bool isExpanded;
  final VoidCallback onToggle;

  const StoreDetailsSection({
    super.key,
    required this.order,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stores =
        order.deliveryRoute?.routeDetails
            ?.where(
              (store) =>
                  store.storeName?.toLowerCase() != 'customer location' &&
                  store.storeId != null,
            )
            .toList() ??
        [];

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
                  TablerIcons.building_store,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  size: sz(22, seprateTabletSize: 18).sp,
                ),
                SizedBox(width: 8.w),
                CustomText(
                  text: context.tr('storeDetails'),
                  fontSize: sz(16, seprateTabletSize: 13),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6B6B),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),

          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              children: [
                if (stores.isNotEmpty) ...[
                  for (int i = 0; i < stores.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        ),
                      ),

                    Row(
                      children: [
                        // Store Logo circular avatar
                        Container(
                          width: (isTablet() ? 40 : 48).w,
                          height: (isTablet() ? 40 : 48).h,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.grey[800]
                                    : const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              TablerIcons.building_store,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700],
                              size: sz(24, seprateTabletSize: 20).sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: stores[i].storeName ?? 'Store',
                                fontSize: sz(16, seprateTabletSize: 13),
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              if (stores[i].address != null &&
                                  stores[i].address!.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                CustomText(
                                  text: stores[i].address!,
                                  fontSize: sz(13, seprateTabletSize: 10),
                                  color:
                                      isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                ),
                              ],
                            ],
                          ),
                        ),
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
          ),
        ],
      ),
    );
  }
}
