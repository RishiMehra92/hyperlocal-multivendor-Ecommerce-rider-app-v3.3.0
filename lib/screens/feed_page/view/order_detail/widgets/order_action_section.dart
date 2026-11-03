import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../config/colors.dart';
import '../../../../../config/helper.dart';
import '../../../../../utils/widgets/custom_button.dart';

class OrderActionSection extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const OrderActionSection({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: label,
        onPressed: onPressed,
        isLoading: isLoading,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
        borderRadius: 12.r,
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: (isTablet() ? 10 : 14).h,
        ),
        textStyle: TextStyle(
          fontSize: sz(15, seprateTabletSize: 11).sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
