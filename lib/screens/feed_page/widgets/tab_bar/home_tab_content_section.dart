import 'package:flutter/material.dart';
import 'package:hyper_local/screens/feed_page/widgets/return_order/return_order_page.dart';
import '../available_orders/available_orders_section.dart';

class HomeTabContentSection extends StatelessWidget {
  final TabController tabController;
  final bool isDeliveryBoyActive;
  final bool isDarkTheme;

  const HomeTabContentSection({
    super.key,
    required this.tabController,
    required this.isDeliveryBoyActive,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TabBarView(
        controller: tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          AvailableOrdersSection(isDeliveryBoyActive: isDeliveryBoyActive),
          ReturnOrdersSection(isDeliveryBoyActive: isDeliveryBoyActive),
        ],
      ),
    );
  }
}
