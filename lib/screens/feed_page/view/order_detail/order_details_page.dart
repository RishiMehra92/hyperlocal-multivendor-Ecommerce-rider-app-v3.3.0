// ignore_for_file: unused_element, use_build_context_synchronously

import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:hyper_local/utils/widgets/custom_bottom_sheet.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import '../../../../config/colors.dart';
import '../../../../config/helper.dart';
import '../../../../utils/currency_formatter.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../../utils/widgets/custom_scaffold.dart';
import '../../../../utils/widgets/loading_widget.dart';
import '../../../../utils/widgets/toast_message.dart';
import '../../../system_settings/bloc/system_settings_bloc.dart';
import '../../../system_settings/bloc/system_settings_state.dart';
import '../../model/available_orders.dart';
import '../../bloc/items_collected_bloc/items_collected_bloc.dart';
import '../../bloc/items_collected_bloc/items_collected_event.dart';
import '../../bloc/items_collected_bloc/items_collected_state.dart';
import '../../bloc/order_details_bloc/order_details_bloc.dart';
import '../../bloc/order_details_bloc/order_details_event.dart';
import '../../bloc/order_details_bloc/order_details_state.dart';
import '../../bloc/available_orders_bloc/available_orders_bloc.dart';
import '../../bloc/available_orders_bloc/available_orders_event.dart';
import '../../bloc/my_orders_bloc/my_orders_bloc.dart';
import '../../bloc/my_orders_bloc/my_orders_event.dart';
import '../../../../utils/widgets/custom_button.dart';
import '../../widgets/orderdetails_widgets/index.dart'
    hide PaymentMethodCard, OrderNoteCard;
import '../../../../router/app_routes.dart';
import '../map/widgets/unified_map_widget.dart';
import '../map/store_pickup_route/services/navigation_service.dart';
import 'widgets/order_note_card.dart';
import 'widgets/order_items_section.dart';
import 'widgets/shipping_details_section.dart';
import 'widgets/delivered_trip_details.dart';
import '../../repo/order_actions_repo.dart';
import '../../services/order_service.dart';
import '../../services/dialog_service.dart';
import '../../../../utils/services/phone_service.dart';
import '../../services/item_card_service.dart';
import '../../../../utils/widgets/custom_slide_action.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;
  final bool from;
  final int? sourceTab; // 0 = Available Orders, 1 = My Orders
  final bool? arrivalConfirmed; // Whether arrival has been confirmed

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    this.from = false,
    this.sourceTab,
    this.arrivalConfirmed,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with TickerProviderStateMixin {
  Orders? _fetchedOrder;

  // Local state sets for tracking item status
  final Set<String> _collectedItems = {};
  final Set<String> _deliveredItems = {};
  final Set<String> _otpVerifiedItems = {};

  // UI state variables
  bool _isItemsExpanded = true;
  bool _isStoreDetailsExpanded = false;
  final Set<String> _processingItemIds = {};
  final Set<int> _collectingStoreIds = {};
  bool _isCollectingAll = false;
  bool _isApiFailed = false;
  bool _isCancellingOrder = false;
  bool _isCancellingDelivery = false;
  bool _isNavigating = false;
  int? _navigatingStoreId;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'out_for_delivery':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  String _getDisplayStatus(String status) {
    // Check if all items are delivered with verified OTP

    // If status is delivered and OTP is verified, don't show pending
    if (status.toLowerCase() == 'delivered' ||
        status.toLowerCase() == 'completed') {
      return 'delivered';
    }

    // If status is pending and no items require OTP, show as collected
    if (status.toLowerCase() == 'pending') {
      return 'collected'; // Show as collected instead of pending
    }

    return status;
  }

  bool _areAllItemsDeliveredWithOtp() {
    final order = _fetchedOrder;
    if (order?.items == null || order!.items!.isEmpty) return false;

    for (var item in order.items!) {
      if (item.status?.toLowerCase() != 'delivered' || item.otpVerified != 1) {
        return false;
      }
    }
    return true;
  }

  bool _areAllItemsDelivered() {
    return OrderService.areAllItemsDelivered(_fetchedOrder);
  }

  @override
  void initState() {
    super.initState();

    // Reset confetti flag for new order
    // Fetch order details from API
    context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));

    // Remove the post-frame callback that was causing state conflicts
    // WidgetsBinding.instance.addPostFrameCallback((_) {

    //   _initializeLocalStateFromApi();
    // });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This method is called when the widget's dependencies change
    // It's a good place to refresh data when navigating back to this page

    // Only refresh if we don't have order data
    // Don't refresh if we already have the latest state to preserve bloc updates
    if (_fetchedOrder == null) {
      _refreshOrderDataIfNeeded();
    } else {}
  }

  // Method to refresh order data when needed (e.g., when navigating back)
  void _refreshOrderDataIfNeeded() {
    // Only refresh if we have an order and it's been a while since last refresh
    if (_fetchedOrder != null) {
      context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
    }
  }

  // Method to manually refresh order data
  void _refreshOrderData() {
    // Check if current bloc state has reachedDestination items that we need to preserve
    final currentState = context.read<OrderDetailsBloc>().state;
    Map<String, bool> reachedDestinationItems = {};

    if (currentState.status == ApiStatus.success &&
        currentState.order != null) {
      // Preserve reachedDestination status from current bloc state
      for (var item in currentState.order!.items ?? []) {
        if (item.reachedDestination == true) {
          reachedDestinationItems[item.id.toString()] = true;
        }
      }
    }

    // Clear local state first
    setState(() {
      _deliveredItems.clear();
      _otpVerifiedItems.clear();
      _collectedItems.clear();
    });

    // Fetch fresh data from API
    context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));

    // After API response, restore reachedDestination status
    if (reachedDestinationItems.isNotEmpty) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SystemSettingsBloc, SystemSettingsState>(
      listener: (context, state) {
        if (state.fetchStatus == ApiStatus.success) {
          // Trigger a rebuild to update currency symbols
          setState(() {});
        }
      },
      child: BlocConsumer<ItemsCollectedBloc, ItemsCollectedState>(
        listener: (context, state) {
          if (state.status == ApiStatus.success) {
            String processedItemId = state.itemId;

            if (processedItemId == "ALL_DELIVER") {
              setState(() {
                _isCollectingAll = false;
              });
              context.read<OrderDetailsBloc>().add(
                FetchOrderDetails(widget.orderId),
              );
              _showSuccessBottomSheet();
              return;
            }

            if (processedItemId.startsWith("ALL_STORE_")) {
              final storeIdStr = processedItemId.substring("ALL_STORE_".length);
              final storeId = int.tryParse(storeIdStr);
              setState(() {
                _isCollectingAll = false;
                if (storeId != null) {
                  _collectingStoreIds.remove(storeId);
                }
              });
              context.read<OrderDetailsBloc>().add(
                FetchOrderDetails(widget.orderId),
              );
              ToastManager.show(
                context: context,
                message:
                    state.message.isNotEmpty
                        ? state.message
                        : 'All store items collected successfully',
                type: ToastType.success,
              );
              return;
            }

            setState(() {
              _processingItemIds.remove(processedItemId);

              // Remove from _collectingStoreIds if no more items are in queue for this store
              final item = _fetchedOrder?.items?.firstWhere(
                (i) => i.id.toString() == processedItemId,
                orElse: () => Items(),
              );
              if (item != null && item.storeId != null) {
                final hasMoreItemsInQueue =
                    _fetchedOrder?.items?.any(
                      (i) =>
                          i.storeId == item.storeId &&
                          _processingItemIds.contains(i.id.toString()),
                    ) ??
                    false;
                if (!hasMoreItemsInQueue) {
                  _collectingStoreIds.remove(item.storeId);
                }
              }

              // If this was the last item in "collect all", reset the flag
              if (_isCollectingAll && _processingItemIds.isEmpty) {
                _isCollectingAll = false;
              }
            });

            // Dispatch FetchOrderDetails as backup
            context.read<OrderDetailsBloc>().add(
              FetchOrderDetails(widget.orderId),
            );

            // Show toast or auto-close bottom sheet if all items are collected
            if (!state.isDelivery && _areAllItemsCollected()) {
              ToastManager.show(
                context: context,
                message:
                    context.tr('allItemsCollectedSuccessfully'),
                type: ToastType.success,
              );
            } else {
              String successMessage =
                  state.isDelivery
                      ? context.tr('itemDeliveredSuccessfully')
                      : context.tr('itemCollectedSuccessfully');

              // Only show individual toasts if not collecting all
              if (!_isCollectingAll) {
                ToastManager.show(
                  context: context,
                  message: successMessage,
                  type: ToastType.success,
                );
              }
            }
          } else if (state.status == ApiStatus.failed) {
            setState(() {
              if (state.itemId == "ALL_DELIVER") {
                _isCollectingAll = false;
              } else if (state.itemId.startsWith("ALL_STORE_")) {
                _isCollectingAll = false;
                final storeIdStr = state.itemId.substring("ALL_STORE_".length);
                final storeId = int.tryParse(storeIdStr);
                if (storeId != null) {
                  _collectingStoreIds.remove(storeId);
                }
              } else {
                _processingItemIds.remove(state.itemId);

                // Remove from _collectingStoreIds if no more items are in queue for this store
                final item = _fetchedOrder?.items?.firstWhere(
                  (i) => i.id.toString() == state.itemId,
                  orElse: () => Items(),
                );
                if (item != null && item.storeId != null) {
                  final hasMoreItemsInQueue =
                      _fetchedOrder?.items?.any(
                        (i) =>
                            i.storeId == item.storeId &&
                            _processingItemIds.contains(i.id.toString()),
                      ) ??
                      false;
                  if (!hasMoreItemsInQueue) {
                    _collectingStoreIds.remove(item.storeId);
                  }
                }

                if (_isCollectingAll && _processingItemIds.isEmpty) {
                  _isCollectingAll = false;
                }
              }
            });

            ToastManager.show(
              context: context,
              message: state.message,
              type: ToastType.error,
            );
          }
        },
        builder: (context, itemsCollectedState) {
          return BlocConsumer<OrderDetailsBloc, OrderDetailsState>(
            listener: (context, state) {
              if (state.status == ApiStatus.success && state.order != null) {
                // Check if we need to restore reachedDestination status from previous state
                setState(() {
                  _isApiFailed = false;
                  _fetchedOrder = state.order;
                  _processingItemIds.clear();
                  _isCollectingAll = false;
                  _collectingStoreIds.clear();

                  // Clear local state sets before rebuilding from API response
                  _deliveredItems.clear();
                  _collectedItems.clear();
                  _otpVerifiedItems.clear();

                  // Update local state based on API response
                  if (_fetchedOrder?.items != null) {
                    for (var item in _fetchedOrder!.items!) {
                      // Update local state based on API status
                      if (item.id != null) {
                        String itemId = item.id.toString();

                        // If item is delivered according to API, add to delivered items
                        if (item.status?.toLowerCase() == 'delivered') {
                          _deliveredItems.add(itemId);
                        }

                        // If item is collected according to API, add to collected items
                        if (item.status?.toLowerCase() == 'collected' ||
                            item.status?.toLowerCase() == 'delivered') {
                          _collectedItems.add(itemId);
                        }

                        // If item has OTP verified according to API, add to OTP verified items
                        if (item.otpVerified == 1) {
                          _otpVerifiedItems.add(itemId);
                        }
                      }
                    }
                  }
                });
              } else if (state.status == ApiStatus.failed) {
                setState(() {
                  _isApiFailed = true;
                  _processingItemIds.clear();
                });
              }
            },
            builder: (context, state) {
              // Use fetched order data with restored reachedDestination values
              final order = _fetchedOrder;

              if (order == null) {
                return CustomScaffold(
                  appBar: CustomAppBar(
                    title: context.tr('orderDetails'),
                    showRefreshButton: true,
                    showThemeToggle: false,
                    onRefreshPressed: () {
                      if (_fetchedOrder == null) {
                        _refreshOrderData();
                      } else {
                        ToastManager.show(
                          context: context,
                          message: 'Order data is already up to date',
                          type: ToastType.info,
                        );
                      }
                    },
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child:
                              _isApiFailed
                                  ? ErrorStateWidget(
                                    onRetry: () {
                                      context.read<OrderDetailsBloc>().add(
                                        FetchOrderDetails(widget.orderId),
                                      );
                                    },
                                  )
                                  : const LoadingWidget(),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return CustomScaffold(
                appBar: CustomAppBar(
                  titleWidget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        text: context.tr('orderDetails'),
                        fontSize: sz(18, seprateTabletSize: 14),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text:
                                '${context.tr('orderId')} #${order.id}',
                            fontSize: sz(13, seprateTabletSize: 11),
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 6.w),
                          Icon(
                            order.status?.toLowerCase() == 'cancelled'
                                ? Icons.cancel
                                : (order.status?.toLowerCase() == 'delivered' ||
                                    order.status?.toLowerCase() == 'completed')
                                ? Icons.check_circle
                                : Icons.access_time,
                            color: _getStatusColor(order.status ?? ''),
                            size: sz(14, seprateTabletSize: 12).sp,
                          ),
                          SizedBox(width: 4.w),
                          CustomText(
                            text: _capitalizeStatus(
                              _getDisplayStatus(order.status ?? ''),
                            ),
                            fontSize: sz(13, seprateTabletSize: 11),
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(order.status ?? ''),
                          ),
                        ],
                      ),
                    ],
                  ),
                  additionalActions: [
                    Container(
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
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
                body: Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          final detailsCompleter = Completer<void>();
                          // Fetch order details from API
                          context.read<OrderDetailsBloc>().add(
                            FetchOrderDetails(
                              widget.orderId,
                              completer: detailsCompleter,
                            ),
                          );
                          await detailsCompleter.future;
                        },
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: (isTablet() ? 24 : 8).w,
                            vertical: (isTablet() ? 16 : 18).h,
                          ),
                          child: Column(
                            spacing: 12.h,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order Status Banner
                              // Removed OrderStatusBanner as it is now in the AppBar
                              if (!_isOrderCancelled() &&
                                  order.status?.toLowerCase() != 'delivered' &&
                                  order.status?.toLowerCase() != 'completed')
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
                                              (order.status?.toLowerCase() ==
                                                          'out_for_delivery' ||
                                                      order.status
                                                              ?.toLowerCase() ==
                                                          'collected' ||
                                                      order.status
                                                              ?.toLowerCase() ==
                                                          'delivered' ||
                                                      order.status
                                                              ?.toLowerCase() ==
                                                          'completed')
                                                  ? MapViewMode.customerDelivery
                                                  : MapViewMode.storePickup,
                                          order: order,
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.black.withValues(
                                                    alpha: 0.3,
                                                  ),
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
                                            onTap: _onNavigationPressed,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(20.r),
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
                                                      child: const CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    Icon(
                                                      TablerIcons
                                                          .brand_google_maps,
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

                              if (order.status?.toLowerCase() == 'delivered' ||
                                  order.status?.toLowerCase() == 'completed' ||
                                  order.status?.toLowerCase() == 'cancelled' ||
                                  order.status?.toLowerCase() == 'canceled')
                                DeliveredTripDetails(order: order),

                              // Shipping Details Section
                              if (order.status?.toLowerCase() ==
                                  'out_for_delivery')
                                ShippingDetailsSection(
                                  order: order,
                                  isExpanded: _isStoreDetailsExpanded,
                                  onToggle: () {
                                    setState(() {
                                      _isStoreDetailsExpanded =
                                          !_isStoreDetailsExpanded;
                                    });
                                  },
                                ),
                              // Order Note Card
                              if (order.orderNote != null &&
                                  order.orderNote != "")
                                OrderNoteCard(order: order),

                              if (order.status?.toLowerCase() != 'delivered' &&
                                  order.status?.toLowerCase() != 'completed' &&
                                  order.status?.toLowerCase() != 'cancelled' &&
                                  order.status?.toLowerCase() != 'canceled')
                                OrderItemsSection(
                                  order: order,
                                  isExpanded: _isItemsExpanded,
                                  onToggle: () {
                                    setState(() {
                                      _isItemsExpanded = !_isItemsExpanded;
                                    });
                                  },
                                  storeGroups: _buildStoreGroups(order),
                                  onCollectAll:
                                      (!widget.from &&
                                              order.status?.toLowerCase() ==
                                                  'assigned' &&
                                              _hasUncollectedItems())
                                          ? _collectAllItems
                                          : null,
                                  collectingStoreIds: _collectingStoreIds,
                                  collectedItems: _collectedItems,
                                  onCollectAllForStore: _collectStoreItems,
                                  onNavigateToStore: _navigateToStore,
                                  navigatingStoreId: _navigatingStoreId,
                                  onItemOtpTap: _showItemOtpDialog,
                                ),
                              if (_canShowCancelDeliveryAction() &&
                                  _hasCancellableItems()) ...[
                                CustomButton(
                                  text:
                                      context.tr('cancelDelivery'),
                                  onPressed: _openCancelDeliverySheet,
                                  isLoading: _isCancellingDelivery,
                                  backgroundColor: AppColors.errorColor,
                                  textColor: Colors.white,
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: (isTablet() ? 18 : 24).w,
                                    vertical: (isTablet() ? 10 : 12).h,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: sz(16, seprateTabletSize: 12).sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                              ],
                              if (_canShowCancelOrderAction())
                                CustomButton(
                                  text:
                                      context.tr('cancelOrder'),
                                  onPressed: _showCancelOrderDialog,
                                  isLoading: _isCancellingOrder,
                                  backgroundColor: AppColors.errorColor,
                                  textColor: Colors.white,
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: (isTablet() ? 18 : 24).w,
                                    vertical: (isTablet() ? 10 : 12).h,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: sz(16, seprateTabletSize: 12).sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              SizedBox(
                                height: 60.h,
                              ), // Bottom padding for swipe button
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: _buildBottomSheet(),
              );
            },
          );
        },
      ),
    );
  }

  void _showArrivalConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green),
              SizedBox(width: 8.w),
              CustomText(
                text: context.tr('confirmArrival'),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          content: CustomText(
            text: context.tr('haveYouReachedAddress'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: CustomText(text: context.tr('cancel')),
            ),
            CustomButton(
              text: context.tr('yesImHere'),
              onPressed: () {
                Navigator.pop(dialogContext);

                // Mark ALL items as reached destination using the bloc
                if (_fetchedOrder?.items != null) {
                  for (final item in _fetchedOrder!.items!) {
                    if (item.id != null) {
                      context.read<OrderDetailsBloc>().add(
                        MarkItemReachedDestination(
                          _fetchedOrder!.id!,
                          item.id!,
                        ),
                      );
                    }
                  }
                }

                // Show success message
                ToastManager.show(
                  context: context,
                  message:
                      context.tr('arrivalConfirmedViewDetails'),
                  type: ToastType.success,
                );
              },
              backgroundColor: AppColors.primaryColor,
              textColor: Colors.white,
            ),
          ],
        );
      },
    );
  }

  // Helper method to build the bottom sheet using the reusable widget
  Widget? _buildBottomSheet() {
    if (_fetchedOrder?.items == null) return null;

    final String? status = _fetchedOrder?.status?.toLowerCase();
    if (status == 'cancelled' || status == 'canceled') {
      return null;
    }

    List<Widget> actions = [];

    final bool isOrderWise =
        _fetchedOrder?.deliveryOtpMode?.toLowerCase() == 'order_wise';
    final bool requiresOrderOtp =
        isOrderWise &&
        (_fetchedOrder?.deliveryOtpRequired ?? false) &&
        !(_fetchedOrder?.deliveryOtpVerified ?? false);

    // 1. Show "Collect All Items" button if there are uncollected items (Removed - placed in StoreDetailsSection)
    // 2. Show "Deliver All" / "Enter OTP" button if there are undelivered collected items (Only when all items are collected)
    // We also show it if all items are delivered but the overall order is not yet marked as delivered on the server.
    if (!_hasUncollectedItems() &&
        (_hasUndeliveredCollectedItems() ||
            (status != 'delivered' && _hasAnyCollectedOrDeliveredItems()))) {
      actions.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: SizedBox(
            width: double.infinity,
            height: 48.h,
            child: CustomSlideAction(
              text:
                  requiresOrderOtp
                      ? context.tr('enterOtp')
                      : context.tr('deliverAll'),
              action: _isCollectingAll ? () {} : _handleDeliverAllAction,
              isLoading: _isCollectingAll,
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) return null;

    // ✅ Return multiple buttons UI wrapped in a styled container
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
        child: Column(mainAxisSize: MainAxisSize.min, children: actions),
      ),
    );
  }

  bool _areAllItemsCollected() {
    return OrderService.areAllItemsCollected(_fetchedOrder);
  }

  bool _hasUncollectedItems() {
    final items = _fetchedOrder?.items;
    if (items == null || items.isEmpty) return false;
    return items.any((item) {
      final s = item.status?.toLowerCase();
      return s != 'collected' && s != 'delivered' && s != 'returning_to_store';
    });
  }

  bool _areAllItemsStrictlyCollected() {
    return OrderService.areAllItemsStrictlyCollected(_fetchedOrder);
  }

  bool _canShowCancelOrderAction() {
    final status = _fetchedOrder?.status?.toLowerCase();
    if (status == null) return false;
    if (status == 'delivered' ||
        status == 'completed' ||
        status == 'cancelled' ||
        status == 'canceled') {
      return false;
    }
    final items = _fetchedOrder?.items;
    if (items == null || items.isEmpty) return false;
    final anyTouched = items.any((item) {
      final s = item.status?.toLowerCase();
      if (s == 'collected' || s == 'delivered' || s == 'returning_to_store') {
        return true;
      }
      return _collectedItems.contains(item.id.toString());
    });
    return !anyTouched;
  }

  bool _canShowCancelDeliveryAction() {
    return _fetchedOrder?.status?.toLowerCase() == 'out_for_delivery';
  }

  Future<String?> _submitCancelOrder(String reason) async {
    if (_fetchedOrder?.id == null || _isCancellingOrder) {
      return 'Unable to cancel order right now';
    }

    setState(() {
      _isCancellingOrder = true;
    });

    try {
      final response = await OrderActionsRepo().cancelOrder(
        orderId: _fetchedOrder!.id!,
        note: reason,
      );

      final isSuccess = response['success'] == true;
      final message =
          response['message']?.toString() ?? 'Failed to cancel order';

      if (!mounted) return message;

      if (isSuccess) {
        ToastManager.show(
          context: context,
          message: message,
          type: ToastType.success,
        );
        return null;
      }

      ToastManager.show(
        context: context,
        message: message,
        type: ToastType.success,
      );
      return message;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ToastManager.show(
          context: context,
          message: message,
          type: ToastType.success,
        );
      }
      return message;
    } finally {
      if (mounted) {
        setState(() {
          _isCancellingOrder = false;
        });
      }
    }
  }

  Future<String?> _submitCancelDeliveryForItems(
    List<int> itemIds,
    String reasonCode,
    String? note,
  ) async {
    if (itemIds.isEmpty) {
      return 'Select at least one item to cancel delivery';
    }
    if (_isCancellingDelivery) {
      return 'Cancellation already in progress';
    }

    setState(() {
      _isCancellingDelivery = true;
    });

    try {
      String? successMessage;

      for (final orderItemId in itemIds) {
        final response = await OrderActionsRepo().markDeliveryFailed(
          orderItemId: orderItemId,
          reasonCode: reasonCode,
          note: note,
        );

        final isSuccess = response['success'] == true;
        final message =
            response['message']?.toString() ?? 'Failed to cancel delivery';

        if (!isSuccess) {
          if (mounted) {
            ToastManager.show(
              context: context,
              message: message,
              type: ToastType.error,
            );
          }
          return message;
        }

        successMessage = message;
      }

      if (mounted) {
        ToastManager.show(
          context: context,
          message: successMessage ?? 'Delivery cancelled successfully',
        );
        _refreshOrderData();
      }

      return null;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ToastManager.show(
          context: context,
          message: message,
          type: ToastType.error,
        );
      }
      return message;
    } finally {
      if (mounted) {
        setState(() {
          _isCancellingDelivery = false;
        });
      }
    }
  }

  Future<void> _showCancelOrderDialog() async {
    if (_isCancellingOrder) return;
    final result = await DialogService.showCancelOrderDialog(
      context: context,
      onSubmit: _submitCancelOrder,
    );
    if (!mounted) return;
    if (result == true) {
      context.read<MyOrdersBloc>().add(AllMyOrdersList(forceRefresh: true));
      context.read<AvailableOrdersBloc>().add(
        AllAvailableOrdersList(forceRefresh: true),
      );
      if (context.canPop()) {
        context.pop();
      }
    }
  }

  Future<void> _openCancelDeliverySheet() async {
    if (_isCancellingDelivery) return;
    final order = _fetchedOrder;
    if (order == null) return;
    final List<Items> eligibleItems =
        order.items?.where(_isItemCancellable).toList() ?? const <Items>[];
    if (eligibleItems.isEmpty) {
      ToastManager.show(
        context: context,
        message: 'No items eligible for delivery cancellation',
        type: ToastType.info,
      );
      return;
    }
    await CancelDeliverySheet.show(
      context: context,
      items: eligibleItems,
      onSubmit: _submitCancelDeliveryForItems,
    );
  }

  bool _isItemCancellable(Items item) {
    final status = item.status?.toLowerCase();
    return status != 'delivered' && status != 'returning_to_store';
  }

  bool _hasCancellableItems() {
    final items = _fetchedOrder?.items;
    if (items == null || items.isEmpty) return false;
    return items.any(_isItemCancellable);
  }

  bool _isOrderCancelled() {
    final status = _fetchedOrder?.status?.toLowerCase();
    return status == 'cancelled' || status == 'canceled';
  }

  int _getTotalItems() {
    return OrderService.getTotalItems(_fetchedOrder);
  }

  bool _hasItemsRequiringOtp() {
    return OrderService.hasItemsRequiringOtp(_fetchedOrder);
  }

  bool _areAllOtpItemsVerified() {
    return OrderService.areAllOtpItemsVerified(_fetchedOrder);
  }

  bool _hasCodItems() {
    return OrderService.hasCodItems(_fetchedOrder);
  }

  void _showCodPopup() {
    DialogService.showCodPopup(context, _fetchedOrder);
  }

  void _collectItem(Items item) {
    // Collect the item directly (no OTP required)
    if (item.id != null) {
      // Set the current processing item ID for tracking
      setState(() {
        _processingItemIds.add(item.id.toString());
      });

      // Dispatch the API call - UI updates will be handled in BlocConsumer
      context.read<ItemsCollectedBloc>().add(
        ItemsCollected(item.id.toString()),
      );
    }
  }

  void _deliverItemWithoutOtp(Items item) async {
    if (item.id != null) {
      // Set the current processing item ID for tracking
      setState(() {
        _processingItemIds.add(item.id.toString());
      });

      // Remove the force refresh that was causing bottom sheet to disappear
      // _forceBottomSheetRefresh();

      // Dispatch the API call to mark item as delivered
      context.read<ItemsCollectedBloc>().add(
        ItemsDelivered(item.id.toString()),
      );
    }
  }

  void _deliverItem(Items item) async {
    if (item.id != null) {
      // Show OTP dialog for delivery
      final String? otp = await _showDeliveryOtpDialog();

      if (otp != null && otp.isNotEmpty) {
        // Set the current processing item ID for tracking
        setState(() {
          _processingItemIds.add(item.id.toString());
        });

        // Dispatch the API call - UI updates will be handled in BlocConsumer
        context.read<ItemsCollectedBloc>().add(
          ItemsCollectedWithOtp(orderItemId: item.id.toString(), otp: otp),
        );
      }
    }
  }

  Future<String?> _showDeliveryOtpDialog() async {
    return await DialogService.showDeliveryOtpDialog(context);
  }

  List<StoreGroup> _buildStoreGroups(Orders order) {
    if (order.items == null || order.items!.isEmpty) return [];

    final Map<int?, List<Items>> groupedItems = {};
    for (var item in order.items!) {
      groupedItems.putIfAbsent(item.storeId, () => []).add(item);
    }

    final List<StoreGroup> storeGroups = [];

    groupedItems.forEach((storeId, items) {
      if (storeId == null || storeId == 0) return;
      final routeDetail = order.deliveryRoute?.routeDetails?.firstWhere(
        (detail) => detail.storeId == storeId,
        orElse: () => RouteDetails(storeId: storeId),
      );

      final String storeName =
          routeDetail?.storeName ?? items.first.store?.name ?? 'Unknown Store';
      final String? storeAddress =
          routeDetail?.address ?? routeDetail?.landmark;

      final List<Widget> cards =
          items.map((item) => _buildItemCard(item)).toList();

      storeGroups.add(
        StoreGroup(
          storeId: storeId,
          storeName: storeName,
          storeAddress: storeAddress,
          itemCards: cards,
        ),
      );
    });

    // Sort storeGroups based on the order of storeIds in deliveryRoute.routeDetails
    final routeStoreIds =
        order.deliveryRoute?.routeDetails
            ?.map((d) => d.storeId)
            .where((id) => id != null)
            .toList() ??
        [];

    storeGroups.sort((a, b) {
      final indexA = routeStoreIds.indexOf(a.storeId);
      final indexB = routeStoreIds.indexOf(b.storeId);
      if (indexA == -1 && indexB == -1) return 0;
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;
      return indexA.compareTo(indexB);
    });

    return storeGroups;
  }

  Widget _buildItemCard(Items item) {
    final storeCoords = _resolveStoreCoords(item);
    return ItemCardService.buildItemCard(
      context: context,
      item: item,
      from: widget.from,
      collectedItems: _collectedItems,
      deliveredItems: _deliveredItems,
      otpVerifiedItems: _otpVerifiedItems,
      currentProcessingItemId:
          _processingItemIds.contains(item.id.toString())
              ? item.id.toString()
              : (_isCollectingAll &&
                      (_collectingStoreIds.isEmpty ||
                          _collectingStoreIds.contains(item.storeId))
                  ? 'collecting_all'
                  : null),
      fetchedOrder: _fetchedOrder,
      onCollect: () => _collectItem(item),
      onDelivered: () => _deliverItemWithoutOtp(item),
      onReachedDestination: () => _markItemReachedDestination(item),
      onItemOtpTap: _showItemOtpDialog,
      onNavigateToStore:
          (item.status?.toLowerCase() == 'returning_to_store' &&
                  storeCoords != null)
              ? () => NavigationService.openDirectionsInGoogleMaps(
                storeCoords.$1,
                storeCoords.$2,
              )
              : null,
    );
  }

  (double, double)? _resolveStoreCoords(Items item) {
    final routeDetails = _fetchedOrder?.deliveryRoute?.routeDetails;
    if (routeDetails == null || routeDetails.isEmpty) return null;
    if (item.storeId == null) return null;
    for (final route in routeDetails) {
      if (route.storeId == item.storeId &&
          route.latitude != null &&
          route.longitude != null) {
        return (route.latitude!, route.longitude!);
      }
    }
    return null;
  }

  void _showItemOtpDialog(Items item) async {
    bool requiresOtp =
        (item.requiresOtp == true) || (item.product?.requiresOtp == 1);

    if (!requiresOtp) {
      _deliverItemWithoutOtp(item);
      return;
    }

    // Show simplified OTP dialog
    final String? otp = await DialogService.showDeliveryOtpDialog(context);

    if (otp != null && otp.isNotEmpty) {
      setState(() {
        _processingItemIds.add(item.id.toString());
      });

      context.read<ItemsCollectedBloc>().add(
        ItemsCollectedWithOtp(orderItemId: item.id.toString(), otp: otp),
      );
    }
  }

  void _collectAllItems() async {
    setState(() {
      _isCollectingAll = true;
    });

    OrderService.collectAllItems(
      order: _fetchedOrder,
      collectedItems: _collectedItems,
      onItemCollected: (itemId) {
        context.read<ItemsCollectedBloc>().add(ItemsCollected(itemId));
      },
      onError: (errorMessage) {
        setState(() {
          _isCollectingAll = false;
        });
        ToastManager.show(
          context: context,
          message: errorMessage,
          type: ToastType.error,
        );
      },
    );
  }

  void _collectStoreItems(int storeId) {
    if (_fetchedOrder?.id == null) return;

    setState(() {
      _isCollectingAll = true;
      _collectingStoreIds.add(storeId);
    });

    context.read<ItemsCollectedBloc>().add(
      CollectAllItems(orderId: _fetchedOrder!.id!, storeId: storeId),
    );
  }

  bool _hasUndeliveredCollectedItems() {
    final items = _fetchedOrder?.items;
    if (items == null || items.isEmpty) return false;
    return items.any((item) {
      final s = item.status?.toLowerCase();
      final isCollected =
          s == 'collected' || _collectedItems.contains(item.id.toString());
      final isDelivered =
          s == 'delivered' || _deliveredItems.contains(item.id.toString());
      return isCollected && !isDelivered;
    });
  }

  bool _hasAnyCollectedOrDeliveredItems() {
    final items = _fetchedOrder?.items;
    if (items == null || items.isEmpty) return false;
    return items.any((item) {
      final s = item.status?.toLowerCase();
      final isCollected =
          s == 'collected' || _collectedItems.contains(item.id.toString());
      final isDelivered =
          s == 'delivered' || _deliveredItems.contains(item.id.toString());
      return isCollected || isDelivered;
    });
  }

  bool _hasUnverifiedOtpItems() {
    if (_fetchedOrder?.deliveryOtpMode?.toLowerCase() == 'order_wise') {
      return false;
    }
    final items = _fetchedOrder?.items;
    if (items == null || items.isEmpty) return false;

    return items.any((item) {
      final s = item.status?.toLowerCase();
      final isCollected =
          s == 'collected' || _collectedItems.contains(item.id.toString());
      final isDelivered =
          s == 'delivered' || _deliveredItems.contains(item.id.toString());
      final requiresOtp =
          (item.requiresOtp == true) || (item.product?.requiresOtp == 1);
      final isOtpVerified =
          item.otpVerified == 1 ||
          _otpVerifiedItems.contains(item.id.toString());

      return isCollected && !isDelivered && requiresOtp && !isOtpVerified;
    });
  }

  void _deliverAllItems({String? otp}) async {
    if (_fetchedOrder?.id == null) return;

    final bool isOrderWise =
        _fetchedOrder?.deliveryOtpMode?.toLowerCase() == 'order_wise';
    if (!isOrderWise && _hasUnverifiedOtpItems()) {
      ToastManager.show(
        context: context,
        message: context.tr('someItemsRequireOtp'),
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isCollectingAll = true;
    });

    context.read<ItemsCollectedBloc>().add(
      DeliverAllItems(orderId: _fetchedOrder!.id!, otp: otp),
    );
  }

  void _handleDeliverAllAction() async {
    final bool isOrderWise =
        _fetchedOrder?.deliveryOtpMode?.toLowerCase() == 'order_wise';
    final bool requiresOrderOtp =
        isOrderWise &&
        (_fetchedOrder?.deliveryOtpRequired ?? false) &&
        !(_fetchedOrder?.deliveryOtpVerified ?? false);

    if (!isOrderWise && _hasUnverifiedOtpItems()) {
      ToastManager.show(
        context: context,
        message: context.tr('someItemsRequireOtp'),
        type: ToastType.error,
      );
      return;
    }

    if (requiresOrderOtp) {
      final String? otp = await DialogService.showDeliveryOtpDialog(context);
      if (otp == null || otp.isEmpty) {
        return; // User cancelled or entered invalid OTP
      }

      setState(() {
        _isCollectingAll = true;
      });

      // Call order-items/{orderId}/status API with orderId and OTP
      context.read<ItemsCollectedBloc>().add(
        ItemsCollectedWithOtp(
          orderItemId: _fetchedOrder!.id.toString(),
          otp: otp,
        ),
      );
      return;
    }

    final paymentMethod = _fetchedOrder?.paymentMethod?.toLowerCase();
    final paymentStatus = _fetchedOrder?.paymentStatus?.toLowerCase();
    final isCodPaidOnline = _fetchedOrder?.isCodPaidOnline ?? false;

    if (paymentMethod == 'cod' &&
        paymentStatus != 'completed' &&
        !isCodPaidOnline) {
      final result = await context.push(
        AppRoutes.paymentMethodSelection,
        extra: {
          'orderId': _fetchedOrder!.id,
          'paymentUrl': _fetchedOrder!.codOnlinePaymentUrl,
          'canPayOnline': _fetchedOrder!.canPayOnline ?? false,
          'codAmount': CurrencyFormatter.formatAmount(
            context,
            _fetchedOrder!.finalTotal ?? '0',
          ),
        },
      );
      if (!mounted) return;
      if (result == 'cod' || result == 'online_completed') {
        _deliverAllItems();
      }
    } else {
      _deliverAllItems();
    }
  }

  void _showSuccessBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    CustomBottomSheet.show(
      context: context,
      child: Column(
        children: [
          // Lottie Success Animation Container
          Container(
            color: const Color(0xff2FCD71),
            height: 200,
            width: double.infinity,
            child: Center(
              child: Lottie.asset(
                'assets/lottie/success_lottie.json',
                repeat: false,
                height: 150.h,
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // Order Completed Title
          CustomText(
            text: context.tr('orderCompleted'),
            fontSize: sz(22, seprateTabletSize: 18),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          SizedBox(height: 6.h),

          // Subtitle
          CustomText(
            text: context.tr('allItemsDeliveredSuccessfully'),
            textAlign: TextAlign.center,
            fontSize: sz(13, seprateTabletSize: 11),
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),

          SizedBox(height: 24.h),

          // Earnings Breakdown Card
          if (_fetchedOrder?.earnings != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Title
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primaryColor,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      CustomText(
                        text:
                            context.tr('yourEarningsBreakdown'),
                        fontWeight: FontWeight.bold,
                        fontSize: sz(14, seprateTabletSize: 12),
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Breakdown rows
                  if (_fetchedOrder?.earnings?.breakdown != null) ...[
                    _buildPremiumBreakdownRow(
                      icon: Icons.receipt_long_outlined,
                      label: context.tr('baseFee'),
                      amount: _fetchedOrder?.earnings?.breakdown?.baseFee,
                      isDark: isDark,
                    ),
                    _buildPremiumBreakdownRow(
                      icon: Icons.storefront_outlined,
                      label: context.tr('storePickupFee'),
                      amount:
                          _fetchedOrder?.earnings?.breakdown?.perStorePickupFee,
                      isDark: isDark,
                    ),
                    _buildPremiumBreakdownRow(
                      icon: Icons.directions_run_outlined,
                      label: context.tr('distanceFee'),
                      amount:
                          _fetchedOrder?.earnings?.breakdown?.distanceBasedFee,
                      isDark: isDark,
                    ),
                    _buildPremiumBreakdownRow(
                      icon: Icons.stars_outlined,
                      label: context.tr('orderIncentive'),
                      amount:
                          _fetchedOrder?.earnings?.breakdown?.perOrderIncentive,
                      isDark: isDark,
                    ),
                    if (_fetchedOrder?.riderTipAmount != null &&
                        _fetchedOrder!.riderTipAmount! > 0)
                      _buildPremiumBreakdownRow(
                        icon: Icons.favorite_border,
                        label: context.tr('riderTip'),
                        amount: _fetchedOrder!.riderTipAmount,
                        isDark: isDark,
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                    ),
                  ],

                  // Total Earnings row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: context.tr('totalEarnings'),
                        fontWeight: FontWeight.bold,
                        fontSize: sz(14, seprateTabletSize: 12),
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      CustomText(
                        text: CurrencyFormatter.formatAmount(
                          context,
                          _fetchedOrder?.earnings?.total ?? 0,
                        ),
                        fontSize: sz(20, seprateTabletSize: 16),
                        fontWeight: FontWeight.bold,
                        color: const Color(
                          0xFF2E7D32,
                        ), // High contrast premium green
                      ),
                    ],
                  ),
                ],
              ),
            ),

          SizedBox(height: 28.h),

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primaryColor.withValues(alpha: 0.3),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                },
                child: CustomText(
                  text: context.tr('close'),
                  color: Colors.white,
                  fontSize: sz(15, seprateTabletSize: 12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildPremiumBreakdownRow({
    required IconData icon,
    required String label,
    required double? amount,
    required bool isDark,
  }) {
    if (amount == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: isDark ? Colors.grey[500] : Colors.grey[500],
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: CustomText(
              text: label,
              fontSize: sz(12, seprateTabletSize: 10),
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          CustomText(
            text: CurrencyFormatter.formatAmount(context, amount),
            fontSize: sz(13, seprateTabletSize: 11),
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ],
      ),
    );
  }

  void _markItemReachedDestination(Items item) {
    if (item.id != null) {
      OrderService.markItemReachedDestination(
        orderId: widget.orderId,
        itemId: item.id!,
        onMarkItemReachedDestination: (orderId, itemId) {
          context.read<OrderDetailsBloc>().add(
            MarkItemReachedDestination(orderId, itemId),
          );
        },
      );
    }
  }

  Future<void> _onNavigationPressed() async {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });

    try {
      final order = _fetchedOrder;
      if (order != null) {
        await NavigationService.navigateForOrder(order);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  Future<void> _navigateToStore(int storeId) async {
    if (_navigatingStoreId != null) return;
    setState(() {
      _navigatingStoreId = storeId;
    });

    try {
      final routeDetails = _fetchedOrder?.deliveryRoute?.routeDetails;
      if (routeDetails == null || routeDetails.isEmpty) return;
      for (final route in routeDetails) {
        if (route.storeId == storeId &&
            route.latitude != null &&
            route.longitude != null) {
          await NavigationService.openDirectionsInGoogleMaps(
            route.latitude!,
            route.longitude!,
          );
          return;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _navigatingStoreId = null;
        });
      }
    }
  }

  int _getTargetTabForNavigation() {
    return OrderService.getTargetTabForNavigation(
      widget.sourceTab,
      widget.from,
    );
  }
}

Future<void> _makePhoneCall(String phoneNumber) async {
  await PhoneService.makePhoneCall(phoneNumber);
}
