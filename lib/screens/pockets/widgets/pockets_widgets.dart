import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/currency_formatter.dart';
import 'package:hyper_local/utils/extensions.dart';

import '../../../utils/widgets/custom_card.dart';
import 'package:hyper_local/config/app_images.dart';

/// A custom painter to draw the decorative background waves for the wallet card.

/// The top Available Balance card with background waves and the "Request Withdraw" action.
class AvailableBalanceCard extends StatelessWidget {
  final double availableBalance;
  final String titleText;
  final String buttonText;
  final VoidCallback onWithdrawRequested;

  const AvailableBalanceCard({
    super.key,
    required this.availableBalance,
    required this.titleText,
    required this.buttonText,
    required this.onWithdrawRequested,
  });

  @override
  Widget build(BuildContext context) {
    // Premium blue gradient matching the mockup

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: .7),
            AppColors.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: const DecorationImage(
          image: AssetImage(AppImages.cardBackgroundImage),
          fit: BoxFit.fill,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0056C6).withValues(alpha: 0.25),
            blurRadius: 16.r,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            CustomText(
              text: titleText,
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            // Balance Amount
            CustomText(
              text: CurrencyFormatter.formatAmount(
                context,
                availableBalance.toStringAsFixed(2),
              ),
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),

            // Request Withdraw Button
            CustomButton(
              text: buttonText,
              onPressed: onWithdrawRequested,
              backgroundColor: Colors.black,
              borderRadius: 5,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              shrinkWrap: true,
              textSize: 13,
              fontWeight: FontWeight.w700,
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              trailingIcon: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  TablerIcons.send,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Side-by-side metric cards (used for Blocked and Total Balance).
class BalanceMetricCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color titleColor;

  const BalanceMetricCard({
    super.key,
    required this.title,
    required this.amount,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.all(16.w),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: title,
            color: titleColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: CurrencyFormatter.formatAmount(
              context,
              amount.toStringAsFixed(2),
            ),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

/// Tinted summary cards for Earning Summary metrics (used for Pending and Paid).
class EarningSummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color iconBgColor;
  final Color cardBgColor;
  final Color amountColor;

  const EarningSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconBgColor,
    required this.cardBgColor,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = context.isDarkMode;

    // Use adapted colors for dark mode to maintain readability and beauty

    return CustomCard(
      backgroundColor: isDarkTheme ? null : cardBgColor,
      border: Border.all(
        color:
            isDarkTheme
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.transparent,
        width: 1,
      ),
      padding: const EdgeInsets.all(12),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: Colors.black, size: 25),
          ),
          SizedBox(height: 16.h),
          // Title label
          CustomText(
            text: title,
            color: context.isDarkMode ? null : const Color(0xff3a3a3a),
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 4.h),
          // Amount value
          CustomText(
            text: CurrencyFormatter.formatAmount(
              context,
              amount.toStringAsFixed(2),
            ),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: amountColor,
          ),
        ],
      ),
    );
  }
}

/// Reusable navigation tile for pockets actions (used for Order Earnings, Cash Collection, and View Transactions).
class PocketsNavigationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final double? amount;
  final bool isPrimaryColorTinted;
  final Color? subtitleColor;
  final bool showAmount;

  const PocketsNavigationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.amount,
    this.isPrimaryColorTinted = false,
    this.subtitleColor,
    this.showAmount = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = context.isDarkMode;

    // Background color configuration
    final cardBg =
        isPrimaryColorTinted
            ? const Color(0xFFB7CFFF).withValues(alpha: .15)
            : (isDarkTheme ? AppColors.cardDarkColor : Colors.white);

    // Icon background color configuration
    final iconBg =
        isPrimaryColorTinted
            ? const Color(0xFF0055FF).withValues(alpha: .15)
            : (isDarkTheme
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF3F3F3));

    // Icon color configuration
    final iconColor =
        isPrimaryColorTinted
            ? null
            : (isDarkTheme ? Colors.white : Colors.black87);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: CustomCard(
        backgroundColor: cardBg,
        padding: EdgeInsets.symmetric(
          horizontal: isPrimaryColorTinted ? 12 : 16.w,
          vertical: 14.h,
        ),
        child: Row(
          children: [
            // Customizable Icon
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(
                  isPrimaryColorTinted ? 7 : 14,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 12.w),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,
                    fontSize: 16,
                    fontWeight:
                        isPrimaryColorTinted
                            ? FontWeight.bold
                            : FontWeight.w700,
                    color:
                        (isPrimaryColorTinted && !isDarkTheme)
                            ? const Color(0xff3a3a3a)
                            : null,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    CustomText(
                      text: subtitle,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ],
                ],
              ),
            ),
            // Optional Amount
            if (amount != null && showAmount) ...[
              CustomText(
                text: CurrencyFormatter.formatAmount(
                  context,
                  amount!.toStringAsFixed(2),
                ),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color:
                    isPrimaryColorTinted
                        ? const Color(0xFF0055FF)
                        : AppColors.primaryColor,
              ),
              SizedBox(width: 12.w),
            ],
            // Trailing Chevron Arrow
            Icon(Icons.chevron_right, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
