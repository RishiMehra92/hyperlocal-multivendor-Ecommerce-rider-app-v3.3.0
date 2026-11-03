import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:slide_action/slide_action.dart';
import '../../config/colors.dart';
import 'custom_text.dart';
import 'loading_widget.dart';

class CustomSlideAction extends StatelessWidget {
  final VoidCallback action;
  final String text;
  final bool isLoading;
  final Color? trackColor;
  final Color? thumbIconColor;
  final IconData? thumbIcon;

  const CustomSlideAction({
    super.key,
    required this.action,
    required this.text,
    required this.isLoading,
    this.trackColor,
    this.thumbIconColor,
    this.thumbIcon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTrackColor = trackColor ?? AppColors.greenTrackColor;
    final effectiveThumbIconColor = thumbIconColor ?? AppColors.greenTrackColor;
    final effectiveThumbIcon = thumbIcon ?? Icons.keyboard_double_arrow_right;

    return SlideAction(
      thumbWidth: 80.w,
      action: () async {
        if (!isLoading) {
          // Trigger device vibration.
          // Note: Vibration/haptic feedback does not require runtime permissions on iOS or Android,
          // but the android.permission.VIBRATE permission has been added to AndroidManifest.xml.
          await HapticFeedback.vibrate();
          action();
        }
      },
      trackBuilder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: effectiveTrackColor,
            borderRadius: BorderRadius.circular(20.r),
          ),
          alignment: Alignment.center,
          child: CustomText(
            text: text,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            textAlign: TextAlign.center,
          ),
        );
      },
      thumbBuilder: (context, state) {
        return Container(
          margin: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
          ),
          alignment: Alignment.center,
          child:
              isLoading
                  ? const LoadingWidget()
                  : Icon(
                    effectiveThumbIcon,
                    color: effectiveThumbIconColor,
                    size: 30,
                  ),
        );
      },
    );
  }
}
