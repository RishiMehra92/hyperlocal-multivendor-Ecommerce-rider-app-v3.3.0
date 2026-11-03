import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../../utils/widgets/custom_card.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../utils/widgets/toast_message.dart';
import '../../../../../utils/services/phone_service.dart';
import '../../../../../config/helper.dart';
import '../../../model/available_orders.dart';

class ShippingDetailsSection extends StatelessWidget {
  final Orders order;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ShippingDetailsSection({
    super.key,
    required this.order,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final address =
        '${order.shippingAddress1 ?? ''}${order.shippingAddress2 != null ? ', ${order.shippingAddress2}' : ''}';

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
                  TablerIcons.map_pin,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  size: sz(22, seprateTabletSize: 18).sp,
                ),
                SizedBox(width: 8.w),
                CustomText(
                  text: context.tr('shippingDetails'),
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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  context,
                  '${context.tr('name')} :',
                  order.shippingName ?? 'N/A',
                ),
                _buildDetailRow(
                  context,
                  '${context.tr('phone')} :',
                  order.shippingPhone ?? 'N/A',
                  crossAxisAlignment: CrossAxisAlignment.center,
                  trailing:
                      (order.shippingPhone != null &&
                              order.shippingPhone!.isNotEmpty)
                          ? GestureDetector(
                            onTap: () async {
                              try {
                                await PhoneService.makePhoneCall(
                                  order.shippingPhone!,
                                );
                              } catch (e) {
                                ToastManager.show(
                                  context: context,
                                  message: 'Could not launch phone dialer: $e',
                                  type: ToastType.error,
                                );
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phone_in_talk_outlined,
                                color: Theme.of(context).primaryColor,
                                size: sz(18, seprateTabletSize: 14).sp,
                              ),
                            ),
                          )
                          : null,
                ),
                _buildDetailRow(
                  context,
                  '${context.tr('address')} :',
                  address.isNotEmpty ? address : 'N/A',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Widget? trailing,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: 85.w,
            child: CustomText(text: label, fontWeight: FontWeight.w400),
          ),
          Expanded(
            child: CustomText(
              text: value,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
