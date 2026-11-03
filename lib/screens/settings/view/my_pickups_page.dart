import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/screens/feed_page/widgets/my_pickups/my_pickups_section.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/pickup_orders_list_bloc/pickup_order_list_bloc.dart';

class MyPickupsPage extends StatelessWidget {
  const MyPickupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PickupOrderListBloc, PickupOrderListState>(
      builder: (context, state) {
        final totalOrders = state.totalOrders;
        final countText =
            (state.status == ApiStatus.success ||
                    state.status == ApiStatus.loading &&
                        state.orders.isNotEmpty)
                ? " ($totalOrders)"
                : "";

        return CustomScaffold(
          appBar: CustomAppBar(
            title:
                "${context.tr('pickupOrders', fallback: "Pickup Orders")}$countText",
          ),
          body: const MyPickupsSection(isDeliveryBoyActive: true),
        );
      },
    );
  }
}
