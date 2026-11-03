import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:popover/popover.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import '../../../router/app_routes.dart';
import 'package:hyper_local/config/app_images.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/currency_formatter.dart';
import '../../../config/colors.dart';
import '../../dashboard/bloc/notification/notification_bloc.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import '../../feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../../feed_page/bloc/available_orders_bloc/available_orders_bloc.dart';
import '../../feed_page/bloc/available_orders_bloc/available_orders_event.dart';
import '../../feed_page/bloc/available_orders_bloc/available_orders_state.dart';
import '../../feed_page/widgets/header_section/home_header_section.dart';
import '../bloc/inactive_page_stats/home_stats_bloc.dart';
import '../bloc/inactive_page_stats/home_stats_state.dart';
import '../bloc/inactive_page_stats/home_stats_event.dart';
import '../model/home_stats_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../config/constant.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import '../../settings/bloc/profile_bloc/profile_bloc.dart';
import '../../settings/bloc/profile_bloc/profile_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LatLng _centerLatLng = const LatLng(23.2488453, 69.6696795);
  String _selectedChartPeriod = '';
  late final AnimationController _mapAnimationController;
  late final AnimationController _pulsingController;
  bool _hasFocusedMap = false;
  bool _isMapReady = false;

  void _autoFocusMap(ProfileData? profileData) {
    if (profileData == null || !_isMapReady || _hasFocusedMap) return;

    final zone = profileData.deliveryBoy.deliveryZone;
    LatLng center = _centerLatLng;
    if (zone != null && zone.boundaryJson.isNotEmpty) {
      final firstPoint = zone.boundaryJson.first;
      center = LatLng(firstPoint.lat, firstPoint.lng);
    } else if (zone != null) {
      final double? lat = double.tryParse(zone.centerLatitude);
      final double? lng = double.tryParse(zone.centerLongitude);
      if (lat != null && lng != null) {
        center = LatLng(lat, lng);
      }
    }

    final List<LatLng> polygonPoints = [];
    if (zone != null && zone.boundaryJson.isNotEmpty) {
      for (final point in zone.boundaryJson) {
        polygonPoints.add(LatLng(point.lat, point.lng));
      }
    }

    final List<LatLng> fitPoints = List.from(polygonPoints);
    final stores = profileData.deliveryBoy.stores;
    for (final store in stores) {
      final double? storeLat = double.tryParse(store.latitude);
      final double? storeLng = double.tryParse(store.longitude);
      if (storeLat != null && storeLng != null) {
        fitPoints.add(LatLng(storeLat, storeLng));
      }
    }

    // Filter to find distinct geographical points to prevent division by zero or coordinate fit errors
    final List<LatLng> distinctFitPoints = [];
    for (final p in fitPoints) {
      if (distinctFitPoints.isEmpty ||
          distinctFitPoints.every(
            (existing) =>
                (existing.latitude - p.latitude).abs() > 0.000001 ||
                (existing.longitude - p.longitude).abs() > 0.000001,
          )) {
        distinctFitPoints.add(p);
      }
    }

    _hasFocusedMap = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (distinctFitPoints.length >= 2) {
          final bounds = LatLngBounds.fromPoints(distinctFitPoints);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: EdgeInsets.only(
                top: 120.h,
                bottom: 120.h,
                left: 40.w,
                right: 40.w,
              ),
            ),
          );
        } else if (distinctFitPoints.isNotEmpty) {
          _mapController.move(distinctFitPoints.first, 14.5);
        } else {
          _mapController.move(center, 14.5);
        }
      } catch (e) {
        debugPrint('Error fitting camera or moving map: $e');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _mapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulsingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    context.read<HomeStatsBloc>().add(const FetchHomeStats());
    context.read<AvailableOrdersBloc>().add(
      AllAvailableOrdersList(forceRefresh: true),
    );
    context.read<NotificationBloc>().add(FetchNotifications());
  }

  @override
  void dispose() {
    _mapAnimationController.dispose();
    _pulsingController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedChartPeriod.isEmpty) {
      _selectedChartPeriod = context.tr('week');
    }
    // Sync with current delivery boy status when page becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryBoyStatusBloc>().add(const CheckApiStatus());
    });
  }

  List<LatLng> _ensureClockwise(List<LatLng> points) {
    if (points.length < 3) return points;
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      area += p1.longitude * p2.latitude - p2.longitude * p1.latitude;
    }
    if (area > 0) {
      return points.reversed.toList();
    }
    return points;
  }

  double _distance(LatLng p1, LatLng p2) {
    final dx = p2.longitude - p1.longitude;
    final dy = p2.latitude - p1.latitude;
    return math.sqrt(dx * dx + dy * dy);
  }

  List<double> _computeCumulativeDistances(List<LatLng> points) {
    final distances = <double>[0.0];
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      distances.add(distances.last + _distance(p1, p2));
    }
    return distances;
  }

  LatLng _interpolatePoint(
    List<LatLng> points,
    List<double> cumDistances,
    double d,
  ) {
    if (points.isEmpty) return const LatLng(0, 0);
    if (d.isNaN || d.isInfinite || d <= 0.0) return points.first;
    final totalDistance = cumDistances.last;
    if (d >= totalDistance) return points.first;

    for (int i = 0; i < points.length; i++) {
      if (d >= cumDistances[i] && d <= cumDistances[i + 1]) {
        final p1 = points[i];
        final p2 = points[(i + 1) % points.length];
        final segmentLength = cumDistances[i + 1] - cumDistances[i];
        if (segmentLength < 1e-9) return p1;
        final t = (d - cumDistances[i]) / segmentLength;
        if (t.isNaN || t.isInfinite) return p1;

        final lat = p1.latitude + (p2.latitude - p1.latitude) * t;
        final lng = p1.longitude + (p2.longitude - p1.longitude) * t;
        if (lat.isNaN || lat.isInfinite || lng.isNaN || lng.isInfinite) {
          return p1;
        }
        return LatLng(lat, lng);
      }
    }
    return points.first;
  }

  List<LatLng> _getSubroute(
    List<LatLng> points,
    List<double> cumDistances,
    double startDist,
    double endDist,
  ) {
    final totalDistance = cumDistances.last;
    final result = <LatLng>[];

    final s = startDist % totalDistance;
    final e = endDist % totalDistance;

    if (s < e) {
      result.add(_interpolatePoint(points, cumDistances, s));
      for (int i = 0; i < points.length; i++) {
        final d = cumDistances[i];
        if (d > s && d < e) {
          result.add(points[i]);
        }
      }
      result.add(_interpolatePoint(points, cumDistances, e));
    } else {
      result.add(_interpolatePoint(points, cumDistances, s));
      for (int i = 0; i < points.length; i++) {
        final d = cumDistances[i];
        if (d > s) {
          result.add(points[i]);
        }
      }
      for (int i = 0; i < points.length; i++) {
        final d = cumDistances[i];
        if (d < e) {
          result.add(points[i]);
        }
      }
      result.add(_interpolatePoint(points, cumDistances, e));
    }
    return result;
  }

  Widget _buildStorePopoverContent(StoreData store, BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (store.logo != null && store.logo!.isNotEmpty)
            CustomImageContainer(
              imagePath: store.logo!,
              height: 100.h,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          else
            Container(
              height: 100.h,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.storefront,
                size: 40.r,
                color: AppColors.primaryColor,
              ),
            ),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: store.name,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                if (store.address != null && store.address!.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14.sp,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: CustomText(
                          text: store.address!,
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
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
        ],
      ),
    );
  }

  Widget _buildStoreMarker(StoreData store) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            showPopover(
              radius: 14,
              context: context,
              bodyBuilder:
                  (context) => _buildStorePopoverContent(store, context),
              direction: PopoverDirection.top,
              width: 240.w,
              height:
                  (store.address != null && store.address!.isNotEmpty)
                      ? 190.h
                      : 155.h,
              arrowHeight: 12,
              arrowWidth: 24,
              backgroundColor: Theme.of(context).colorScheme.surface,
            );
          },
          child: Container(
            padding: EdgeInsets.all(3.r),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2.r),
            ),
            child: ClipOval(
              child:
                  store.logo != null && store.logo!.isNotEmpty
                      ? CustomImageContainer(
                        imagePath: store.logo!,
                        width: 34.w,
                        height: 34.h,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          color: Colors.white,
                          child: Icon(
                            Icons.storefront,
                            color: AppColors.primaryColor,
                            size: 20.r,
                          ),
                        ),
                      )
                      : Container(
                        color: Colors.white,
                        child: Icon(
                          Icons.storefront,
                          color: AppColors.primaryColor,
                          size: 20.r,
                        ),
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundMap(ProfileData? profileData) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    LatLng center = _centerLatLng;
    final zone = profileData?.deliveryBoy.deliveryZone;
    if (zone != null && zone.boundaryJson.isNotEmpty) {
      final firstPoint = zone.boundaryJson.first;
      center = LatLng(firstPoint.lat, firstPoint.lng);
    } else if (zone != null) {
      final double? lat = double.tryParse(zone.centerLatitude);
      final double? lng = double.tryParse(zone.centerLongitude);
      if (lat != null && lng != null) {
        center = LatLng(lat, lng);
      }
    }

    final List<LatLng> polygonPoints = [];
    if (zone != null && zone.boundaryJson.isNotEmpty) {
      for (final point in zone.boundaryJson) {
        polygonPoints.add(LatLng(point.lat, point.lng));
      }
    }

    final List<Marker> storeMarkers = [];
    final List<LatLng> fitPoints = List.from(polygonPoints);
    final stores = profileData?.deliveryBoy.stores;
    if (stores != null) {
      for (final store in stores) {
        final double? storeLat = double.tryParse(store.latitude);
        final double? storeLng = double.tryParse(store.longitude);
        if (storeLat != null && storeLng != null) {
          final latLng = LatLng(storeLat, storeLng);
          fitPoints.add(latLng);
          storeMarkers.add(
            Marker(
              point: latLng,
              width: 40.w,
              height: 40.h,
              child: _buildStoreMarker(store),
            ),
          );
        }
      }
    }

    final clockwisePoints = _ensureClockwise(polygonPoints);
    final cumDistances =
        clockwisePoints.isNotEmpty
            ? _computeCumulativeDistances(clockwisePoints)
            : <double>[];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.5,
        initialCameraFit:
            fitPoints.isNotEmpty
                ? CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(fitPoints),
                  padding: EdgeInsets.only(
                    top: 120.h,
                    bottom: 120.h,
                    left: 40.w,
                    right: 40.w,
                  ),
                )
                : null,
        onMapReady: () {
          _isMapReady = true;
          _autoFocusMap(profileData);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: AppConstant.packageName,
          maxZoom: 19,
          minZoom: 0.0,
          tileBuilder:
              isDark
                  ? (context, tileWidget, tile) {
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        // High-visibility dark mode inversion matrix (keeps roads bright and land dark)
                        -0.9, 0, 0, 0, 255,
                        0, -0.9, 0, 0, 255,
                        0, 0, -0.9, 0, 255,
                        0, 0, 0, 1, 0,
                      ]),
                      child: tileWidget,
                    );
                  }
                  : null,
        ),
        if (polygonPoints.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: polygonPoints,
                color: AppColors.primaryColor.withValues(alpha: 0.15),
                borderColor: isDark ? Colors.white30 : Colors.black26,
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
        if (clockwisePoints.isNotEmpty && cumDistances.isNotEmpty)
          AnimatedBuilder(
            animation: _mapAnimationController,
            builder: (context, child) {
              final totalDist = cumDistances.last;

              // Define dash and gap length to be very small (small dotted lines)
              final dashLen = totalDist * 0.006; // 0.6% dash
              final gapLen = totalDist * 0.01; // 1% gap
              final patternLen = dashLen + gapLen;

              if (totalDist < 1e-7 || patternLen < 1e-9) {
                return const SizedBox.shrink();
              }

              // Map the animation value (0 to 1) to a shift of exactly one pattern length
              final offset = _mapAnimationController.value * patternLen;

              final List<Polyline<Object>> dashLines = [];

              // Generate dashes across the entire perimeter
              for (double d = 0; d < totalDist; d += patternLen) {
                final startDist = (d + offset) % totalDist;
                final endDist = startDist + dashLen;

                final subroute = _getSubroute(
                  clockwisePoints,
                  cumDistances,
                  startDist,
                  endDist,
                );

                dashLines.add(
                  Polyline(
                    points: subroute,
                    color: AppColors.primaryColor,
                    strokeWidth: 2.5,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                );
              }

              return PolylineLayer(polylines: dashLines);
            },
          ),
        if (polygonPoints.isNotEmpty)
          MarkerLayer(
            markers:
                polygonPoints.map((point) {
                  return Marker(
                    point: point,
                    width: 8.w,
                    height: 8.h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white70 : Colors.black87,
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        if (storeMarkers.isNotEmpty) MarkerLayer(markers: storeMarkers),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      wantSafeArea: false,
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            final statsCompleter = Completer<void>();
            final ordersCompleter = Completer<void>();
            final profileCompleter = Completer<void>();
            context.read<HomeStatsBloc>().add(
              RefreshHomeStats(completer: statsCompleter),
            );
            context.read<AvailableOrdersBloc>().add(
              AllAvailableOrdersList(
                forceRefresh: true,
                completer: ordersCompleter,
              ),
            );
            context.read<ProfileBloc>().add(
              LoadProfile(completer: profileCompleter),
            );
            await Future.wait([
              statsCompleter.future,
              ordersCompleter.future,
              profileCompleter.future,
            ]);
            setState(() {
              _hasFocusedMap = false;
            });
          } catch (e) {
            //
          }
        },
        child: BlocConsumer<HomeStatsBloc, HomeStatsState>(
          listener: (context, homeStatsState) {
            if (homeStatsState.status == ApiStatus.success &&
                homeStatsState.response != null) {
              final profileData = _findDataByKey(
                homeStatsState.response!.data,
                'profile',
                (data) => data.profileData,
              );
              _autoFocusMap(profileData);
            }
          },
          builder: (context, homeStatsState) {
            if ((homeStatsState.status == ApiStatus.initial ||
                    homeStatsState.status == ApiStatus.loading) &&
                homeStatsState.response == null) {
              return const Center(child: LoadingWidget());
            } else if (homeStatsState.status == ApiStatus.failed &&
                homeStatsState.response == null) {
              return EmptyStateWidget.noData(
                onRetry: () {
                  context.read<HomeStatsBloc>().add(const FetchHomeStats());
                  context.read<AvailableOrdersBloc>().add(
                    AllAvailableOrdersList(forceRefresh: true),
                  );
                },
              );
            } else if (homeStatsState.response != null) {
              return _buildHomeStatsContent(homeStatsState.response!);
            } else {
              return Center(
                child: CustomText(
                  text: context.tr('noDataAvailable'),
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildHomeStatsContent(HomeStatsResponse response) {
    final profileData = _findDataByKey(
      response.data,
      'profile',
      (data) => data.profileData,
    );
    final summaryData = _findDataByKey(
      response.data,
      'summary',
      (data) => data.summaryData,
    );
    final performanceData = _findDataByKey(
      response.data,
      'performanceMetrics',
      (data) => data.performanceMetricsData,
    );
    final todayData = _findDataByKey(
      response.data,
      'todayProgress',
      (data) => data.todayProgressData,
    );
    final earningsAnalytics = _findDataByKey(
      response.data,
      'earningsAnalytics',
      (data) => data.earningsAnalyticsData,
    );

    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Map Header Section
          Container(
            color: Colors.red,
            height: isTablet() ? MediaQuery.of(context).size.height * 0.5 : 450,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background Map (IgnorePointer so dragging scrolls the page)
                _buildBackgroundMap(profileData),

                // Blur effect at the bottom where the earnings card intersects the map
                Positioned(
                  bottom: -10,
                  left: 0,
                  right: 0,
                  height: 90.h,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.1),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.0),
                              Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Today's Earning card overlapping the bottom of the map
                Positioned(
                  bottom: -40,
                  left: 8,
                  right: 8,
                  child: _buildEarningsCard(summaryData, response.hashCode),
                ),
                Positioned(
                  top: kToolbarHeight + 10,
                  left: 16.w,
                  right: 16.w,
                  child: BlocBuilder<
                    DeliveryBoyStatusBloc,
                    DeliveryBoyStatusState
                  >(
                    builder: (context, statusState) {
                      bool currentStatus = statusState.isOnline;
                      return HomeHeaderSection(
                        handleToggle: () {
                          try {
                            final bloc = context.read<DeliveryBoyStatusBloc>();
                            final newValue = !currentStatus;
                            bloc.add(ToggleStatus(newValue));
                          } catch (e) {}
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _buildThreeStatsRow(
                  performanceData,
                  todayData,
                  profileData,
                  response.hashCode,
                ),
              ],
            ),
          ),
          if (earningsAnalytics != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: _buildEarningsChart(earningsAnalytics.charts),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(SummaryData? summaryData, int responseHash) {
    final earnings = summaryData?.today.earnings ?? 0.0;
    final totalEarnings = summaryData?.total.earnings ?? 0.0;

    return AnimatedBuilder(
      animation: _pulsingController,
      builder: (context, child) {
        final pulse = _pulsingController.value;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: RadialGradient(
              colors: [
                Color.lerp(
                  AppColors.primaryColor,
                  Colors.white,
                  0.22 + (pulse * 0.06),
                )!,
                AppColors.primaryColor,
              ],
              center: Alignment.center,
              radius: 0.70 + (pulse * 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(
                  alpha: 0.2 + (pulse * 0.15),
                ),
                blurRadius: 8 + (pulse * 8),
                offset: Offset(0, 3 + (pulse * 2)),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: context.tr('todaysEarnings'),
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 8),
                CustomText(
                  text: CurrencyFormatter.formatAmount(
                    context,
                    earnings.toStringAsFixed(2),
                  ),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: Colors.greenAccent,
                      size: 14.sp,
                    ),
                    const SizedBox(width: 2),

                    CustomText(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                      text:
                          "${context.tr('total')}: ${CurrencyFormatter.formatAmount(context, totalEarnings.toStringAsFixed(2))}",
                    ),
                  ],
                ),
              ],
            ),
          ),

          const CustomImageContainer(
            imagePath: AppImages.dashboardWalletImage,
            height: 100,
            width: 120,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildThreeStatsRow(
    PerformanceMetricsData? performanceData,
    TodayProgressData? todayData,
    ProfileData? profileData,
    int responseHash,
  ) {
    final deliveredCount =
        performanceData?.ordersDelivered ??
        profileData?.deliveryBoy.totalDeliveries ??
        25;
    final rating =
        performanceData?.averageRating ??
        profileData?.deliveryBoy.rating ??
        4.8;

    return IntrinsicHeight(
      child: Row(
        spacing: 10.w,
        children: [
          Expanded(
            child: _buildMetricCard(
              icon: Icons.inventory_2_outlined,
              value: deliveredCount,
              label: context.tr('delivered'),
              onTap: () => context.push(AppRoutes.myOrders, extra: 'completed'),
            ),
          ),
          Expanded(
            child: BlocBuilder<AvailableOrdersBloc, AvailableOrdersState>(
              builder: (context, availableOrdersState) {
                final newOrdersCount = availableOrdersState.totalOrders;
                return _buildMetricCard(
                  icon: Icons.shopping_bag_outlined,
                  value: newOrdersCount,
                  label: context.tr('availableOrders'),
                  onTap: () => context.go(AppRoutes.feed),
                );
              },
            ),
          ),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.star_outline_rounded,
              value: rating.toStringAsFixed(1),
              label: context.tr('averageRating'),
              onTap: () => context.push(AppRoutes.ratings),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required dynamic value,
    required String label,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return PhysicalScaleFeedback(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 20.sp),
            ),
            SizedBox(height: 12.h),
            // Value
            if (value is Widget)
              value
            else
              CustomText(
                text: value.toString(),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            SizedBox(height: 4.h),
            // Label
            CustomText(text: label, fontSize: 11, textAlign: TextAlign.center),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  // Helper method to find data by key
  T? _findDataByKey<T>(
    List<HomeStatsData> data,
    String key,
    T Function(HomeStatsData) extractor,
  ) {
    try {
      final found = data.where((item) => item.key == key).firstOrNull;
      return found != null ? extractor(found) : null;
    } catch (e) {
      return null;
    }
  }

  Widget _buildEarningsChart(AnalyticsCharts charts) {
    List<ChartPoint> rawData = [];
    List<BarChartGroupData> barGroupsData = [];
    List<String> labels = [];

    try {
      final currentPeriod = _selectedChartPeriod;

      if (currentPeriod == context.tr('week')) {
        rawData = charts.weekly.data;
      } else if (currentPeriod == context.tr('month')) {
        rawData = charts.monthly.data;
      } else if (currentPeriod == context.tr('year')) {
        rawData = charts.yearly.data;
      } else {
        rawData = charts.weekly.data;
      }

      // Calculate max Y value first for better scaling
      double tempMaxY = 0.0;
      for (final item in rawData) {
        if (item.earnings > tempMaxY) {
          tempMaxY = item.earnings;
        }
      }
      double maxY = tempMaxY * 1.2; // Add 20% padding
      if (maxY < 5000) maxY = 5000; // Minimum scale

      for (int i = 0; i < rawData.length; i++) {
        final item = rawData[i];
        double earnings = item.earnings;
        barGroupsData.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: earnings,
                color: AppColors.primaryColor,
                width: sz(28, seprateTabletSize: 48).w, // Wide capsule bars
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ), // Round top borders and flat bottom to touch the bottom axis
              ),
            ],
          ),
        );
        labels.add(item.label);
      }
    } catch (e) {
      return SizedBox(
        height: 300.h,
        child: Center(
          child: CustomText(
            text: context.tr('errorLoadingChartData'),
            color: Colors.grey,
          ),
        ),
      );
    }

    // Calculate max Y value for better scaling
    double maxY =
        barGroupsData.isEmpty
            ? 5000
            : barGroupsData
                .map((e) => e.barRods.first.toY)
                .reduce((a, b) => a > b ? a : b);
    maxY = (maxY * 1.2); // Add 20% padding
    if (maxY < 5000) maxY = 5000; // Minimum scale

    final settingsData = context.read<SystemSettingsBloc>();
    final isTabletDevice = isTablet();
    final yAxisWidth = isTabletDevice ? 70.w : 40.w;

    // Calculate dynamic scroll width for the chart
    final barGroupWidth = isTabletDevice ? 80.w : 48.w;
    final double screenWidth =
        MediaQuery.of(context).size.width - 48.w - yAxisWidth;
    double chartWidth = rawData.length * barGroupWidth;
    if (chartWidth < screenWidth) {
      chartWidth = screenWidth;
    }

    return CustomCard(
      padding: EdgeInsets.zero,
      height: 300.h,
      child: Column(
        spacing: 16,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: context.tr('earnings'),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 15.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: SizedBox(
                      height: 28.h,
                      child: DropdownButton<String>(
                        value: _selectedChartPeriod,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primaryColor,
                          size: 18.sp,
                        ),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedChartPeriod = newValue;
                            });
                          }
                        },
                        selectedItemBuilder: (BuildContext context) {
                          return [
                            context.tr('week'),
                            context.tr('month'),
                            context.tr('year'),
                          ].map<Widget>((String value) {
                            return Center(
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        items:
                            [
                              context.tr('week'),
                              context.tr('month'),
                              context.tr('year'),
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: CustomText(
                                  text: value,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Left: Static Y-Axis
                  SizedBox(
                    width: yAxisWidth,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: maxY,
                        barGroups: const [],
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: maxY / 5,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (value == 0) return const Text('');
                                String text;
                                if (maxY >= 10000) {
                                  text =
                                      '${settingsData.currencySymbol}${(value / 1000).toStringAsFixed(0)}K';
                                } else {
                                  text =
                                      '${settingsData.currencySymbol}${value.toStringAsFixed(0)}';
                                }
                                return CustomText(
                                  text: text,
                                  fontSize: sz(10, seprateTabletSize: 7),
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                );
                              },
                              reservedSize: yAxisWidth,
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              getTitlesWidget: _emptyTitleWidget,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Right: Scrollable chart
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: chartWidth,
                        child: BarChart(
                          key: ValueKey(
                            'home_bar_chart_${_selectedChartPeriod}_${barGroupsData.length}',
                          ),
                          BarChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxY / 5,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.06),
                                  strokeWidth: 1,
                                  dashArray: [4, 4],
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 25,
                                  interval: 1,
                                  getTitlesWidget: (
                                    double value,
                                    TitleMeta meta,
                                  ) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < labels.length) {
                                      return Padding(
                                        padding: EdgeInsets.only(top: 8.h),
                                        child: CustomText(
                                          text: labels[index],
                                          fontSize: sz(
                                            10,
                                            seprateTabletSize: 8,
                                          ),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minY: 0,
                            maxY: maxY,
                            barGroups: barGroupsData,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor:
                                    (touchedSpot) =>
                                        Theme.of(context).colorScheme.surface,
                                tooltipBorderRadius: BorderRadius.circular(8.r),
                                tooltipPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                tooltipBorder: BorderSide(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  width: 1,
                                ),
                                fitInsideVertically: true,
                                fitInsideHorizontally: true,
                                getTooltipItem: (
                                  group,
                                  groupIndex,
                                  rod,
                                  rodIndex,
                                ) {
                                  final index = group.x;
                                  final label =
                                      index < labels.length
                                          ? labels[index]
                                          : '';
                                  return BarTooltipItem(
                                    '$label\n${settingsData.currencySymbol}${rod.toY.toStringAsFixed(0)}',
                                    TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _emptyTitleWidget(double value, TitleMeta meta) {
    return const SizedBox.shrink();
  }
}

class PhysicalScaleFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PhysicalScaleFeedback({super.key, required this.child, this.onTap});

  @override
  State<PhysicalScaleFeedback> createState() => _PhysicalScaleFeedbackState();
}

class _PhysicalScaleFeedbackState extends State<PhysicalScaleFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
