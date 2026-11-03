import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import '../../../../../../config/colors.dart';
import '../../../../../../utils/widgets/custom_button.dart';
import '../../../../../../utils/widgets/custom_text.dart';
import '../../../../model/available_orders.dart';
import 'store_item_widget.dart';
import 'delivery_address_widget.dart';

class BottomCardWidget extends StatefulWidget {
  final Orders order;
  final bool hasReachedDestination;
  final List<RouteDetails> filteredStores;
  final bool shouldShowNumbers;
  final double? distanceToStores; // Add distance parameter
  final VoidCallback? onViewDetailsPressed; // Add callback parameter

  const BottomCardWidget({
    super.key,
    required this.order,
    required this.hasReachedDestination,
    required this.filteredStores,
    required this.shouldShowNumbers,
    required this.distanceToStores, // Add distance parameter
    this.onViewDetailsPressed, // Add callback parameter
  });

  @override
  State<BottomCardWidget> createState() => _BottomCardWidgetState();
}

class _BottomCardWidgetState extends State<BottomCardWidget> {
  bool _isExpanded = true; // Default to expanded

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: CustomCard(
        height:
            _isExpanded
                ? null
                : (isTablet(context: context) ? 110 : 80)
                    .h, // null = auto height based on content

        child: SingleChildScrollView(
          child: Column(
            children: [
              // Draggable handle bar
              GestureDetector(
                onTap: _toggleExpansion,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.h,
                    vertical: 10.h,
                  ),
                  child: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 26.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              // Content with conditional display
              if (_isExpanded)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0.h),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Take minimum height needed
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            widget.hasReachedDestination
                                ? Icons.delivery_dining
                                : Icons.store,
                            color: AppColors.primaryColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: CustomText(
                              text:
                                  widget.hasReachedDestination
                                      ? context.tr('deliveryRoute')
                                      : '${context.tr('storePickup')} ',
                              fontSize: sz(18, seprateTabletSize: 16),
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          // Distance
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: CustomText(
                              text:
                                  widget.distanceToStores != null
                                      ? '${widget.distanceToStores!.toStringAsFixed(1)} ${context.tr('km')}'
                                      : '? ${context.tr('km')}', // Use actual calculated distance
                              fontSize: sz(12, seprateTabletSize: 10),
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // Stores List (only show when hasReachedDestination is false)
                      if (!widget.hasReachedDestination)
                        ...widget.filteredStores.asMap().entries.map((entry) {
                          final index = entry.key;
                          final store = entry.value;
                          return StoreItemWidget(
                            store: store,
                            index: index,
                            shouldShowNumbers: widget.shouldShowNumbers,
                          );
                        }),

                      // Delivery Address (only show when hasReachedDestination is true)
                      if (widget.hasReachedDestination)
                        DeliveryAddressWidget(
                          shippingAddress1: widget.order.shippingAddress1,
                          shippingAddress2: widget.order.shippingAddress2,
                        ),

                      SizedBox(height: 20.h),

                      // Action Button
                      CustomButton(
                        text: context.tr('viewDetails'),
                        width: double.infinity,
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.white,
                        onPressed: widget.onViewDetailsPressed,
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),

              // Minimized state content
              if (!_isExpanded)
                GestureDetector(
                  onTap: _toggleExpansion,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Icon(
                          widget.hasReachedDestination
                              ? Icons.delivery_dining
                              : Icons.store,
                          color: AppColors.primaryColor,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: CustomText(
                            text:
                                widget.hasReachedDestination
                                    ? context.tr('deliveryRoute')
                                    : '${widget.filteredStores.length} stores to pickup',
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Icon(
                          Icons.touch_app,
                          color: Colors.grey[600],
                          size: 16.sp,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
