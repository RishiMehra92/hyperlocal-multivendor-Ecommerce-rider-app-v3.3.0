import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../config/helper.dart';

class WithdrawalEmptyState extends StatelessWidget {
  const WithdrawalEmptyState({super.key});

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
              Icons.account_balance_wallet_outlined,
              size: (isTablet() ? 40 : 48).r,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          SizedBox(height: 24.h),
          CustomText(
            text: context.tr('noWithdrawalsYet'),
            fontSize: sz(20, seprateTabletSize: 16),
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: CustomText(
              text: context.tr('noWithdrawalsYetDescription'),
              fontSize: sz(16, seprateTabletSize: 12),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
