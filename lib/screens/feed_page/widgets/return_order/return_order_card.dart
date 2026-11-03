import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/app_routes.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import 'package:hyper_local/utils/currency_formatter.dart';
import '../../bloc/return_order/accept_return_order_bloc/return_order_bloc.dart';
import '../../bloc/return_order/accept_return_order_bloc/return_order_event.dart';
import '../../bloc/return_order/accept_return_order_bloc/return_order_state.dart';
import '../../bloc/return_order/return_orders_list_bloc/return_order_list_bloc.dart';
import '../../bloc/return_order/return_orders_list_bloc/return_order_list_event.dart';
import '../../model/return_orders_list_model.dart';
import '../order_feed_card.dart';

class ReturnOrderCard extends StatelessWidget {
  final Pickups pickup;

  const ReturnOrderCard({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReturnOrderBloc(),
      child: BlocConsumer<ReturnOrderBloc, ReturnOrderState>(
        listener: (context, state) {
          if (state.status == ApiStatus.success) {
            ToastManager.show(
              context: context,
              message: state.message,
              type: ToastType.success,
            );
            context.read<ReturnOrderListBloc>().add(
              const FetchReturnOrders(forceRefresh: true),
            );
            context.push(
              AppRoutes.pickupOrderDetails,
              extra: {'returnId': pickup.id.toString()},
            );
          } else if (state.status == ApiStatus.failed) {
            ToastManager.show(
              context: context,
              message: state.errorMessage,
              type: ToastType.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == ApiStatus.loading;
          final store = pickup.store;
          final product = pickup.orderItem?.product;

          Widget? additionalInfo;
          if (product?.name != null) {
            additionalInfo = Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 10.r,
                  color: AppColors.primaryColor.withValues(alpha: 0.7),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: CustomText(
                    text: product!.name!,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor.withValues(alpha: 0.7),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }

          return OrderFeedCard(
            isPickup: true,
            expectedEarningText: CurrencyFormatter.formatAmount(
              context,
              pickup.earnings?.total ?? '0',
            ),
            orderIdText: "${pickup.orderId ?? "N/A"}",
            storeName: store?.name ?? 'Unknown Store',
            storeAddress: store?.address,
            additionalInfo: additionalInfo,
            actionText:
                isLoading
                    ? context.tr('accepting')
                    : context.tr('acceptReturn'),
            isLoading: isLoading,
            onAction: () {
              context.read<ReturnOrderBloc>().add(
                AcceptReturnOrder(returnId: pickup.id.toString()),
              );
            },
            badgeColor: Colors.orange,
            avatarGradientColors: const [Colors.orange, Colors.deepOrange],
          );
        },
      ),
    );
  }
}
