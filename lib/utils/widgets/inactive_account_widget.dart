import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/colors.dart';
import '../../config/app_images.dart';
import 'custom_text.dart';
import 'custom_button.dart';

class InactiveAccountWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const InactiveAccountWidget({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Inactive account image
            Image.asset(
              AppImages.inactive,
              width: 140.w,
              height: 140.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 24.h),

            // Title
            CustomText(
              text:
                  context.tr('accountInactive', fallback: 'Account Inactive'),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),

            // Message
            CustomText(
              text: message ?? 'Your account is currently inactive.',
              textAlign: TextAlign.center,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            SizedBox(height: 24.h),

            // Retry button (optional)
            if (onRetry != null)
              CustomButton(
                onPressed: onRetry,
                text: context.tr('retry', fallback: 'Retry'),
                backgroundColor: AppColors.primaryColor,
                textColor: Colors.white,
                borderRadius: 12,
                width: 140,
              ),
          ],
        ),
      ),
    );
  }
}
