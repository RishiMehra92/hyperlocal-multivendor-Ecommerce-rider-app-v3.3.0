import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/screens/feed_page/view/map/store_pickup_route/services/location_service.dart';
import 'package:hyper_local/screens/feed_page/view/map/store_pickup_route/services/map_service.dart';
import 'package:hyper_local/utils/location_tracker.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/screens/feed_page/model/available_orders.dart';
import 'package:hyper_local/screens/feed_page/model/return_orders_list_model.dart'
    hide RouteDetails;

enum MapViewMode {
  storePickup, // Regular order: Rider -> Stores (map_delivery_page.dart)
  customerDelivery, // Regular order: Rider -> Customer (pickup_route_map_page.dart)
  pickupFromCustomer, // Return order: Rider -> Seller (pickup_order_map_page.dart stage 0/1)
  returnToStore, // Return order: Rider -> Store (pickup_order_map_page.dart stage 2)
}

class UnifiedMapWidget extends StatefulWidget {
  final MapViewMode mode;
  final Orders? order; // For regular orders
  final Pickups? pickup; // For return/pickup orders

  // Custom overlays passed by the parent screen
  final Widget? bottomCard; // Specific bottom card UI
  final List<Widget>? topOverlays; // Additional top overlays

  // Callbacks
  final Function(LocationData)? onLocationUpdated;
  final Function(double? distance)? onDistanceCalculated;
  final VoidCallback? onMapReady;
  final VoidCallback? onNavigationPressed;

  const UnifiedMapWidget({
    super.key,
    required this.mode,
    this.order,
    this.pickup,
    this.bottomCard,
    this.topOverlays,
    this.onLocationUpdated,
    this.onDistanceCalculated,
    this.onMapReady,
    this.onNavigationPressed,
  });

  @override
  State<UnifiedMapWidget> createState() => _UnifiedMapWidgetState();
}

class _UnifiedMapWidgetState extends State<UnifiedMapWidget>
    with TickerProviderStateMixin {
  late MapController _mapController;
  LocationData? _currentLocation;
  bool _isLoadingLocation = true;
  List<LatLng> _accurateRoutePoints = [];
  StreamSubscription<LocationData>? _locationSubscription;
  double _riderRotation = 0;
  LatLng? _animatedRiderLatLng;
  AnimationController? _animationController;
  DateTime? _lastRerouteTime;
  bool _isFetchingRoute = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[UnifiedMap] initState called. Mode: ${widget.mode}, Order ID: ${widget.order?.id}, Pickup ID: ${widget.pickup?.id}',
    );
    _mapController = MapController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _getCurrentLocation();
  }

  @override
  void didUpdateWidget(covariant UnifiedMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the mode, order ID, or order status changed, we must recalculate the route and map bounds!
    if (widget.mode != oldWidget.mode ||
        widget.order?.id != oldWidget.order?.id ||
        widget.order?.status != oldWidget.order?.status ||
        widget.pickup?.id != oldWidget.pickup?.id) {
      debugPrint(
        '[UnifiedMap] didUpdateWidget triggered: mode, order, or status changed.',
      );

      // Clear old accurate route points so it recalculates
      setState(() {
        _accurateRoutePoints.clear();
      });

      // Trigger camera fit and route fetch in the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitMapToAllPoints();
          _fetchAccurateRoute();
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    debugPrint('[UnifiedMap] _getCurrentLocation() started');
    try {
      // 1. Check if we already have location in LocationTracker
      final cachedLocation = LocationTracker().currentLocation;
      debugPrint(
        '[UnifiedMap] LocationTracker cached location: ${cachedLocation != null ? 'lat=${cachedLocation.latitude}, lng=${cachedLocation.longitude}' : 'null'}',
      );

      if (cachedLocation != null) {
        setState(() {
          _currentLocation = cachedLocation;
          _isLoadingLocation = false;
        });

        _notifyDistanceAndLocation(cachedLocation);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint(
            '[UnifiedMap] PostFrame: Fitting map bounds and fetching accurate route using cached location',
          );
          _fitMapToAllPoints();
          _fetchAccurateRoute();
        });
      }

      // 2. Check and request permissions
      debugPrint('[UnifiedMap] Requesting location permission and services...');
      final hasPermission = await LocationService.requestPermissionAndService();
      debugPrint(
        '[UnifiedMap] Location permission check result: hasPermission = $hasPermission',
      );

      if (!mounted) return;

      if (!hasPermission) {
        debugPrint(
          '[UnifiedMap] Permission denied. Aborting location fetching.',
        );
        setState(() {
          _isLoadingLocation = false;
        });
        if (mounted) {
          ToastManager.show(
            context: context,
            message: context.tr('locationPermissionRequired'),
            type: ToastType.error,
          );
        }
        return; // Return early if no permission
      }

      // 3. Start listening to location updates
      _startLocationUpdates();

      // 4. If we didn't have cached location, fetch it now
      if (cachedLocation == null) {
        debugPrint(
          '[UnifiedMap] No cached location. Requesting current location from GPS...',
        );
        final locationData = await LocationService.getCurrentLocation();
        debugPrint(
          '[UnifiedMap] GPS direct location result: ${locationData != null ? 'lat=${locationData.latitude}, lng=${locationData.longitude}' : 'null'}',
        );

        if (!mounted) return;

        if (locationData != null) {
          setState(() {
            _currentLocation = locationData;
            _isLoadingLocation = false;
          });

          _notifyDistanceAndLocation(locationData);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint(
              '[UnifiedMap] PostFrame: Fitting map bounds and fetching accurate route using GPS location',
            );
            _fitMapToAllPoints();
            _fetchAccurateRoute();
          });
        } else {
          debugPrint(
            '[UnifiedMap] Failed to get location from GPS. Disabling loading indicator.',
          );
          setState(() {
            _isLoadingLocation = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitMapToAllPoints();
          });
        }
      }
    } catch (e) {
      debugPrint('[UnifiedMap] Exception in _getCurrentLocation(): $e');
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToAllPoints();
      });
    }
  }

  void _startLocationUpdates() {
    debugPrint(
      '[UnifiedMap] _startLocationUpdates() registering stream listener...',
    );
    _locationSubscription?.cancel();
    _locationSubscription = LocationService.getLocationStream().listen(
      (locationData) {
        if (!mounted) return;

        debugPrint(
          '[UnifiedMap] Stream update: lat=${locationData.latitude}, lng=${locationData.longitude}',
        );

        final oldLocation = _currentLocation;
        final newLatLng = LocationService.locationDataToLatLng(locationData);

        if (oldLocation != null && newLatLng != null) {
          final oldLatLng = LatLng(oldLocation.latitude, oldLocation.longitude);
          _animateRider(oldLatLng, newLatLng);
        } else if (newLatLng != null) {
          setState(() {
            _animatedRiderLatLng = newLatLng;
            _currentLocation = locationData;
          });
        }

        setState(() {
          _currentLocation = locationData;

          // Instant unlock
          if (_isLoadingLocation) {
            debugPrint(
              '[UnifiedMap] Stream location received. Initial unlock.',
            );
            _isLoadingLocation = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitMapToAllPoints();
              _fetchAccurateRoute();
            });
          }
        });

        _notifyDistanceAndLocation(locationData);
        _checkReroute(locationData);
      },
      onError: (error) {
        debugPrint('[UnifiedMap] Location stream error: $error');
        // Attempt to restart stream after delay if it crashed
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _isTrackingLocationActive()) {
            _startLocationUpdates();
          }
        });
      },
    );
  }

  bool _isTrackingLocationActive() => _locationSubscription != null;

  void _notifyDistanceAndLocation(LocationData locationData) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onLocationUpdated?.call(locationData);
      if (widget.onDistanceCalculated != null) {
        final distance = _calculateDistance(locationData);
        widget.onDistanceCalculated?.call(distance);
      }
    });
  }

  double? _calculateDistance(LocationData? currentLocation) {
    if (currentLocation == null) return null;
    final currentLatLng = LatLng(
      currentLocation.latitude,
      currentLocation.longitude,
    );

    // If we have an accurate road route, calculate the distance along the road path
    if (_accurateRoutePoints.isNotEmpty) {
      final trimmedRoute = MapService.trimRouteToCurrentLocation(
        currentLatLng,
        _accurateRoutePoints,
      );
      double totalRoadDistance = 0.0;
      for (int i = 0; i < trimmedRoute.length - 1; i++) {
        totalRoadDistance += MapService.calculateDistance(
          trimmedRoute[i],
          trimmedRoute[i + 1],
        );
      }
      return totalRoadDistance;
    }

    // Return null if we don't have an accurate route yet
    return null;
  }

  void _animateRider(LatLng from, LatLng to) {
    if (from == to || !_isValidLatLng(from) || !_isValidLatLng(to)) return;

    final double bearing = _calculateBearing(from, to);
    final latTween = Tween<double>(begin: from.latitude, end: to.latitude);
    final lngTween = Tween<double>(begin: from.longitude, end: to.longitude);

    _animationController!.reset();
    final Animation<double> localAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.linear,
    );

    localAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _animatedRiderLatLng = LatLng(
            latTween.evaluate(localAnimation),
            lngTween.evaluate(localAnimation),
          );
          _riderRotation = bearing;
        });
      }
    });

    _animationController!.forward();
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180;
    final double lon1 = from.longitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double lon2 = to.longitude * math.pi / 180;

    final double dLon = lon2 - lon1;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final double radians = math.atan2(y, x);
    return (radians * 180 / math.pi + 360) % 360;
  }

  void _checkReroute(LocationData currentLocation) {
    if (_isFetchingRoute) return;

    final now = DateTime.now();
    if (_lastRerouteTime != null &&
        now.difference(_lastRerouteTime!) < const Duration(seconds: 15)) {
      return;
    }

    final currentLatLng = LatLng(
      currentLocation.latitude,
      currentLocation.longitude,
    );

    if (_accurateRoutePoints.isEmpty ||
        MapService.isPointOffRoute(
          currentLatLng,
          _accurateRoutePoints,
          thresholdMeters: 40.0,
        )) {
      _fetchAccurateRoute();
    }
  }

  List<LatLng> _generateRoute() {
    final List<LatLng> routePoints = [];

    final currentLatLng = _getCurrentLocationLatLng();
    if (currentLatLng != null) {
      routePoints.add(currentLatLng);
    }

    if (widget.mode == MapViewMode.storePickup) {
      if (widget.order?.deliveryRoute?.routeDetails != null) {
        final stores = MapService.getFilteredStores(
          widget.order!.deliveryRoute!.routeDetails,
        );
        for (final store in stores) {
          if (store.latitude != null && store.longitude != null) {
            final storePoint = LatLng(store.latitude!, store.longitude!);
            if (_isValidLatLng(storePoint)) {
              routePoints.add(storePoint);
            }
          }
        }
      }
    } else if (widget.mode == MapViewMode.customerDelivery) {
      if (widget.order?.deliveryRoute?.routeDetails != null &&
          widget.order!.deliveryRoute!.routeDetails!.isNotEmpty) {
        final destLocation = widget.order!.deliveryRoute!.routeDetails!.last;
        if (destLocation.latitude != null && destLocation.longitude != null) {
          final destPoint = LatLng(
            destLocation.latitude!,
            destLocation.longitude!,
          );
          if (_isValidLatLng(destPoint)) {
            routePoints.add(destPoint);
          }
        }
      }
    } else if (widget.mode == MapViewMode.pickupFromCustomer ||
        widget.mode == MapViewMode.returnToStore) {
      if (widget.pickup?.deliveryRoute?.routeDetails != null &&
          widget.pickup!.deliveryRoute!.routeDetails!.isNotEmpty) {
        if (widget.mode == MapViewMode.pickupFromCustomer) {
          final customerLocation =
              widget.pickup!.deliveryRoute!.routeDetails!.last;
          if (customerLocation.latitude != null &&
              customerLocation.longitude != null) {
            final customerPoint = LatLng(
              customerLocation.latitude!,
              customerLocation.longitude!,
            );
            if (_isValidLatLng(customerPoint)) {
              routePoints.add(customerPoint);
            }
          }
        } else if (widget.mode == MapViewMode.returnToStore) {
          final storeLocation = widget.pickup!.deliveryRoute!.routeDetails![0];
          if (storeLocation.latitude != null &&
              storeLocation.longitude != null) {
            final storePoint = LatLng(
              storeLocation.latitude!,
              storeLocation.longitude!,
            );
            if (_isValidLatLng(storePoint)) {
              routePoints.add(storePoint);
            }
          }
        }
      }
    }

    return routePoints;
  }

  LatLng? _getDestinationLocation() {
    if (widget.mode == MapViewMode.storePickup ||
        widget.mode == MapViewMode.customerDelivery) {
      return LocationService.getDestinationLocation(
        widget.order?.deliveryRoute?.routeDetails,
      );
    }
    return null;
  }

  LatLng _getInitialMapCenter() {
    final currentLatLng = _getCurrentLocationLatLng();
    if (currentLatLng != null && _isValidLatLng(currentLatLng)) {
      return currentLatLng;
    }

    if (widget.mode == MapViewMode.pickupFromCustomer ||
        widget.mode == MapViewMode.returnToStore) {
      if (widget.pickup?.deliveryRoute?.routeDetails != null &&
          widget.pickup!.deliveryRoute!.routeDetails!.isNotEmpty) {
        final targetLocation =
            widget.mode == MapViewMode.pickupFromCustomer
                ? widget.pickup!.deliveryRoute!.routeDetails!.last
                : widget.pickup!.deliveryRoute!.routeDetails![0];
        if (targetLocation.latitude != null &&
            targetLocation.longitude != null) {
          final targetLatLng = LatLng(
            targetLocation.latitude!,
            targetLocation.longitude!,
          );
          if (_isValidLatLng(targetLatLng)) {
            return targetLatLng;
          }
        }
      }
    }

    final destLatLng = _getDestinationLocation();
    if (destLatLng != null && _isValidLatLng(destLatLng)) {
      return destLatLng;
    }

    if (widget.order?.deliveryRoute?.routeDetails != null) {
      final stores = MapService.getFilteredStores(
        widget.order!.deliveryRoute!.routeDetails,
      );
      if (stores.isNotEmpty) {
        final firstStore = stores.first;
        if (firstStore.latitude != null && firstStore.longitude != null) {
          final storeLatLng = LatLng(
            firstStore.latitude!,
            firstStore.longitude!,
          );
          if (_isValidLatLng(storeLatLng)) {
            return storeLatLng;
          }
        }
      }
    }

    final shippingLat = double.tryParse(widget.order?.shippingLatitude ?? '');
    final shippingLng = double.tryParse(widget.order?.shippingLongitude ?? '');
    if (shippingLat != null && shippingLng != null) {
      final orderLatLng = LatLng(shippingLat, shippingLng);
      if (_isValidLatLng(orderLatLng)) {
        return orderLatLng;
      }
    }

    return const LatLng(0, 0);
  }

  LatLng? _getCurrentLocationLatLng() {
    if (_currentLocation != null) {
      final latLng = LatLng(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
      if (_isValidLatLng(latLng)) {
        return latLng;
      }
    }
    return null;
  }

  bool _isValidLatLng(LatLng point) {
    return !point.latitude.isNaN &&
        !point.latitude.isInfinite &&
        !point.longitude.isNaN &&
        !point.longitude.isInfinite &&
        point.latitude >= -90.0 &&
        point.latitude <= 90.0 &&
        point.longitude >= -180.0 &&
        point.longitude <= 180.0;
  }

  void _fitMapToAllPoints() {
    try {
      final List<LatLng> allPoints = [];

      // Add current location if available
      final currentLatLng = _getCurrentLocationLatLng();
      if (currentLatLng != null && _isValidLatLng(currentLatLng)) {
        allPoints.add(currentLatLng);
      }

      // Add destination or stores based on mode
      if (widget.mode == MapViewMode.storePickup ||
          widget.mode == MapViewMode.customerDelivery) {
        if (widget.order?.deliveryRoute?.routeDetails != null) {
          final routeDetails = widget.order!.deliveryRoute!.routeDetails!;

          if (widget.mode == MapViewMode.storePickup) {
            final stores = MapService.getFilteredStores(routeDetails);
            for (final store in stores) {
              if (store.latitude != null && store.longitude != null) {
                final storePoint = LatLng(store.latitude!, store.longitude!);
                if (_isValidLatLng(storePoint)) {
                  allPoints.add(storePoint);
                }
              }
            }
          } else {
            // Customer delivery
            final destLatLng = _getDestinationLocation();
            if (destLatLng != null && _isValidLatLng(destLatLng)) {
              allPoints.add(destLatLng);
            }
          }
        }
      } else {
        // Return orders
        if (widget.pickup?.deliveryRoute?.routeDetails != null &&
            widget.pickup!.deliveryRoute!.routeDetails!.isNotEmpty) {
          final targetLocation =
              widget.mode == MapViewMode.pickupFromCustomer
                  ? widget.pickup!.deliveryRoute!.routeDetails!.last
                  : widget.pickup!.deliveryRoute!.routeDetails![0];
          if (targetLocation.latitude != null &&
              targetLocation.longitude != null) {
            final targetPoint = LatLng(
              targetLocation.latitude!,
              targetLocation.longitude!,
            );
            if (_isValidLatLng(targetPoint)) {
              allPoints.add(targetPoint);
            }
          }
        }
      }

      final validPoints = allPoints.where((p) => _isValidLatLng(p)).toList();

      if (validPoints.length >= 2) {
        final distinctPoints = validPoints.fold<List<LatLng>>([], (list, p) {
          if (list.isEmpty ||
              list.every(
                (existing) =>
                    (existing.latitude - p.latitude).abs() > 0.000001 ||
                    (existing.longitude - p.longitude).abs() > 0.000001,
              )) {
            list.add(p);
          }
          return list;
        });

        if (distinctPoints.length >= 2) {
          final bounds = LatLngBounds.fromPoints(distinctPoints);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50.w)),
          );
        } else if (distinctPoints.isNotEmpty) {
          _mapController.move(distinctPoints.first, 15.0);
        }
      } else if (validPoints.isNotEmpty) {
        _mapController.move(validPoints.first, 15.0);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _fetchAccurateRoute() async {
    if (_currentLocation == null) {
      debugPrint('[UnifiedMap] Cannot fetch route: Current location is null');
      return;
    }
    if (_isFetchingRoute) {
      debugPrint(
        '[UnifiedMap] Skipped route fetch: A fetch is already in progress',
      );
      return;
    }

    _isFetchingRoute = true;
    _lastRerouteTime = DateTime.now();

    try {
      final routePoints = _generateRoute();
      debugPrint(
        '[UnifiedMap] Generating base route points. Base count: ${routePoints.length}',
      );

      if (routePoints.length >= 2) {
        final accuratePoints = await MapService.fetchAccurateRoute(routePoints);

        // Check if the returned points are the same as the base points (meaning fallback occurred)
        final bool isFallback =
            accuratePoints.length == routePoints.length &&
            accuratePoints.first == routePoints.first &&
            accuratePoints.last == routePoints.last;

        if (isFallback) {
          debugPrint(
            '[UnifiedMap] Rendering straight-line fallback route between points',
          );
        } else {
          debugPrint('[UnifiedMap] Rendering accurate road route on map');
        }

        if (mounted) {
          setState(() {
            _accurateRoutePoints = accuratePoints;
          });
          if (_currentLocation != null) {
            _notifyDistanceAndLocation(_currentLocation!);
          }
        }
      } else {
        debugPrint(
          '[UnifiedMap] Cannot fetch road route: Base route has less than 2 points',
        );
      }
    } finally {
      _isFetchingRoute = false;
    }
  }

  List<Polyline> _buildRoutePolylines() {
    var routePoints =
        _accurateRoutePoints.isNotEmpty
            ? _accurateRoutePoints
            : _generateRoute();

    routePoints = routePoints.where((p) => _isValidLatLng(p)).toList();

    if (routePoints.length < 2) return [];

    final currentLatLng = _getCurrentLocationLatLng();
    if (currentLatLng != null && _accurateRoutePoints.isNotEmpty) {
      routePoints = MapService.trimRouteToCurrentLocation(
        currentLatLng,
        routePoints,
      );
    }

    return [
      Polyline(
        points: routePoints,
        strokeWidth: 5,
        color: AppColors.primaryColor,
        strokeCap: StrokeCap.round,
      ),
    ];
  }

  List<Marker> _buildAllMarkers() {
    LocationData? animatedLocation;
    if (_animatedRiderLatLng != null) {
      animatedLocation = LocationData.fromMap({
        'latitude': _animatedRiderLatLng!.latitude,
        'longitude': _animatedRiderLatLng!.longitude,
      });
    }

    if (widget.mode == MapViewMode.storePickup) {
      return MapService.buildPickupMarkers(
        animatedLocation ?? _currentLocation,
        widget.order?.deliveryRoute?.routeDetails,
        rotation: _riderRotation,
        onStoreTap: (stores) {
          _showStoreDetailsPopover(stores);
        },
      );
    } else if (widget.mode == MapViewMode.customerDelivery) {
      return MapService.buildDeliveryMarkers(
        animatedLocation ?? _currentLocation,
        widget.order?.deliveryRoute?.routeDetails,
        rotation: _riderRotation,
      );
    } else {
      // Return order markers
      final markers = <Marker>[];
      final currentLoc = animatedLocation ?? _currentLocation;

      // Rider marker
      if (MapService.isValidLatLng(
        currentLoc?.latitude,
        currentLoc?.longitude,
      )) {
        markers.add(
          Marker(
            point: LatLng(currentLoc!.latitude, currentLoc.longitude),
            width: 45.w,
            height: 45.h,
            child: Transform.rotate(
              angle: _riderRotation * pi / 180,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_bike,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        );
      }

      // Customer/Seller and Store markers
      if (widget.pickup?.deliveryRoute?.routeDetails != null &&
          widget.pickup!.deliveryRoute!.routeDetails!.isNotEmpty) {
        if (widget.mode == MapViewMode.returnToStore) {
          final storeLocation = widget.pickup!.deliveryRoute!.routeDetails![0];
          if (MapService.isValidLatLng(
            storeLocation.latitude,
            storeLocation.longitude,
          )) {
            markers.add(
              Marker(
                point: LatLng(
                  storeLocation.latitude!,
                  storeLocation.longitude!,
                ),
                width: 45.w,
                height: 45.h,
                child: GestureDetector(
                  onTap: () {
                    _showStoreDetailsPopover([
                      RouteDetails(
                        storeId: storeLocation.storeId,
                        storeName: storeLocation.storeName,
                        address: storeLocation.address,
                        latitude: storeLocation.latitude,
                        longitude: storeLocation.longitude,
                      ),
                    ]);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Icon(Icons.store, color: Colors.white, size: 20.sp),
                  ),
                ),
              ),
            );
          }
        } else {
          final customerLocation =
              widget.pickup!.deliveryRoute!.routeDetails!.last;
          if (MapService.isValidLatLng(
            customerLocation.latitude,
            customerLocation.longitude,
          )) {
            markers.add(
              Marker(
                point: LatLng(
                  customerLocation.latitude!,
                  customerLocation.longitude!,
                ),
                width: 45.w,
                height: 45.h,
                child: GestureDetector(
                  onTap: () {
                    _showStoreDetailsPopover([
                      RouteDetails(
                        storeId: customerLocation.storeId,
                        storeName: customerLocation.storeName,
                        address: customerLocation.address,
                        latitude: customerLocation.latitude,
                        longitude: customerLocation.longitude,
                      ),
                    ]);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_pin_circle,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            );
          }
        }
      }

      return markers;
    }
  }

  Widget _buildStoreDetailsRow(RouteDetails store) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          TablerIcons.building_store,
          color: AppColors.primaryColor,
          size: 28.sp,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: store.storeName ?? 'Unknown Store',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              SizedBox(height: 4.h),
              CustomText(
                text: store.address ?? store.landmark ?? 'No address provided',
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStoreDetailsPopover(List<RouteDetails> stores) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[350],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                CustomText(
                  text:
                      stores.length > 1
                          ? 'Stores at this Location'
                          : 'Store Details',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                SizedBox(height: 12.h),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (int i = 0; i < stores.length; i++) ...[
                          if (i > 0)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color:
                                    isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                              ),
                            ),
                          _buildStoreDetailsRow(stores[i]),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onMapReady() {
    widget.onMapReady?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToAllPoints();
      if (_currentLocation != null) {
        _notifyDistanceAndLocation(_currentLocation!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _getInitialMapCenter(),
            initialZoom: 15.0,
            onMapReady: _onMapReady,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://server.arcgisonline.com/ArcGIS/rest/services/'
                  'World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: AppConstant.packageName,
            ),
            if (_buildRoutePolylines().isNotEmpty)
              PolylineLayer(polylines: _buildRoutePolylines()),
            MarkerLayer(markers: _buildAllMarkers()),
          ],
        ),

        // Loading Overlay
        if (_isLoadingLocation)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: context.tr('loadingMap'),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

        // Custom Top Overlays
        if (widget.topOverlays != null) ...widget.topOverlays!,

        // Navigation FloatingActionButton (top right)
        // Positioned(
        //   top: 20.h,
        //   right: 20.w,
        //   child: FloatingActionButton(
        //     heroTag: 'unified_map_nav_btn',
        //     onPressed: _onNavigationPressed,
        //     backgroundColor: AppColors.primaryColor,
        //     foregroundColor: Colors.white,
        //     child: const Icon(Icons.navigation),
        //   ),
        // ),

        // Pinned Bottom Card
        if (widget.bottomCard != null) widget.bottomCard!,
      ],
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _animationController?.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
