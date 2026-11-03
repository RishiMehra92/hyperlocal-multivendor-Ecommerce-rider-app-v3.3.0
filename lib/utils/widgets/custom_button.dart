import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';

import 'custom_text.dart';

import '../../../../config/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? textSize;
  final double? borderRadius;
  final bool isLoading;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? borderColor;
  final double? borderWidth;
  final FontWeight? fontWeight;
  final double? elevation;
  final Color? shadowColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.textSize,
    this.width,
    this.height,
    this.borderRadius,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.shrinkWrap = false,
    this.padding,
    this.textStyle,
    this.borderColor,
    this.borderWidth,
    this.fontWeight,
    this.elevation,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: Colors.grey,
        backgroundColor: backgroundColor ?? AppColors.primaryColor,
        foregroundColor: textColor ?? Colors.white,
        minimumSize: shrinkWrap ? Size.zero : null,
        tapTargetSize: shrinkWrap ? MaterialTapTargetSize.shrinkWrap : null,
        padding:
            padding ??
            EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical:
                  (isTablet(context: context)
                          ? isLoading
                              ? 11
                              : 10
                          : isLoading
                          ? 8
                          : 15)
                      .h,
            ), // Make padding responsive
        shape:
            borderColor != null && borderWidth != null
                ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    (borderRadius ?? 7).r,
                  ), // Make border radius responsive
                  side: BorderSide(color: borderColor!, width: borderWidth!),
                )
                : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    (borderRadius ?? 7).r,
                  ), // Make border radius responsive
                ),
        elevation: elevation ?? 2,
        shadowColor: shadowColor ?? Colors.black.withValues(alpha: 0.2),
      ),
      child:
          isLoading
              ? CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              )
              : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, SizedBox(width: 8.w)],
                  CustomText(
                    text: text,
                    fontSize:
                        textSize ?? (isTablet(context: context) ? 11 : 15),
                    fontWeight: fontWeight ?? FontWeight.w600,
                    color: textStyle?.color ?? Colors.white,
                  ),
                  if (trailingIcon != null) ...[
                    SizedBox(width: 8.w),
                    trailingIcon!,
                  ],
                ],
              ),
    );

    if (shrinkWrap) {
      return button;
    }

    return SizedBox(
      width: (width ?? 192).w, // Make width responsive
      // height: (height ?? 50).h, // Make height responsive
      child: button,
    );
  }
}

// Variant with different styles
class CustomButtonVariant extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final double? width;
  final double? height;
  final bool isLoading;
  final Widget? icon;

  const CustomButtonVariant({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.width,
    this.height,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = const Color(0xFF1C6D2B);
        textColor = Colors.white;
        borderColor = const Color(0xFF1C6D2B);
        break;
      case ButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        textColor = const Color(0xFF1C6D2B);
        borderColor = const Color(0xFF1C6D2B);
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = const Color(0xFF1C6D2B);
        borderColor = const Color(0xFF1C6D2B);
        break;
    }

    return SizedBox(
      width: width ?? 192,
      height: height ?? 55,
      child:
          variant == ButtonVariant.outline
              ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: borderColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: _buildChild(),
              )
              : ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: textColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  elevation: variant == ButtonVariant.primary ? 2 : 0,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                ),
                child: _buildChild(),
              ),
    );
  }

  Widget _buildChild() {
    return isLoading
        ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        )
        : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            CustomText(
              text: text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ],
        );
  }
}

enum ButtonVariant { primary, secondary, outline }
