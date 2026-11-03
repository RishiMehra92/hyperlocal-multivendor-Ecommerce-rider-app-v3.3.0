import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../utils/widgets/custom_card.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../config/helper.dart';
import '../../model/withdrawal_model.dart';

class WithdrawalSummaryCards extends StatelessWidget {
  final WithdrawalResponse response;

  const WithdrawalSummaryCards({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context,
              'Total Requests',
              '${response.data?.total ?? 0}',
              Icons.receipt_long,
              theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              context,
              'Pending',
              '${response.data?.data.where((w) => w.status?.toLowerCase() == 'pending').length ?? 0}',
              Icons.pending,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      padding: EdgeInsets.all((isTablet() ? 12 : 16).w),
      borderRadius: 12.r,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all((isTablet() ? 6 : 8).w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: sz(20, seprateTabletSize: 16).sp,
                ),
              ),
              const Spacer(),
              Flexible(
                child: CustomText(
                  text: value,

                  fontSize: sz(24, seprateTabletSize: 18),
                  fontWeight: FontWeight.bold,
                  color: color,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: title,

            fontSize: sz(14, seprateTabletSize: 10),
            fontWeight: FontWeight.w500,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}
