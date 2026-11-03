import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import '../../../../../utils/currency_formatter.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../config/helper.dart';
import '../../../model/available_orders.dart';

class EarningsDetailsSection extends StatelessWidget {
  final Orders order;
  final bool isExpanded;
  final VoidCallback onToggle;

  const EarningsDetailsSection({
    super.key,
    required this.order,
    required this.isExpanded,
    required this.onToggle,
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
                  TablerIcons.wallet,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  size: sz(22, seprateTabletSize: 18).sp,
                ),
                SizedBox(width: 8.w),
                CustomText(
                  text: context.tr('earnings'),
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
                _buildEarningsRow(
                  context,
                  '${context.tr('baseFee')} :',
                  CurrencyFormatter.formatAmount(
                    context,
                    order.earnings?.breakdown?.baseFee ?? '0',
                  ),
                ),
                _buildEarningsRow(
                  context,
                  '${context.tr('perStorePickupFee')} :',
                  CurrencyFormatter.formatAmount(
                    context,
                    order.earnings?.breakdown?.perStorePickupFee ?? '0',
                  ),
                ),
                _buildEarningsRow(
                  context,
                  '${context.tr('distanceBasedFee')} :',
                  CurrencyFormatter.formatAmount(
                    context,
                    order.earnings?.breakdown?.distanceBasedFee ?? '0',
                  ),
                ),
                _buildEarningsRow(
                  context,
                  '${context.tr('perOrderIncentive')} :',
                  CurrencyFormatter.formatAmount(
                    context,
                    order.earnings?.breakdown?.perOrderIncentive ?? '0',
                  ),
                ),
                if (order.riderTipAmount != null && order.riderTipAmount! > 0)
                  _buildEarningsRow(
                    context,
                    '${context.tr('riderTip')} :',
                    CurrencyFormatter.formatAmount(
                      context,
                      order.riderTipAmount!.toStringAsFixed(2),
                    ),
                  ),
              ],
            ),
          ),

          // Divider above Total
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),

          // Total Earnings Row with light grey background and rounded bottom corners
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: context.tr('totalEarnings'),
                  fontSize: sz(16, seprateTabletSize: 13),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                CustomText(
                  text: CurrencyFormatter.formatAmount(
                    context,
                    order.earnings?.total ?? '0',
                  ),
                  fontSize: sz(16, seprateTabletSize: 13),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsRow(BuildContext context, String label, String amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(text: label, fontSize: sz(14, seprateTabletSize: 11)),
          CustomText(
            text: amount,
            fontSize: sz(14, seprateTabletSize: 11),
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}
