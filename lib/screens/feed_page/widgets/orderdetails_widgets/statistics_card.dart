import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/utils/extensions.dart';
import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_text.dart';

class StatisticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color valueColor;

  const StatisticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    this.valueColor =
        Colors.transparent, // Default to transparent to use theme color
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: BoxConstraints(minHeight: (isTablet() ? 88 : 100).h),
        // Minimum height instead of fixed
        child: IntrinsicHeight(
          child: Container(
            padding: EdgeInsets.all((isTablet() ? 8 : 10).h),
            decoration: BoxDecoration(
              color:
                  (context.isDarkMode ? AppColors.cardDarkColor : Colors.white),
              borderRadius: BorderRadius.circular(16.r),

              border: Border.all(
                color:
                    context.isDarkMode
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      context.isDarkMode
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8.r,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all((isTablet() ? 6 : 8).w),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: sz(18, seprateTabletSize: 14).sp,
                  ),
                ),
                SizedBox(height: 8.h),
                CustomText(
                  textAlign: TextAlign.center,
                  text: title,
                  fontSize: sz(12, seprateTabletSize: 9),
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: value,
                  fontSize: sz(16, seprateTabletSize: 11),
                  fontWeight: FontWeight.bold,
                  color:
                      valueColor == Colors.transparent
                          ? Theme.of(context).colorScheme.onSurface
                          : valueColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
