import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/pickup_order_details_bloc/pickup_order_details_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/pickup_orders_list_bloc/pickup_order_list_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/update_return_order_status_bloc/update_return_order_status_bloc.dart';
import 'package:hyper_local/screens/feed_page/model/return_orders_list_model.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/currency_formatter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:hyper_local/utils/widgets/custom_pin_field.dart';
import '../../../../utils/extensions.dart';
import '../../../../utils/widgets/custom_bottom_sheet.dart';
import '../../../../utils/widgets/custom_button.dart';
import '../../../../utils/widgets/custom_dropdown.dart';
import '../../../../utils/widgets/custom_textfield.dart';

import '../../../../config/colors.dart';
import '../../../../router/app_routes.dart';
import '../../../../utils/widgets/custom_scaffold.dart';
import '../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../../utils/widgets/loading_widget.dart';
import '../../../../utils/widgets/toast_message.dart';
import '../../../../utils/services/phone_service.dart';
import '../../bloc/return_order/pickup_order_details_bloc/pickup_order_details_state.dart';
import '../../bloc/return_order/update_return_order_status_bloc/update_return_order_status_state.dart';
import '../../../../utils/widgets/custom_slide_action.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../map/widgets/unified_map_widget.dart';
import '../../../../utils/widgets/custom_card.dart';
import 'package:hyper_local/screens/feed_page/view/map/store_pickup_route/services/navigation_service.dart';
import 'widgets/delivered_pickup_trip_details.dart';

class PickupOrderDetailsPage extends StatefulWidget {
  final String returnId;

  const PickupOrderDetailsPage({super.key, required this.returnId});

  @override
  State<PickupOrderDetailsPage> createState() => _PickupOrderDetailsPageState();
}

class _PickupOrderDetailsPageState extends State<PickupOrderDetailsPage> {
  bool _isNavigating = false;

  Future<void> _onNavigationPressed(Pickups pickup) async {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });

    try {
      await NavigationService.navigateForPickup(pickup);
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<PickupOrderDetailsBloc>().add(
      FetchPickupOrderDetails(widget.returnId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PickupOrderDetailsBloc, PickupOrderDetailsState>(
      builder: (context, blocState) {
        final pickup = blocState.pickups;
        final currentStatus = pickup?.pickupStatus?.toLowerCase() ?? 'pending';

        return CustomScaffold(
          appBar: CustomAppBar(
            titleWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: context.tr('pickupDetails'),
                  fontSize: sz(18, seprateTabletSize: 14),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                if (pickup != null &&
                    blocState.status != ApiStatus.loading) ...[
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        text:
                            '${context.tr('orderId')} #${pickup.orderId}',
                        fontSize: sz(13, seprateTabletSize: 11),
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        (currentStatus == 'delivered_to_seller')
                            ? Icons.check_circle
                            : Icons.access_time,
                        color:
                            (currentStatus == 'delivered_to_seller')
                                ? Colors.green
                                : Colors.orange,
                        size: sz(14, seprateTabletSize: 12).sp,
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        text:
                            currentStatus == 'delivered_to_seller'
                                ? context.tr('returned')
                                : _capitalizeStatus(currentStatus),
                        fontSize: sz(13, seprateTabletSize: 11),
                        fontWeight: FontWeight.w600,
                        color:
                            (currentStatus == 'delivered_to_seller')
                                ? Colors.green
                                : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ],
            ),
            additionalActions: [
              Container(
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => context.push(AppRoutes.support),
                  icon: Icon(
                    TablerIcons.headset,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 22.sp,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavBar(pickup),
          body: BlocConsumer<PickupOrderDetailsBloc, PickupOrderDetailsState>(
            listener: (context, state) {
              if (state.status == ApiStatus.failed) {
                ToastManager.show(
                  context: context,
                  message: state.message,
                  type: ToastType.error,
                );
              }
            },
            builder: (context, state) {
              if (state.status == ApiStatus.loading) {
                return const Center(child: LoadingWidget());
              }

              if (state.pickups == null) {
                return Center(
                  child: CustomText(
                    text: context.tr('noPickupDataFound'),
                  ),
                );
              }

              if (state.status == ApiStatus.success) {
                final pickup = state.pickups!;
                final currentStatus = pickup.pickupStatus ?? 'pending';
                final isDelivered = currentStatus == 'delivered_to_seller';
                final isPickedUp =
                    currentStatus == 'picked_up' ||
                    currentStatus == 'delivered_to_seller';

                return SingleChildScrollView(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    children: [
                      if (isDelivered)
                        DeliveredPickupTripDetails(pickup: pickup)
                      else ...[
                        // Embedded Map Box
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Stack(
                              alignment: AlignmentGeometry.bottomCenter,
                              children: [
                                UnifiedMapWidget(
                                  mode:
                                      (currentStatus == 'picked_up')
                                          ? MapViewMode.returnToStore
                                          : MapViewMode.pickupFromCustomer,
                                  pickup: pickup,
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withValues(alpha: 0.3),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.topRight,
                                        end: Alignment.bottomLeft,
                                      ),
                                    ),
                                  ),
                                ),

                                Positioned(
                                  bottom: 16.h,
                                  child: GestureDetector(
                                    onTap: () => _onNavigationPressed(pickup),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14.w,
                                        vertical: 8.h,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isNavigating) ...[
                                            SizedBox(
                                              width: 14.w,
                                              height: 14.h,
                                              child:
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                            ),
                                          ] else ...[
                                            Icon(
                                              TablerIcons.brand_google_maps,
                                              color: Colors.white,
                                              size: 16.sp,
                                            ),
                                          ],
                                          SizedBox(width: 6.w),
                                          CustomText(
                                            text:
                                                '${context.tr('navigate')} to Google Map',
                                            fontSize: sz(
                                              12,
                                              seprateTabletSize: 10,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        _buildReturnItemsCard(pickup),
                        SizedBox(height: 16.h),

                        if (isPickedUp) ...[
                          _buildStoreDetailsCard(pickup),
                          SizedBox(height: 16.h),
                        ],

                        if (!isPickedUp)
                          _buildCustomerDetailsCard(pickup, !isDelivered),
                      ],
                    ],
                  ),
                );
              }

              return Center(
                child: CustomText(
                  text: context.tr('noDetailsFound'),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget? _buildBottomNavBar(Pickups? pickup) {
    if (pickup == null) return null;
    final currentStatus = pickup.pickupStatus?.toLowerCase() ?? 'pending';
    final isDelivered = currentStatus == 'delivered_to_seller';

    if (isDelivered) return null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          child: BlocConsumer<
            UpdateReturnOrderStatusBloc,
            UpdateReturnOrderStatusState
          >(
            listener: (context, statusState) {
              if (statusState.returnId == widget.returnId) {
                if (statusState.status == ApiStatus.success) {
                  ToastManager.show(
                    context: context,
                    message: statusState.message,
                    type: ToastType.success,
                  );
                  context.read<PickupOrderListBloc>().add(
                    FetchPickupOrders(forceRefresh: true),
                  );
                  context.read<PickupOrderDetailsBloc>().add(
                    FetchPickupOrderDetails(widget.returnId),
                  );
                } else if (statusState.status == ApiStatus.failed) {
                  ToastManager.show(
                    context: context,
                    message: statusState.message,
                    type: ToastType.error,
                  );
                }
              }
            },
            builder: (context, statusState) {
              final isUpdating =
                  statusState.status == ApiStatus.loading &&
                  statusState.returnId == widget.returnId;

              // Choose the action and label based on status
              final String slideText;
              final String nextStatus;

              if (currentStatus == 'picked_up') {
                slideText = context.tr('deliveredToSeller');
                nextStatus = 'delivered_to_seller';
              } else {
                slideText = context.tr('pickup');
                nextStatus = 'picked_up';
              }

              return SizedBox(
                width: double.infinity,
                height: 48.h,
                child: CustomSlideAction(
                  text: slideText,
                  action:
                      isUpdating
                          ? () {}
                          : () {
                            if (nextStatus == 'picked_up') {
                              CustomBottomSheet.show(
                                context: context,
                                child: _OtpAndImageBottomSheet(
                                  pickup: pickup,
                                  onSubmit: ({
                                    otp,
                                    images,
                                    pickupCondition,
                                    pickupRemarks,
                                  }) {
                                    context
                                        .read<UpdateReturnOrderStatusBloc>()
                                        .add(
                                          UpdateReturnOrderStatus(
                                            returnId: widget.returnId,
                                            status: nextStatus,
                                            otp: otp,
                                            images: images,
                                            pickupCondition: pickupCondition,
                                            pickupRemarks: pickupRemarks,
                                          ),
                                        );
                                  },
                                ),
                              );
                            } else {
                              context.read<UpdateReturnOrderStatusBloc>().add(
                                UpdateReturnOrderStatus(
                                  returnId: widget.returnId,
                                  status: nextStatus,
                                ),
                              );
                            }
                          },
                  isLoading: isUpdating,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReturnItemsCard(Pickups pickup) {
    final item = pickup.orderItem;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Icon(
                  TablerIcons.box,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  size: sz(22, seprateTabletSize: 18).sp,
                ),
                SizedBox(width: 8.w),
                CustomText(
                  text: context.tr('orderItems'),
                  fontSize: sz(16, seprateTabletSize: 13),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6B6B),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),

          // Store Name / Header for the item
          if (pickup.store != null)
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        TablerIcons.building_store,
                        color: AppColors.primaryColor,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      CustomText(
                        text: pickup.store!.name ?? 'Store',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                  if (pickup.store!.address != null &&
                      pickup.store!.address!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.grey,
                          size: 12.sp,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: CustomText(
                            text: pickup.store!.address!,
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          if (item != null)
            Padding(
              padding: EdgeInsets.all(16.h),
              child: Row(
                children: [
                  CustomImageContainer(
                    width: 50.w,
                    height: 50.h,
                    imagePath: item.product?.image ?? '',
                    backgroundColor:
                        isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8.r),
                    errorWidget: Center(
                      child: Icon(Icons.shopping_bag, size: sz(20).sp),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text:
                              item.product?.name ??
                              context.tr('unknownProduct'),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 4.h),
                        CustomText(
                          text:
                              '${context.tr('quantity')} ${item.quantity ?? 1}',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  CustomText(
                    text: CurrencyFormatter.formatAmount(
                      context,
                      pickup.refundAmount ?? '0',
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       CustomText(
          //         text: '${context.tr('total')} (${context.tr('oneItem')})',
          //         fontSize: 14,
          //         color: Colors.grey[600],
          //         fontWeight: FontWeight.w500,
          //       ),
          //       CustomText(
          //         text: CurrencyFormatter.formatAmount(context, pickup.refundAmount ?? '0'),
          //         fontSize: 14,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  // Widget _buildEarningsCard(Pickups pickup) {
  //   final breakdown = pickup.earnings?.breakdown;
  //   final isDark = Theme.of(context).brightness == Brightness.dark;
  //
  //   return CustomCard(
  //     padding: EdgeInsets.zero,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
  //           child: Row(
  //             children: [
  //               Icon(
  //                 TablerIcons.receipt,
  //                 color: isDark ? Colors.grey[400] : Colors.grey[700],
  //                 size: sz(22, seprateTabletSize: 18).sp,
  //               ),
  //               SizedBox(width: 8.w),
  //               CustomText(
  //                 text: context.tr('earnings'),
  //                 fontSize: sz(16, seprateTabletSize: 13),
  //                 fontWeight: FontWeight.w500,
  //                 color: const Color(0xFF6B6B6B),
  //               ),
  //             ],
  //           ),
  //         ),
  //         Divider(height: 1, thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
  //         Padding(
  //           padding: EdgeInsets.all(16.h),
  //           child: Column(
  //             children: [
  //               _buildRow(
  //                 '${context.tr('baseFee')} :',
  //                 CurrencyFormatter.formatAmount(context, breakdown?.baseFee ?? 0),
  //               ),
  //               _buildRow(
  //                 '${context.tr('perStorePickupFee')} :',
  //                 CurrencyFormatter.formatAmount(context, breakdown?.perStorePickupFee ?? 0),
  //               ),
  //               _buildRow(
  //                 '${context.tr('distanceFee')} :',
  //                 CurrencyFormatter.formatAmount(context, breakdown?.distanceBasedFee ?? 0),
  //               ),
  //               _buildRow(
  //                 '${context.tr('incentive')} :',
  //                 CurrencyFormatter.formatAmount(context, breakdown?.perOrderIncentive ?? 0),
  //               ),
  //               const Divider(height: 24, color: Color(0xFFEEEEEE)),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   CustomText(
  //                     text: context.tr('totalEarnings'),
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                   CustomText(
  //                     text: CurrencyFormatter.formatAmount(context, pickup.earnings?.total ?? 0),
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStoreDetailsCard(Pickups pickup) {
    final store = pickup.store;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (store == null) return const SizedBox.shrink();

    // Construct full address
    List<String> addressParts = [];
    if (store.address != null && store.address!.trim().isNotEmpty) {
      addressParts.add(store.address!.trim());
    }
    if (store.city != null && store.city!.trim().isNotEmpty) {
      addressParts.add(store.city!.trim());
    }
    if (store.state != null && store.state!.trim().isNotEmpty) {
      addressParts.add(store.state!.trim());
    }
    if (store.zipcode != null && store.zipcode!.trim().isNotEmpty) {
      addressParts.add(store.zipcode!.trim());
    }
    String fullAddress =
        addressParts.isNotEmpty ? addressParts.join(', ') : 'N/A';

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Icon(
                  TablerIcons.building_store,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  size: sz(22, seprateTabletSize: 18).sp,
                ),
                SizedBox(width: 8.w),
                CustomText(
                  text: context.tr('storeDetails'),
                  fontSize: sz(16, seprateTabletSize: 13),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6B6B),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          Padding(
            padding: EdgeInsets.all(16.h),
            child: Column(
              children: [
                _buildRow(
                  '${context.tr('store')} :',
                  store.name ?? 'N/A',
                ),
                _buildRow(
                  '${context.tr('storeAddress')} :',
                  fullAddress,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsCard(Pickups pickup, bool isDelivered) {
    final order = pickup.order;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Icon(
                  TablerIcons.map_pin,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  size: sz(22, seprateTabletSize: 18).sp,
                ),
                SizedBox(width: 8.w),
                CustomText(
                  text: context.tr('customerDetails'),
                  fontSize: sz(16, seprateTabletSize: 13),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6B6B),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          Padding(
            padding: EdgeInsets.all(16.h),
            child: Column(
              children: [
                _buildRow(
                  '${context.tr('fullName')} :',
                  order?.shippingName ?? 'N/A',
                ),
                if (isDelivered && order?.shippingPhone != null)
                  _buildRow(
                    '${context.tr('phone')} :',
                    order!.shippingPhone!,
                    trailing: GestureDetector(
                      onTap: () async {
                        try {
                          await PhoneService.makePhoneCall(
                            order.shippingPhone!,
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ToastManager.show(
                            context: context,
                            message: 'Could not launch phone dialer: $e',
                            type: ToastType.error,
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.phone_in_talk_outlined,
                          color: Theme.of(context).primaryColor,
                          size: sz(18, seprateTabletSize: 14).sp,
                        ),
                      ),
                    ),
                  ),
                _buildRow(
                  '${context.tr('address')} :',
                  order?.shippingAddress1 ?? 'N/A',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomText(text: label, fontSize: 14, color: Colors.grey[600]),
          Expanded(
            child: CustomText(
              text: value,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              textAlign: TextAlign.right,
            ),
          ),
          if (trailing != null) ...[SizedBox(width: 8.w), trailing],
        ],
      ),
    );
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return '';
    return status
        .split('_')
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _OtpAndImageBottomSheet extends StatefulWidget {
  final Pickups pickup;
  final void Function({
    String? otp,
    List<File>? images,
    String? pickupCondition,
    String? pickupRemarks,
  })
  onSubmit;

  const _OtpAndImageBottomSheet({required this.pickup, required this.onSubmit});

  @override
  State<_OtpAndImageBottomSheet> createState() =>
      _OtpAndImageBottomSheetState();
}

class _OtpAndImageBottomSheetState extends State<_OtpAndImageBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final List<File> _selectedFiles = [];
  String? _errorMessage;
  String? _selectedCondition;

  @override
  void dispose() {
    _otpController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedFiles.length >= 5) {
      ToastManager.show(
        context: context,
        message: 'You can upload a maximum of 5 images.',
        type: ToastType.error,
      );
      return;
    }
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (photo != null) {
        setState(() {
          _selectedFiles.add(File(photo.path));
        });
      } else {
        if (mounted) {
          ToastManager.show(
            context: context,
            message: context.tr('noImageSelected'),
            type: ToastType.info,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastManager.show(
          context: context,
          message: "${context.tr('errorPickingImage')}$e",
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final theme = Theme.of(context);
    final requiresOtp = widget.pickup.orderItem?.returnRequiresOtp ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomText(
            text: context.tr('verifyPickup'),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 24.h),
          if (requiresOtp) ...[
            CustomText(
              text: context.tr('otpVerification'),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: PinFieldAuto(
                controller: _otpController,
                gapSpace: 8.w,
                fontSize: 18,
                onCodeChanged: (code) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 8.h),
              CustomText(
                text: _errorMessage!,
                color: Colors.red,
                fontSize: 12,
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 24.h),
          ],
          CustomText(
            text:
                '${context.tr('proofImageUpload')} (${_selectedFiles.length}/5)',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          SizedBox(height: 10.h),
          if (_selectedFiles.isEmpty)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140.h,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  color:
                      isDark
                          ? AppColors.cardDarkColor
                          : AppColors.primaryColor.withValues(alpha: 0.02),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: AppColors.primaryColor,
                      size: 40.sp,
                    ),
                    SizedBox(height: 10.h),
                    CustomText(
                      text: context.tr('tapToUploadImageProof'),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: context.tr('supportsImageFormats'),
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 100.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount:
                    _selectedFiles.length + (_selectedFiles.length < 5 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _selectedFiles.length) {
                    return GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 90.w,
                        height: 90.h,
                        margin: EdgeInsets.only(
                          right: 8.w,
                          top: 5.h,
                          bottom: 5.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          color:
                              isDark
                                  ? AppColors.cardDarkColor
                                  : AppColors.primaryColor.withValues(
                                    alpha: 0.02,
                                  ),
                        ),
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.primaryColor,
                          size: 28.sp,
                        ),
                      ),
                    );
                  }

                  final file = _selectedFiles[index];
                  return Stack(
                    children: [
                      Container(
                        width: 90.w,
                        height: 90.h,
                        margin: EdgeInsets.only(
                          right: 8.w,
                          top: 5.h,
                          bottom: 5.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11.r),
                          child: Image.file(file, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 3.w,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFiles.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(3.w),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          SizedBox(height: 32.h),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomDropdownFormField<String>(
                  labelText: 'Pickup Condition',
                  hintText: 'Select condition',
                  value: _selectedCondition,
                  items: const [
                    DropdownMenuItem(value: 'good', child: Text('Good')),
                    DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                    DropdownMenuItem(
                      value: 'opened_package',
                      child: Text('Opened Package'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedCondition = val;
                    });
                  },
                ),
                SizedBox(height: 16.h),
                CustomTextFormField(
                  controller: _remarksController,
                  labelText:
                      _selectedCondition == 'other' ? 'Remarks *' : 'Remarks',
                  hintText: 'Enter remarks here...',
                  minLines: 2,
                  maxLines: 2,
                  validator: (value) {
                    if (_selectedCondition == 'other') {
                      if (value == null || value.trim().isEmpty) {
                        return 'Remarks are required when condition is Other';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  textStyle: const TextStyle(color: Colors.red),

                  text: context.tr('close'),
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomButton(
                  text: context.tr('submit'),
                  backgroundColor: AppColors.primaryColor,
                  textColor: Colors.white,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (requiresOtp) {
                        final enteredOtp = _otpController.text;
                        if (enteredOtp.length != 6) {
                          setState(() {
                            _errorMessage =
                                context.tr('pleaseEnterValidOtp');
                          });
                          return;
                        }
                      }
                      if (_selectedFiles.isEmpty) {
                        ToastManager.show(
                          context: context,
                          message:
                              context.tr('pleaseUploadProofImage'),
                          type: ToastType.error,
                        );
                        return;
                      }
                      widget.onSubmit(
                        otp: requiresOtp ? _otpController.text : null,
                        images: _selectedFiles,
                        pickupCondition: _selectedCondition,
                        pickupRemarks:
                            _remarksController.text.trim().isEmpty
                                ? null
                                : _remarksController.text.trim(),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
