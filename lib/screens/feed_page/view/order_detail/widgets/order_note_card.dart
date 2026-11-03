import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../config/helper.dart';

import '../../../model/available_orders.dart';

class OrderNoteCard extends StatelessWidget {
  final Orders order;

  const OrderNoteCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Only show the card if there's an order note
    // if (order.orderNote == null || order.orderNote!.isEmpty) {
    //   return const SizedBox.shrink();
    // }

    return CustomCard(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.all((isTablet() ? 12 : 16).w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all((isTablet() ? 6 : 8).h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.note,
                    color: Colors.orange,
                    size: sz(20, seprateTabletSize: 16).sp,
                  ),
                ),
                SizedBox(width: 12.w),
                CustomText(
                  text: context.tr('orderNote'),
                  fontSize: sz(16, seprateTabletSize: 12),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all((isTablet() ? 10 : 12).w),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: CustomText(
                text: order.orderNote!,
                fontSize: sz(14, seprateTabletSize: 10),
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
