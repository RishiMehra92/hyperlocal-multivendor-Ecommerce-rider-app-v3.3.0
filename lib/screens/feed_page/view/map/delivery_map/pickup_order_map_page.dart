// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import 'package:hyper_local/screens/feed_page/view/map/widgets/unified_map_widget.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';

import '../../../model/return_orders_list_model.dart';
import '../../../../../utils/widgets/custom_appbar_without_navbar.dart';

class PickupOrderMapPage extends StatefulWidget {
  final Pickups pickup;
  final String locationType; // 'customer' or 'seller'

  const PickupOrderMapPage({
    super.key,
    required this.pickup,
    this.locationType = 'customer',
  });

  @override
  State<PickupOrderMapPage> createState() => _PickupOrderMapPageState();
}

class _PickupOrderMapPageState extends State<PickupOrderMapPage> {
  // Current stage of pickup process
  // 0 = heading to customer, 1 = at customer (confirm pickup), 2 = heading to store
  int _currentStage = 0;

  @override
  void initState() {
    super.initState();
    final status = widget.pickup.pickupStatus?.toLowerCase() ?? 'pending';
    if (status == 'picked_up') {
      _currentStage = 2;
    } else {
      _currentStage = 0;
    }
  }

  String _getStageTitle() {
    if (widget.locationType == 'customer') {
      switch (_currentStage) {
        case 0:
          return 'Going to Customer Location';
        case 1:
          return 'Arrived at Customer Location';
        default:
          return 'Pickup Order';
      }
    } else {
      switch (_currentStage) {
        case 0:
          return 'Going to Seller Location';
        case 1:
          return 'Arrived at Seller Location';
        default:
          return 'Pickup Order';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically set the map view mode based on return order stage
    final MapViewMode mapMode =
        _currentStage < 2
            ? MapViewMode.pickupFromCustomer
            : MapViewMode.returnToStore;

    return CustomScaffold(
      appBar: CustomAppBar(
        title: _getStageTitle(),
        showRefreshButton: false,
        showThemeToggle: false,
      ),
      body: UnifiedMapWidget(
        mode: mapMode,
        pickup: widget.pickup,
        // bottomCard: Positioned(
        //   bottom: 20,
        //   left: 16.w,
        //   right: 16.w,
        //   child: Container(
        //     padding: EdgeInsets.all(16.h),
        //     decoration: BoxDecoration(
        //       color: Theme.of(context).colorScheme.surface,
        //       borderRadius: BorderRadius.circular(12.r),
        //       boxShadow: [
        //         BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10.r, offset: Offset(0, 4.h)),
        //       ],
        //     ),
        //     child: Column(
        //       mainAxisSize: MainAxisSize.min,
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         // Stage indicator
        //         Row(
        //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //           children: [
        //             Expanded(
        //               child: CustomText(
        //                 text: _getStageDescription(),
        //                 fontSize: 13,
        //                 fontWeight: FontWeight.w500,
        //                 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        //               ),
        //             ),
        //           ],
        //         ),
        //         SizedBox(height: 12.h),
        //         // Action buttons
        //         if (_currentStage == 0 || _currentStage == 1)
        //           SizedBox(
        //             width: double.infinity,
        //             child: CustomButton(
        //               text:
        //                   _currentStage == 0
        //                       ? (widget.locationType == 'customer' ? 'Arrived at Customer' : 'Arrived at Seller')
        //                       : (widget.locationType == 'customer' ? 'Pick Up Order' : 'Confirm Return'),
        //               onPressed: _showArrivalConfirmationDialog,
        //               icon: Icon(
        //                 _currentStage == 0
        //                     ? Icons.location_on
        //                     : (widget.locationType == 'customer' ? Icons.shopping_bag : Icons.check_circle),
        //                 color: Colors.white,
        //               ),
        //               backgroundColor: AppColors.primaryColor,
        //               textColor: Colors.white,
        //               borderRadius: 8.r,
        //               padding: EdgeInsets.symmetric(vertical: 12.h),
        //               textStyle: const TextStyle(fontWeight: FontWeight.w600),
        //             ),
        //           ),
        //         if (_currentStage == 2)
        //           SizedBox(
        //             width: double.infinity,
        //             child: CustomButton(
        //               text: 'Arrived at Store',
        //               onPressed: () {
        //                 showDialog(
        //                   context: context,
        //                   builder:
        //                       (ctx) => AlertDialog(
        //                         title: const Text('Return Order to Store'),
        //                         content: const Text('Have you returned the order to the store?'),
        //                         actions: [
        //                           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        //                           TextButton(
        //                             onPressed: () {
        //                               Navigator.pop(ctx);
        //                               context.pop();
        //                               ToastManager.show(
        //                                 context: context,
        //                                 message: context.tr('orderReturnedToStoreUpdateStatus'),
        //                                 type: ToastType.success,
        //                               );
        //                             },
        //                             child: const Text('Confirm'),
        //                           ),
        //                         ],
        //                       ),
        //                 );
        //               },
        //               icon: const Icon(Icons.check_circle, color: Colors.white),
        //               backgroundColor: Colors.green,
        //               textColor: Colors.white,
        //               borderRadius: 8.r,
        //               padding: EdgeInsets.symmetric(vertical: 12.h),
        //               textStyle: const TextStyle(fontWeight: FontWeight.w600),
        //             ),
        //           ),
        //       ],
        //     ),
        //   ),
        // ),
      ),
    );
  }
}
