import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_slide_action.dart';

class OrderFeedCard extends StatelessWidget {
  final String? expectedEarningText;
  final String orderIdText;
  final double? riderTipAmount;
  final String? storeName;
  final String? storeAddress;
  final String? dropName;
  final String? dropAddress;
  final List<Map<String, String?>>?
  stores; // List of stores with 'name' and 'address'
  final String? distanceText;
  final Widget? additionalInfo;
  final String actionText;
  final bool isLoading;
  final VoidCallback onAction;
  final Color badgeColor;
  final List<Color> avatarGradientColors;
  final bool isPickup;

  const OrderFeedCard({
    super.key,
    required this.expectedEarningText,
    required this.orderIdText,
    this.riderTipAmount,
    this.storeName,
    this.storeAddress,
    this.dropName,
    this.dropAddress,
    this.stores,
    this.distanceText,
    this.additionalInfo,
    required this.actionText,
    required this.isLoading,
    required this.onAction,
    this.badgeColor = AppColors.primaryColor,
    this.avatarGradientColors = const [Colors.amber, Colors.orange],
    required this.isPickup,
  });

  String _getStoreInitials(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName.toLowerCase() == 'store') {
      return 'S';
    }
    final words = cleanName.split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: CustomCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top earnings and order ID section
            Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color:
                    isPickup
                        ? Colors.red.withValues(alpha: 0.05)
                        : AppColors.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 5,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomText(
                        text: context.tr('orderId'),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      CustomText(
                        text: "#$orderIdText",
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (distanceText != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14.sp,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(width: 4.w),
                            CustomText(
                              text: context.tr('pickupFrom'),
                              fontSize: sz(10, seprateTabletSize: 12),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ),
                        // CustomText(
                        //   text: distanceText!,
                        //   fontWeight: FontWeight.w600,
                        //   color: AppColors.primaryColor,
                        //   fontSize: sz(10, seprateTabletSize: 12),
                        // ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                  ],
                  if (stores != null && stores!.isNotEmpty)
                    ...List.generate(stores!.length, (index) {
                      final store = stores![index];
                      final isLast = index == stores!.length - 1;
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 28.w,
                                  height: 28.h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: avatarGradientColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(6.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: avatarGradientColors.first
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4.r,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: CustomText(
                                      text: _getStoreInitials(
                                        store['name'] ?? 'S',
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: sz(12),
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 1.5,
                                      margin: EdgeInsets.symmetric(
                                        vertical: 4.h,
                                      ),
                                      child: CustomPaint(
                                        painter: FeedDashedLinePainter(
                                          color: avatarGradientColors.first
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLast ? 0 : 12.h,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: store['name'] ?? 'Store',
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                    SizedBox(height: 2.h),
                                    if (store['address'] != null &&
                                        store['address']!.isNotEmpty)
                                      CustomText(
                                        text: store['address']!,
                                        fontSize: sz(11),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (isLast && additionalInfo != null) ...[
                                      SizedBox(height: 4.h),
                                      additionalInfo!,
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else if (storeName != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28.w,
                          height: 28.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: avatarGradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                            boxShadow: [
                              BoxShadow(
                                color: avatarGradientColors.first.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 4.r,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: CustomText(
                              text: _getStoreInitials(storeName!),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: storeName!,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              SizedBox(height: 2.h),
                              if (storeAddress != null)
                                CustomText(
                                  text: storeAddress!,
                                  fontSize: sz(11),
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (additionalInfo != null) ...[
                                SizedBox(height: 4.h),
                                additionalInfo!,
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (dropName != null) ...[
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14.sp,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4.w),
                        CustomText(
                          text: context.tr('drop'),
                          fontSize: sz(10, seprateTabletSize: 12),
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28.w,
                          height: 28.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.green, Colors.lightGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 4.r,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: CustomText(
                              text: _getStoreInitials(dropName!),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: sz(12),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: dropName!,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              SizedBox(height: 2.h),
                              if (dropAddress != null &&
                                  dropAddress!.isNotEmpty)
                                CustomText(
                                  text: dropAddress!,
                                  fontSize: sz(11),
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45.h,
                    child: CustomSlideAction(
                      action: onAction,
                      text: actionText,
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Swiper Button
          ],
        ),
      ),
    );
  }
}

class FeedDashedLinePainter extends CustomPainter {
  final Color color;

  FeedDashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 4, startY = 0;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
