// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/screens/feed_page/view/map/widgets/unified_map_widget.dart';
import '../../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../model/available_orders.dart';
import '../../../bloc/order_details_bloc/order_details_bloc.dart';
import '../../../bloc/order_details_bloc/order_details_event.dart';
import '../../../bloc/order_details_bloc/order_details_state.dart';
import 'widgets/index.dart';

class MapDeliveryPage extends StatefulWidget {
  final Orders order;
  final String? currentLat;
  final String? currentLng;
  final bool autoOpenBottomSheet;
  final int? sourceTab;

  const MapDeliveryPage({
    super.key,
    required this.order,
    this.currentLat,
    this.currentLng,
    this.autoOpenBottomSheet = true,
    this.sourceTab,
  });

  @override
  State<MapDeliveryPage> createState() => _MapDeliveryPageState();
}

class _MapDeliveryPageState extends State<MapDeliveryPage> {
  double? _distanceToStores;

  @override
  void initState() {
    super.initState();
    // Hydrate the BLoC immediately on startup with the latest order details
    context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.order.id!));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderDetailsBloc, OrderDetailsState>(
      builder: (context, state) {
        // Use the reactively updated order from state, falling back to initial widget order
        final activeOrder = state.order ?? widget.order;
        final status = activeOrder.status?.toLowerCase() ?? 'assigned';

        // Dynamically switch routing mode based on status
        final bool isPostPickup =
            status == 'out_for_delivery' ||
            status == 'collected' ||
            status == 'delivered';
        final mapViewMode =
            isPostPickup
                ? MapViewMode.customerDelivery
                : MapViewMode.storePickup;

        // Dynamic App Bar title based on status
        final String pageTitle =
            isPostPickup
                ? context.tr('deliveryRoute')
                : context.tr('storePickupRoute');

        return WillPopScope(
          onWillPop: () async {
            context.pop(true);
            return false;
          },
          child: Scaffold(
            appBar: CustomAppBar(
              title: pageTitle,
              showRefreshButton: false,
              showThemeToggle: false,
            ),
            body: UnifiedMapWidget(
              mode: mapViewMode,
              order: activeOrder,
              onDistanceCalculated: (distance) {
                if (mounted) {
                  setState(() {
                    _distanceToStores = distance;
                  });
                }
              },
              topOverlays: [
                // Distance Indicator Widget
                Positioned(
                  top: 20.h,
                  left: 20.w,
                  child: DistanceIndicatorWidget(distance: _distanceToStores),
                ),
              ],
              // bottomCard: BottomCardWidget(
              //   order: activeOrder,
              //   hasReachedDestination: isPostPickup, // Displays store list vs customer address reactively
              //   filteredStores: filteredStores,
              //   shouldShowNumbers: filteredStores.length > 1,
              //   distanceToStores: _distanceToStores,
              //   onViewDetailsPressed: () => context.pop(), // Pops back to OrderDetailsPage
              // ),
            ),
          ),
        );
      },
    );
  }
}
