import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../utils/widgets/custom_button.dart';

class EmptyTransactionsState extends StatelessWidget {
  final VoidCallback onRetry;

  const EmptyTransactionsState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 100.sp),

            SizedBox(height: 24.h),

            Text(
              context.tr('noTransactionYet'),
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12.h),

            Text(
              "${context.tr('noTransactionDescriptionMsg')}\n"
              "${context.tr('noTransactionDescriptionSecondaryMsg')}",
              style: TextStyle(
                fontSize: 15.sp,
                color: colorScheme.tertiary.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 40.h),

            CustomButton(
              text: context.tr('retry'),
              onPressed: onRetry,
            ),

            // Retry Button
            // SizedBox(
            //   width: 180,
            //   child: CustomButton(
            //     onPressed: onRetry,
            //     child: Row(
            //       crossAxisAlignment: CrossAxisAlignment.center,
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         Icon(Icons.refresh_rounded, size: 20),
            //         SizedBox(width: 10,),
            //         Text(context.tr('retry')),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
