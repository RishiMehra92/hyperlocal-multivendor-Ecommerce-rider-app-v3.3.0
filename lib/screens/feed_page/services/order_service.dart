import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import '../model/available_orders.dart';

class OrderService {
  static bool areAllItemsCollected(Orders? order) {
    if (order?.items == null || order!.items!.isEmpty) {
      return false;
    }

    int collectedCount = getCollectedItemsCount(order);
    return collectedCount >= order.items!.length;
  }

  static bool areAllItemsStrictlyCollected(Orders? order) {
    if (order?.items == null || order!.items!.isEmpty) {
      return false;
    }

    return order.items!.every(
      (item) => item.status?.toLowerCase() == 'collected',
    );
  }

  static List<int> getCollectedItemIds(Orders? order) {
    if (order?.items == null || order!.items!.isEmpty) {
      return const [];
    }

    return order.items!
        .where(
          (item) =>
              item.id != null && item.status?.toLowerCase() == 'collected',
        )
        .map((item) => item.id!)
        .toList();
  }

  static int getTotalItems(Orders? order) {
    return order?.items?.length ?? 0;
  }

  static int getCollectedItemsCount(Orders? order) {
    if (order?.items == null || order!.items!.isEmpty) {
      return 0;
    }

    int collectedCount = 0;
    for (var item in order.items!) {
      bool isItemCollected =
          item.status?.toLowerCase() == 'collected' ||
          item.status?.toLowerCase() == 'delivered';
      if (isItemCollected) {
        collectedCount++;
      }
    }
    return collectedCount;
  }

  static bool hasItemsRequiringOtp(Orders? order) {
    if (order == null) return false;
    if (order.deliveryOtpMode?.toLowerCase() == 'order_wise') {
      return order.deliveryOtpRequired ?? false;
    }
    if (order.items == null || order.items!.isEmpty) {
      return false;
    }
    for (var item in order.items!) {
      if ((item.requiresOtp == true) || (item.product?.requiresOtp == 1)) {
        return true;
      }
    }
    return false;
  }

  static bool areAllOtpItemsVerified(Orders? order) {
    if (order == null) return true;
    if (order.deliveryOtpMode?.toLowerCase() == 'order_wise') {
      return !(order.deliveryOtpRequired ?? false) ||
          (order.deliveryOtpVerified ?? false);
    }
    final otpItems = order.items?.where(
      (item) => (item.requiresOtp == true) || (item.product?.requiresOtp == 1),
    );

    // If there are no items requiring OTP, return false (no OTP verification needed)
    if (otpItems == null || otpItems.isEmpty) return false;

    // Otherwise, check if all OTP items are verified
    return otpItems.every((item) => item.otpVerified == 1);
  }

  static bool hasCodItems(Orders? order) {
    return order?.paymentMethod?.toLowerCase() == 'cod';
  }

  static bool areAllItemsDelivered(Orders? order) {
    if (order?.items == null || order!.items!.isEmpty) return false;

    final isOrderWise = order.deliveryOtpMode?.toLowerCase() == 'order_wise';

    int deliveredCount = 0;
    int totalCount = order.items!.length;

    for (var item in order.items!) {
      // Check if item is delivered from API status
      bool isDelivered = item.status?.toLowerCase() == 'delivered';

      // For items requiring OTP, also check if OTP is verified (only in item_wise mode)
      bool requiresOtp =
          !isOrderWise &&
          ((item.requiresOtp == true) || (item.product?.requiresOtp == 1));
      bool isOtpVerified = item.otpVerified == 1;

      bool isItemDelivered;
      if (requiresOtp) {
        // For OTP items: must be delivered AND OTP verified
        isItemDelivered = isDelivered && isOtpVerified;
      } else {
        // For non-OTP items: just needs to be delivered
        isItemDelivered = isDelivered;
      }

      if (isItemDelivered) {
        deliveredCount++;
      }
    }

    return deliveredCount == totalCount;
  }

  static int getTargetTabForNavigation(int? sourceTab, bool from) {
    // If sourceTab is explicitly provided, use that
    if (sourceTab != null) {
      return sourceTab;
    }

    // Otherwise, determine based on the 'from' parameter
    // from = false means coming from Available Orders (tab 0)
    // from = true means coming from My Orders (tab 1)
    int targetTab = from ? 1 : 0;

    return targetTab;
  }

  static void collectAllItems({
    required Orders? order,
    required Set<String> collectedItems,
    required Function(String) onItemCollected,
    required Function(String) onError,
  }) {
    if (order?.items == null || order!.items!.isEmpty) {
      onError('No items to collect');
      return;
    }

    try {
      // Collect only uncollected items
      for (var item in order.items!) {
        if (item.id != null) {
          // Only collect items that are not already collected
          bool isCollectedFromApi =
              item.status?.toLowerCase() == 'collected' ||
              item.status?.toLowerCase() == 'delivered';

          if (!isCollectedFromApi) {
            onItemCollected(item.id.toString());
          }
        }
      }
    } catch (e) {
      onError('Error collecting items: ${e.toString()}');
    }
  }

  static String getStatusText(BuildContext context, Orders? order, bool from) {
    if (!from) {
      // When from is false (collection mode)
      bool allCollected = areAllItemsCollected(order);

      if (allCollected) {
        // If all items are collected, show "View Delivery Route" regardless of order status
        return context.tr('viewPickupRoute');
      } else {
        // Show status text when not all items are collected
        int collectedCount = getCollectedItemsCount(order);
        return '${context.tr('collectAllItems')} ($collectedCount/${getTotalItems(order)})';
      }
    } else {
      // When from is true (delivery mode)
      if (areAllItemsDelivered(order)) {
        return context.tr('done');
      } else if (areAllItemsCollected(order)) {
        return context.tr('viewPickupRoute');
      } else {
        int collectedCount = getCollectedItemsCount(order);
        return '${context.tr('collectItemsIndividually')} ($collectedCount/${getTotalItems(order)})';
      }
    }
  }

  static void handleButtonPress({
    required BuildContext context,
    required Orders? order,
    required bool from,
    required Function() onCollectAllItems,
    required Function() onShowEarningsPopup,
    required Function() onNavigateToPickupRoute,
    required Function() onNavigateToMap,
  }) {
    if (!from) {
      // When from is false (collection mode)
      if (areAllItemsCollected(order)) {
        // Navigate to pickup route map when all items are collected
        onNavigateToPickupRoute();
      } else if (order?.status?.toLowerCase() == 'assigned') {
        // Collect all items when order status is assigned and not all items are collected
        onCollectAllItems();
      } else {
        // Collect all items if not all are collected
        onCollectAllItems();
      }
    } else {
      // When from is true (delivery mode)
      if (areAllItemsDelivered(order)) {
        // Show completion dialog when all items are delivered
        onShowEarningsPopup();
      } else if (areAllItemsCollected(order)) {
        onNavigateToPickupRoute();
      }
    }
  }

  static void markItemReachedDestination({
    required int orderId,
    required int itemId,
    required Function(int, int) onMarkItemReachedDestination,
  }) {
    onMarkItemReachedDestination(orderId, itemId);
  }
}
