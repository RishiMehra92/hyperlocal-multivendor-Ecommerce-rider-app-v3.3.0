import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../config/colors.dart';
import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/custom_button.dart';
import '../../model/available_orders.dart';
import '../../bloc/items_collected_bloc/items_collected_bloc.dart';
import '../../bloc/items_collected_bloc/items_collected_state.dart';

class ItemCard extends StatelessWidget {
  final Items item;
  final String? orderStatus;
  final bool from;
  final bool isCollected;
  final bool isDelivered;
  final bool isLoading;
  final bool isOtpVerified;
  final bool isOrderWiseOtp;
  final VoidCallback? onCollect;
  final VoidCallback? onDelivered;
  final VoidCallback? onTap;
  final VoidCallback? onReachedDestination;
  final VoidCallback? onNavigateToStore;
  final VoidCallback? onItemOtpTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.orderStatus,
    required this.from,
    required this.isCollected,
    required this.isDelivered,
    required this.isLoading,
    this.isOtpVerified = false,
    this.isOrderWiseOtp = false,
    this.onCollect,
    this.onDelivered,
    this.onTap,
    this.onReachedDestination,
    this.onNavigateToStore,
    this.onItemOtpTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemsCollectedBloc, ItemsCollectedState>(
      builder: (context, state) {
        final bool requiresOtp =
            (item.requiresOtp == true) || (item.product?.requiresOtp == 1);

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              CustomImageContainer(
                width: (isTablet() ? 44 : 50).w,
                height: (isTablet() ? 44 : 50).h,
                imagePath: item.product?.image ?? '',
                backgroundColor:
                    isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8.r),
                errorWidget: Center(
                  child: Icon(
                    Icons.shopping_bag,
                    color: Colors.blue,
                    size: sz(20, seprateTabletSize: 16).sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text:
                          item.title ??
                          context.tr('unknownItem'),
                      fontSize: sz(15, seprateTabletSize: 12),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text:
                          '${context.tr('quantity')} ${item.quantity}',
                      fontSize: sz(13, seprateTabletSize: 10),
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),

              // Right side: Action button, Loader, or Price
              if (isLoading)
                SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                )
              else if (item.status?.toLowerCase() == 'returning_to_store') ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomText(
                      text: context.tr('returningToStore'),
                      fontSize: sz(12, seprateTabletSize: 9),
                      color: AppColors.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                    if (onNavigateToStore != null) ...[
                      SizedBox(height: 4.h),
                      _buildActionButton(
                        context,
                        'Navigate',
                        onNavigateToStore!,
                        color: AppColors.errorColor,
                      ),
                    ],
                  ],
                ),
              ] else if (orderStatus?.toLowerCase() == 'out_for_delivery' &&
                  isCollected &&
                  !isDelivered &&
                  requiresOtp &&
                  !isOtpVerified &&
                  !isOrderWiseOtp &&
                  onItemOtpTap != null) ...[
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[700]!, Colors.amber[800]!],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: onItemOtpTap,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            TablerIcons.shield,
                            color: Colors.white,
                            size: sz(14, seprateTabletSize: 10).sp,
                          ),
                          SizedBox(width: 4.w),
                          CustomText(
                            text: context.tr('enterOtp'),
                            fontSize: sz(12, seprateTabletSize: 9),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    VoidCallback onPressed, {
    bool isEnabled = true,
    Color color = AppColors.primaryColor,
  }) {
    return CustomButton(
      width: (isTablet() ? 70 : 96).w,
      height: (isTablet() ? 30 : 34).h,
      text: text,
      onPressed: isEnabled ? onPressed : null,
      backgroundColor: isEnabled ? color : Colors.grey,
      textColor: Colors.white,
      borderRadius: 6.r,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      textStyle: TextStyle(
        fontSize: sz(12, seprateTabletSize: 9).sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
