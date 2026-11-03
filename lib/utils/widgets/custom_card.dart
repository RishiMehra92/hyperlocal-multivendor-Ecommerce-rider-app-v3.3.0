import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/extensions.dart';
import '../../config/colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  final double? borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.gradient,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.boxShadow,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = context.isDarkMode;

    final cardWidget = Container(
      margin: margin,
      width: width ?? double.infinity,
      height: height,
      padding: padding ?? EdgeInsets.all(15.h),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDarkTheme ? AppColors.cardDarkColor : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius ?? 16.r),

        border:
            border ??
            Border.all(
              color:
                  isDarkTheme
                      ? Colors.grey.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
        gradient: gradient,
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color:
                    isDarkTheme
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8.r,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 16.r),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}
