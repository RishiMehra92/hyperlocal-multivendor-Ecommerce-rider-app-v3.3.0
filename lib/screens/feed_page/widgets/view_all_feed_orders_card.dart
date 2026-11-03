import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';

class ViewAllFeedOrdersCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ViewAllFeedOrdersCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,
                    fontWeight: FontWeight.bold,
                    fontSize: sz(16, seprateTabletSize: 12),
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: subtitle,
                    fontSize: sz(12, seprateTabletSize: 9),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
