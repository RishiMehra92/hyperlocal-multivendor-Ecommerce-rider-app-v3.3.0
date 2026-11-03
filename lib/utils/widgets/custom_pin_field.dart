import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:hyper_local/config/colors.dart';

class PinFieldAuto extends StatelessWidget {
  final TextEditingController? controller;
  final String? currentCode;
  final int codeLength;
  final ValueChanged<String?>? onCodeChanged;
  final ValueChanged<String>? onCodeSubmitted;
  final double gapSpace;
  final double fontSize;
  final TextInputType keyboardType;

  const PinFieldAuto({
    super.key,
    this.controller,
    this.currentCode,
    this.codeLength = 6,
    this.onCodeChanged,
    this.onCodeSubmitted,
    this.gapSpace = 10,
    this.fontSize = 20,
    this.keyboardType = TextInputType.number,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PinFieldAutoFill(
      controller: controller,
      autoFocus: true,
      currentCode: currentCode ?? controller?.text,
      cursor: Cursor(
        width: 2,
        height: 24,
        radius: const Radius.circular(1),
        enabled: true,
        color: AppColors.primaryColor,
      ),
      codeLength: codeLength,
      keyboardType: keyboardType,
      onCodeChanged: onCodeChanged,
      onCodeSubmitted: onCodeSubmitted,
      decoration: BoxLooseDecoration(
        radius: Radius.circular(10.r),
        strokeWidth: 1.5,
        gapSpace: gapSpace,
        textStyle: TextStyle(
          fontSize: fontSize.sp,
          color: isDark ? Colors.white : AppColors.textColor,
          fontWeight: FontWeight.bold,
        ),
        strokeColorBuilder: const FixedColorBuilder(AppColors.primaryColor),
      ),
    );
  }
}
