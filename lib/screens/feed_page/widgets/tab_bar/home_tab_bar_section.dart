// home_tab_bar_section.dart
import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/feed_page/bloc/available_orders_bloc/available_orders_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/available_orders_bloc/available_orders_state.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/return_orders_list_bloc/return_order_list_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/return_orders_list_bloc/return_order_list_state.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';

import '../../../../config/colors.dart';

class HomeTabBarSection extends StatelessWidget {
  final TabController tabController;

  const HomeTabBarSection({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AvailableOrdersBloc, AvailableOrdersState>(
      builder: (context, availableState) {
        return BlocBuilder<ReturnOrderListBloc, ReturnOrderListState>(
          builder: (context, returnState) {
            final ordersCount = availableState.totalOrders;
            final pickupsCount = returnState.totalOrders;

            return TabBar(
              controller: tabController,
              isScrollable: false,
              physics: const BouncingScrollPhysics(),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 3.0.w,
                  color: AppColors.primaryColor,
                ),
              ),
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: sz(15, seprateTabletSize: 25),
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: sz(14, seprateTabletSize: 22),
              ),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 16,
              ), // Space between tabs
              dividerColor: Colors.transparent,
              tabs: [
                _buildTab(
                  context.tr('availableOrders', fallback: "New Orders"),
                  ordersCount,
                ),
                _buildTab(
                  context.tr('availPickupOrders', fallback: "New Pickups"),
                  pickupsCount,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTab(String title, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            text: title,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w500,
          ),
          if (count > 0) ...[
            SizedBox(width: 6.w),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: CustomText(
                text: count.toString(),
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
