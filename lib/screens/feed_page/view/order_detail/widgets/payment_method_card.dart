import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../config/helper.dart';
import '../../../../../utils/currency_formatter.dart';
import '../../../model/available_orders.dart';

class PaymentMethodCard extends StatelessWidget {
  final Orders order;

  const PaymentMethodCard({super.key, required this.order});

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return const Color(0xFF16A34A); // Green
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return '';
    return status
        .split('_')
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _capitalize(String? text) {
    if (text == null || text.isEmpty) return 'Cod';
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getPaymentStatusColor(order.paymentStatus ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      padding: EdgeInsets.zero,
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Payment Overview & Status
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      TablerIcons.credit_card,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      size: sz(22, seprateTabletSize: 18).sp,
                    ),
                    SizedBox(width: 8.w),
                    CustomText(
                      text: context.tr('paymentOverview'),
                      fontSize: sz(16, seprateTabletSize: 13),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B6B6B),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: CustomText(
                    text: _capitalizeStatus(order.paymentStatus ?? 'Pending'),
                    fontSize: sz(12, seprateTabletSize: 10),
                    color: statusColor,
                  ),
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

          // Bottom Row: Payment Method & Total Amount
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      TablerIcons.coins,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      size: sz(22, seprateTabletSize: 18).sp,
                    ),
                    SizedBox(width: 8.w),
                    CustomText(
                      text: _capitalize(order.paymentMethod),
                      fontSize: sz(16, seprateTabletSize: 13),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B6B6B),
                    ),
                  ],
                ),
                CustomText(
                  text: CurrencyFormatter.formatAmount(
                    context,
                    order.finalTotal ?? '0',
                  ),
                  fontSize: sz(20, seprateTabletSize: 16),
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
