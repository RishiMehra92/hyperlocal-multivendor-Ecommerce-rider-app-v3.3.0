// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/colors.dart';
import '../../../../config/global.dart';
import '../../../../config/helper.dart';
import '../../../../router/app_routes.dart';

import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/custom_slide_action.dart';
import '../../../../utils/widgets/toast_message.dart';
import '../model/available_orders.dart';
import '../repo/accept_order.dart';
import '../repo/order_details.dart';
import '../bloc/available_orders_bloc/available_orders_bloc.dart';
import '../bloc/available_orders_bloc/available_orders_event.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class OrderReadyBanner extends StatefulWidget {
  final int orderId;
  final VoidCallback onDismiss;

  const OrderReadyBanner({
    super.key,
    required this.orderId,
    required this.onDismiss,
  });

  @override
  State<OrderReadyBanner> createState() => _OrderReadyBannerState();
}

class _OrderReadyBannerState extends State<OrderReadyBanner>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _countdownTimer;
  Timer? _soundTimer;
  int _secondsRemaining = 30;
  bool _isDismissing = false;
  bool _isAccepting = false;

  Orders? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Initialize slide and fade animations for premium entry and exit
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start entry animation
    _animationController.forward();

    // Vibrate device and play sound to capture user attention in the foreground
    _triggerAlerts();

    _startTimer();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final response = await OrderDetailsRepo().getOrderDetails(widget.orderId);
      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          setState(() {
            _order = Orders.fromJson(response['data']['order']);
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                response['message'] ?? 'Failed to load order details';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _triggerAlerts() async {
    try {
      FlutterRingtonePlayer().play(
        fromAsset: 'assets/sounds/new_order_foreground_sound.mp3',
        volume: 1.0,
      );

      _soundTimer?.cancel();
      _soundTimer = Timer.periodic(const Duration(milliseconds: 2450), (timer) {
        try {
          FlutterRingtonePlayer().play(
            fromAsset: 'assets/sounds/new_order_foreground_sound.mp3',
            volume: 1.0,
          );
        } catch (e) {
          debugPrint('Error playing sound in loop: $e');
        }
      });

      for (int i = 0; i < 4; i++) {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 600));
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _soundTimer?.cancel();
    _animationController.dispose();
    try {
      FlutterRingtonePlayer().stop();
    } catch (e) {}
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _countdownTimer?.cancel();
          _dismissWithAnimation();
        }
      }
    });
  }

  void _dismissWithAnimation() {
    if (_isDismissing) return;
    _countdownTimer?.cancel(); // Stop timer immediately when dismissing
    _soundTimer?.cancel();
    try {
      FlutterRingtonePlayer().stop();
    } catch (e) {}
    setState(() {
      _isDismissing = true;
    });

    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  Future<void> _acceptOrder() async {
    if (_isAccepting) return;

    _countdownTimer
        ?.cancel(); // Stop timer so it doesn't dismiss while API is calling
    _soundTimer?.cancel();
    try {
      FlutterRingtonePlayer().stop();
    } catch (e) {}

    setState(() {
      _isAccepting = true;
    });

    try {
      final response = await AcceptOrderRepo().updateAcceptOrder(
        orderId: widget.orderId,
      );
      if (response['success'] == true) {
        if (mounted) {
          HapticFeedback.vibrate();

          final mainContext = navigatorKey.currentContext;
          if (mainContext != null) {
            // 1. Show success toast
            ToastManager.show(
              context: mainContext,
              message: response['message'] ?? 'Order accepted successfully',
              type: ToastType.success,
            );

            // 2. Refresh available orders list BLoC
            final shellContext = shellNavigatorKey.currentContext;
            if (shellContext != null) {
              shellContext.read<AvailableOrdersBloc>().add(
                AllAvailableOrdersList(forceRefresh: true),
              );
            }
          }

          // 3. Determine if we are already on an order-related screen
          final router = MyAppRoute.router;
          final lastMatch = router.routerDelegate.currentConfiguration.last;
          final currentPath = lastMatch.matchedLocation;
          final isOnOrderScreen =
              currentPath.contains('/map-delivery') ||
              currentPath.contains('/order-details') ||
              currentPath.contains('/pickup-order-details');

          // 4. Dismiss the banner
          _dismissWithAnimation();

          final currentOrder = _order;

          // 5. Navigate to Map Screen of the new order if not already on an order screen
          if (!isOnOrderScreen && currentOrder != null && mainContext != null) {
            bool hasValidCoordinates = false;
            String? destinationLat;
            String? destinationLng;

            if (currentOrder.deliveryRoute?.routeDetails != null &&
                currentOrder.deliveryRoute!.routeDetails!.isNotEmpty) {
              final storeLocation =
                  currentOrder.deliveryRoute!.routeDetails!.first;
              hasValidCoordinates =
                  storeLocation.latitude != null &&
                  storeLocation.longitude != null;
              if (hasValidCoordinates) {
                destinationLat = storeLocation.latitude.toString();
                destinationLng = storeLocation.longitude.toString();
              }
            }

            if (!hasValidCoordinates) {
              hasValidCoordinates =
                  currentOrder.shippingLatitude != null &&
                  currentOrder.shippingLongitude != null;
              if (hasValidCoordinates) {
                destinationLat = currentOrder.shippingLatitude.toString();
                destinationLng = currentOrder.shippingLongitude.toString();
              }
            }

            if (hasValidCoordinates &&
                destinationLat != null &&
                destinationLng != null) {
              mainContext.push(
                AppRoutes.mapDelivery,
                extra: {
                  'order': currentOrder,
                  'currentLat': destinationLat,
                  'currentLng': destinationLng,
                  'autoOpenBottomSheet': false,
                  'sourceTab': 0,
                },
              );
            }
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isAccepting = false;
          });
          final toastContext = navigatorKey.currentContext ?? context;
          ToastManager.show(
            context: toastContext,
            message: response['message'] ?? 'Failed to accept order',
            type: ToastType.error,
          );
          _startTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
        final toastContext = navigatorKey.currentContext ?? context;
        ToastManager.show(
          context: toastContext,
          message: 'Error accepting order: $e',
          type: ToastType.error,
        );
        _startTimer();
      }
    }
  }

  List<Widget> _buildStoreList(Orders? order) {
    if (order?.deliveryRoute?.routeDetails == null ||
        order!.deliveryRoute!.routeDetails!.isEmpty) {
      return [
        CustomText(
          text: context.tr('storeDetailsNotAvailable'),
          color: AppColors.textColor,
          fontSize: sz(12),
        ),
      ];
    }

    final routeDetails = order.deliveryRoute!.routeDetails!;
    return List.generate(routeDetails.length, (index) {
      final store = routeDetails[index];
      final isLast = index == routeDetails.length - 1;
      final isCustomer = store.storeId == null || store.storeId == 0;

      final String displayName =
          isCustomer
              ? ((order.shippingName != null && order.shippingName!.isNotEmpty)
                  ? order.shippingName!
                  : (store.storeName ?? 'Customer'))
              : (store.storeName ?? 'Store');

      final String displayAddress =
          isCustomer
              ? _getCustomerAddress(order, store)
              : (store.address ?? '');

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: isCustomer ? const Color(0xFFE8F5E9) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        isCustomer
                            ? const Icon(
                              TablerIcons.map_pin,
                              color: Colors.black,
                              size: 20,
                            )
                            : CustomText(
                              text: _getStoreInitials(store.storeName ?? 'S'),
                              color: const Color(0xFF2C63C0),
                              fontSize: sz(14),
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                      child: CustomPaint(
                        painter: DashedLinePainter(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      text: displayName,
                      color: Colors.white,
                      fontSize: sz(15),
                      fontWeight: FontWeight.w700,
                    ),
                    if (displayAddress.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: CustomText(
                              text: displayAddress,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: sz(12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _getCustomerAddress(Orders? order, RouteDetails store) {
    if (store.address != null && store.address!.isNotEmpty) {
      return store.address!;
    }
    if (order == null) return '';
    final parts = <String>[];
    if (order.shippingAddress1 != null && order.shippingAddress1!.isNotEmpty) {
      parts.add(order.shippingAddress1!);
    }
    if (order.shippingAddress2 != null && order.shippingAddress2!.isNotEmpty) {
      parts.add(order.shippingAddress2!);
    }
    if (order.shippingLandmark != null && order.shippingLandmark!.isNotEmpty) {
      parts.add(order.shippingLandmark!);
    }
    if (order.shippingCity != null && order.shippingCity!.isNotEmpty) {
      parts.add(order.shippingCity!);
    }
    if (order.shippingState != null && order.shippingState!.isNotEmpty) {
      parts.add(order.shippingState!);
    }
    if (order.shippingZip != null && order.shippingZip!.isNotEmpty) {
      parts.add(order.shippingZip!);
    }
    return parts.isEmpty ? 'Customer Location' : parts.join(', ');
  }

  String _getStoreInitials(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName.toLowerCase() == 'store') {
      return 'S';
    }
    final words = cleanName.split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C63C0), Color(0xFFA305FA)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24.r),
                bottomRight: Radius.circular(24.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2C63C0).withValues(alpha: 0.4),
                  blurRadius: 20.r,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: kToolbarHeight),
                // Header (Timer and Close)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.white, size: 20.sp),
                        SizedBox(width: 8.w),
                        CustomText(
                          text: context.tr('autoDismissIn'),
                          color: Colors.white,
                          fontSize: sz(16),
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        CustomText(
                          text: '${_secondsRemaining}s',
                          color: Colors.white,
                          fontSize: sz(20),
                          fontWeight: FontWeight.w700,
                        ),
                        SizedBox(width: 16.w),
                        GestureDetector(
                          onTap: _dismissWithAnimation,
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              TablerIcons.x,
                              color: Colors.black,
                              size: 18.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 1.0,
                      end: _secondsRemaining / 30.0,
                    ),
                    duration: const Duration(seconds: 1),
                    curve: Curves.linear,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 8.h,
                      );
                    },
                  ),
                ),
                SizedBox(height: 16.h),

                // Conditional Body (Loading, Error, Loaded)
                if (_isLoading)
                  Container(
                    height: 160.h,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(color: Colors.white),
                  )
                else if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: CustomText(
                            text:
                                context.tr('failedToFetchDetails'),
                            color: Colors.white,
                            fontSize: sz(13),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: context.tr('orderNumber', positionalArgs: [widget.orderId]),
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: sz(12),
                                  fontWeight: FontWeight.w600,
                                ),
                                // SizedBox(height: 2.h),
                                // CustomText(
                                //   text: context.tr('expectedEarning'),
                                //   color: Colors.white.withValues(alpha: 0.9),
                                //   fontSize: sz(15),
                                //   fontWeight: FontWeight.w500,
                                // ),
                              ],
                            ),
                            // CustomText(
                            //   text: CurrencyFormatter.formatAmount(context, _order?.earnings?.total ?? '0'),
                            //   color: Colors.white,
                            //   fontSize: sz(28),
                            //   fontWeight: FontWeight.w800,
                            // ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        ..._buildStoreList(_order),
                      ],
                    ),
                  ),

                SizedBox(height: 20.h),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 45.h,
                  child: CustomSlideAction(
                    action: _acceptOrder,
                    text:
                        _isAccepting
                            ? context.tr('accepting')
                            : context.tr('acceptOrder'),
                    isLoading: _isAccepting,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 4, startY = 0;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
