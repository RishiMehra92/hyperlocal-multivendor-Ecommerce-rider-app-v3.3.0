import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../config/colors.dart';
import 'package:hyper_local/config/app_images.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';

class EmptyStateWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final bool isLoading;

  const EmptyStateWidget({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.onRetry,
    this.showRetryButton = true,
    this.isLoading = false,
  });

  // Factory for "No data yet" state
  factory EmptyStateWidget.noData({
    Key? key,
    String? title,
    String? subtitle,
    IconData? icon,
    required VoidCallback onRetry,
  }) {
    return EmptyStateWidget(
      key: key,
      title: title ?? "No data yet",
      subtitle: subtitle ?? "Your information will appear here soon",
      icon: icon ?? Icons.bar_chart_outlined,
      onRetry: onRetry,
    );
  }

  // Factory for error state with retry
  factory EmptyStateWidget.error({
    Key? key,
    String? title,
    String? subtitle,
    IconData? icon,
    required VoidCallback onRetry,
    bool isLoading = false,
  }) {
    return EmptyStateWidget(
      key: key,
      title: title ?? "Unable to load data",
      subtitle: subtitle ?? "Please check your connection and try again",
      icon: icon ?? Icons.wifi_off_outlined,
      onRetry: onRetry,
      showRetryButton: true,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use localized strings if title/subtitle are null
    final String displayTitle =
        title ??
        (showRetryButton
            ? context.tr('unableToLoadData')
            : context.tr('noDataYet'));

    final String displaySubtitle =
        subtitle ??
        (showRetryButton
            ? context.tr('checkConnectionAndTryAgain')
            : context.tr('dataWillAppearHere'));

    final IconData displayIcon =
        icon ??
        (showRetryButton ? Icons.wifi_off_outlined : Icons.inbox_outlined);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon appearance
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (value * 0.2), // subtle grow effect
                    child: child,
                  ),
                );
              },
              child: Icon(
                displayIcon,
                size: 96.r,
                color: Colors.grey.withValues(alpha: 0.6),
              ),
            ),

            SizedBox(height: 32.h),

            CustomText(
              text: displayTitle,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: CustomText(
                text: displaySubtitle,
                fontSize: 16,
                color: Colors.grey.shade600,
                textAlign: TextAlign.center,
              ),
            ),

            if (showRetryButton) ...[
              SizedBox(height: 40.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onRetry,
                  icon:
                      isLoading
                          ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                          : Icon(Icons.refresh, size: 20.r),
                  label: CustomText(
                    text:
                        isLoading
                            ? context.tr('loading')
                            : context.tr('tryAgain'),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),

              // SizedBox(height: 16.h),
              // Text(
              //   context.tr('pullToRefresh'),
              //   style: TextStyle(
              //     fontSize: 14.sp,
              //     color: Colors.grey.shade600.withValues(alpha: 0.7),
              //   ),
              // ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String? message;
  final double? imageWidth;
  final double? imageHeight;
  final VoidCallback onRetry;
  final String retryButtonText;

  const ErrorStateWidget({
    super.key,
    this.message,
    this.imageWidth = 220,
    this.imageHeight = 100,
    required this.onRetry,
    this.retryButtonText = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    final Widget visualWidget = Image.asset(
      AppImages.noData,
      width: 250,
      height: 180,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if image fails to load (e.g. wrong path)
        return Icon(
          TablerIcons.circle_x_filled,
          size: 64.sp,
          color: Theme.of(context).colorScheme.error,
        );
      },
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            visualWidget,
            SizedBox(height: 24.h),
            CustomText(
              text:
                  context.tr('unableToLoadData', fallback: 'Unable to load data'),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: 12.h),
              CustomText(
                text: message!,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: CustomText(
                text: retryButtonText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
