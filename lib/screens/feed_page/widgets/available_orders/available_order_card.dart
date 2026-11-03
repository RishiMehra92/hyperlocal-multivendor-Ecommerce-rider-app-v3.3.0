import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/helper.dart';
import '../../../../config/colors.dart';
import '../../bloc/accept_order_bloc/accept_order_bloc.dart';
import '../../bloc/accept_order_bloc/accept_order_event.dart';
import '../../bloc/accept_order_bloc/accept_order_state.dart';
import '../../bloc/available_orders_bloc/available_orders_bloc.dart';
import '../../bloc/available_orders_bloc/available_orders_event.dart';
import '../../model/available_orders.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/app_routes.dart';
import '../../../../utils/widgets/toast_message.dart';
import '../order_feed_card.dart';

class AvailableOrderCard extends StatelessWidget {
  final Orders order;

  const AvailableOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AcceptOrderBloc, AcceptOrderState>(
      listenWhen: (previous, current) => current.orderId == order.id.toString(),
      listener: (context, state) {
        if (state.status == ApiStatus.success) {
          _navigateToMapDeliveryPage(context, order);
          context.read<AvailableOrdersBloc>().add(AllAvailableOrdersList(forceRefresh: true));
        } else if (state.status == ApiStatus.failed) {
          ToastManager.show(
            context: context,
            message:
                state.errorMessage.isNotEmpty ? state.errorMessage : context.tr('failedToUpdateStatus'),
            type: ToastType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == ApiStatus.loading && state.orderId == order.id.toString();
        final storeName = order.deliveryRoute?.routeDetails?.first.storeName ?? context.tr('store');

        final addressParts = <String>[];
        if (order.shippingAddress1 != null) {
          addressParts.add(order.shippingAddress1!);
        }
        if (order.shippingAddress2 != null) {
          addressParts.add(order.shippingAddress2!);
        }
        final customerAddress = addressParts.isNotEmpty ? addressParts.join(', ') : null;

        // Map route details for multi-store layout (excluding customer locations where storeId is null)
        List<Map<String, String?>>? stores;
        if (order.deliveryRoute?.routeDetails != null && order.deliveryRoute!.routeDetails!.isNotEmpty) {
          stores =
              order.deliveryRoute!.routeDetails!.where((detail) => detail.storeId != null && detail.storeId != 0).map((
                detail,
              ) {
                return {'name': detail.storeName, 'address': detail.address};
              }).toList();
        }

        return OrderFeedCard(
          isPickup: false,
          expectedEarningText: null, // CurrencyFormatter.formatAmount(context, order.earnings?.total ?? '0'),
          orderIdText: "${order.id ?? "N/A"}",
          riderTipAmount: order.riderTipAmount,
          storeName: storeName,
          storeAddress: null, // Not used if stores is populated, or shouldn't be customer address
          dropName: context.tr('customerLocation', fallback: 'Customer Location'),
          dropAddress: customerAddress,
          stores: stores,
          distanceText:
              order.deliveryRoute?.totalDistance != null
                  ? '${order.deliveryRoute!.totalDistance!.toStringAsFixed(1)} ${context.tr('km')}'
                  : null,
          actionText: isLoading ? context.tr('accepting') : context.tr('acceptOrder'),
          isLoading: isLoading,
          onAction: () {
            context.read<AcceptOrderBloc>().add(AcceptOrder(order.id!));
          },
          badgeColor: AppColors.primaryColor,
          avatarGradientColors: const [Colors.amber, Colors.orange],
        );
      },
    );
  }

  // Navigation method for map delivery page
  Future<void> _navigateToMapDeliveryPage(BuildContext context, Orders order) async {
    debugPrint('[AvailableOrderCard] _navigateToMapDeliveryPage called for order ${order.id}');
    bool hasValidCoordinates = false;
    String? destinationLat;
    String? destinationLng;

    if (order.deliveryRoute?.routeDetails != null && order.deliveryRoute!.routeDetails!.isNotEmpty) {
      final storeLocation = order.deliveryRoute!.routeDetails!.first;
      hasValidCoordinates = storeLocation.latitude != null && storeLocation.longitude != null;
      if (hasValidCoordinates) {
        destinationLat = storeLocation.latitude.toString();
        destinationLng = storeLocation.longitude.toString();
        debugPrint(
          '[AvailableOrderCard] Found store coordinates in route details: lat=$destinationLat, lng=$destinationLng',
        );
      }
    }

    if (!hasValidCoordinates) {
      hasValidCoordinates = order.shippingLatitude != null && order.shippingLongitude != null;
      if (hasValidCoordinates) {
        destinationLat = order.shippingLatitude.toString();
        destinationLng = order.shippingLongitude.toString();
        debugPrint(
          '[AvailableOrderCard] Found fallback shipping coordinates: lat=$destinationLat, lng=$destinationLng',
        );
      }
    }

    if (hasValidCoordinates && destinationLat != null && destinationLng != null) {
      debugPrint('[AvailableOrderCard] Pushing AppRoutes.mapDelivery for order ${order.id}');
      try {
        context
            .push(
              AppRoutes.mapDelivery,
              extra: {
                'order': order,
                'currentLat': destinationLat,
                'currentLng': destinationLng,
                'autoOpenBottomSheet': false, // Do not auto-open bottom sheet upon acceptance
                'sourceTab': 0,
              },
            )
            .then((_) {
              if (context.mounted) {
                context.read<AvailableOrdersBloc>().add(AllAvailableOrdersList(forceRefresh: true));
              }
            });
      } catch (e) {
        debugPrint('[AvailableOrderCard] Error pushing map route: $e');
        ToastManager.show(
          context: context,
          message: context.tr('navigationError', positionalArgs: [e.toString()]),
          type: ToastType.error,
        );
      }
    } else {
      debugPrint('[AvailableOrderCard] Error: Store pickup coordinates not available for order ${order.id}');
      ToastManager.show(
        context: context,
        message: context.tr('storePickupCoordinatesNotAvailable'),
        type: ToastType.error,
      );
    }
  }
}
