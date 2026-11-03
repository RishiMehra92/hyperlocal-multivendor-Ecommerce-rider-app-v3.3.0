import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../bloc/withdrawal_bloc.dart';
import '../../bloc/withdrawal_event.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../config/helper.dart';

class WithdrawalErrorState extends StatelessWidget {
  final String errorMessage;

  const WithdrawalErrorState({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all((isTablet() ? 16 : 24).w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              Icons.error_outline,
              size: (isTablet() ? 40 : 48).r,
              color: theme.colorScheme.error,
            ),
          ),
          SizedBox(height: 24.h),
          CustomText(
            text: context.tr('somethingWentWrong'),
            fontSize: sz(20, seprateTabletSize: 16),
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: CustomText(
              text: errorMessage,
              fontSize: sz(16, seprateTabletSize: 12),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              context.read<WithdrawalBloc>().add(FetchWithdrawals());
            },
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.onPrimary,
              size: sz(20, seprateTabletSize: 18).sp,
            ),
            label: CustomText(
              text: context.tr('tryAgain'),
              fontSize: sz(16, seprateTabletSize: 12),
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimary,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
