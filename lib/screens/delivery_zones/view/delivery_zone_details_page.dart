import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:latlong2/latlong.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import '../../../utils/widgets/loading_widget.dart';
import '../../../config/constant.dart';
import '../../../config/helper.dart';
import '../../system_settings/bloc/system_settings_bloc.dart';
import '../bloc/delivery_zone_bloc.dart';
import '../bloc/delivery_zone_event.dart';
import '../bloc/delivery_zone_state.dart';
import '../model/delivery_zone_model.dart';

class DeliveryZoneDetailsPage extends StatefulWidget {
  final int zoneId;
  final DeliveryZoneModel? zone;

  const DeliveryZoneDetailsPage({super.key, required this.zoneId, this.zone});

  @override
  State<DeliveryZoneDetailsPage> createState() =>
      _DeliveryZoneDetailsPageState();
}

class _DeliveryZoneDetailsPageState extends State<DeliveryZoneDetailsPage> {
  final MapController _mapController = MapController();
  @override
  void initState() {
    super.initState();
    // If zone is not provided, fetch it
    if (widget.zone == null) {
      context.read<DeliveryZoneBloc>().add(
        SelectDeliveryZoneEvent(widget.zoneId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;
    String currencySymbol = context.read<SystemSettingsBloc>().currencySymbol;
    return CustomScaffold(
      appBar: CustomAppBar(title: context.tr('zoneDetails')),
      // appBar: AppBar(
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back, color: AppColors.textColor),
      //     onPressed: () => context.pop(),
      //   ),
      //   title: CustomText(text: context.tr('zoneDetails'), fontSize: 20, fontWeight: FontWeight.w600),
      //   centerTitle: true,
      // ),
      body:
          widget.zone != null
              ? _buildContent(widget.zone!, isDark, currencySymbol)
              : BlocBuilder<DeliveryZoneBloc, DeliveryZoneState>(
                builder: (context, state) {
                  if (state.status == ApiStatus.loading) {
                    return const Center(child: LoadingWidget());
                  } else if (state.status == ApiStatus.success &&
                      state.selectedZone != null) {
                    return _buildContent(
                      state.selectedZone!,
                      isDark,
                      currencySymbol,
                    );
                  } else if (state.status == ApiStatus.failed) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64.sp,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16.h),
                          CustomText(
                            text: state.message,
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
    );
  }

  Widget _buildContent(
    DeliveryZoneModel zone,
    bool isDark,
    String currencySymbol,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone Name
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.primaryColor,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),

                CustomText(
                  text: zone.name,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),

          // Map Section
          Container(
            height: 300.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: _buildMap(zone),
            ),
          ),

          SizedBox(height: 24.h),

          // Zone Information Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryColor,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    CustomText(
                      text: context.tr('zoneInformation'),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Regular Time Per KM
                _buildInfoTile(
                  isDark,
                  label: context.tr('regularTimePerKm'),
                  value: '${zone.deliveryTimePerKm} Min',
                ),
                SizedBox(height: 12.h),

                // Buffer Time
                _buildInfoTile(
                  isDark,
                  label: context.tr('bufferTime'),
                  value: '${zone.bufferTime} Min',
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Coverage Details Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primaryColor,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    CustomText(
                      text: context.tr('coverageDetails'),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Delivery Charges
                _buildDetailCard(
                  isDark,
                  title: context.tr('deliveryCharges'),
                  items: [
                    _DetailItem(
                      label: context.tr('regularDelivery'),
                      value: '$currencySymbol${zone.regularDeliveryCharges}',
                    ),
                    if (zone.rushDeliveryEnabled &&
                        zone.rushDeliveryCharges != null)
                      _DetailItem(
                        label: context.tr('rushDelivery'),
                        value: '$currencySymbol${zone.rushDeliveryCharges}',
                      ),
                    if (zone.distanceBasedDeliveryCharges != null)
                      _DetailItem(
                        label: context.tr('distanceBased'),
                        value:
                            '$currencySymbol${zone.distanceBasedDeliveryCharges}',
                      ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Zone Radius
                _buildDetailCard(
                  isDark,
                  title: context.tr('zoneCoverage'),
                  items: [
                    _DetailItem(
                      label: context.tr('radius'),
                      value: '${zone.radiusKm.toStringAsFixed(3)} km',
                    ),
                    if (zone.freeDeliveryAmount != null)
                      _DetailItem(
                        label: context.tr('freeDeliveryAbove'),
                        value: '$currencySymbol${zone.freeDeliveryAmount}',
                      ),
                  ],
                ),

                if (zone.perStoreDropOffFee != null ||
                    zone.handlingCharges != null) ...[
                  SizedBox(height: 12.h),
                  _buildDetailCard(
                    isDark,
                    title: context.tr('additionalFees'),
                    items: [
                      if (zone.perStoreDropOffFee != null)
                        _DetailItem(
                          label:
                              context.tr('perStoreDropOffFee'),
                          value: '$currencySymbol${zone.perStoreDropOffFee}',
                        ),
                      if (zone.handlingCharges != null)
                        _DetailItem(
                          label: context.tr('handlingCharges'),
                          value: '$currencySymbol${zone.handlingCharges}',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildMap(DeliveryZoneModel zone) {
    // Parse center coordinates
    double centerLat = double.tryParse(zone.centerLatitude) ?? 23.2488453;
    double centerLng = double.tryParse(zone.centerLongitude) ?? 69.6696795;

    // Check for NaN or Infinity
    if (centerLat.isNaN || centerLat.isInfinite) centerLat = 23.2488453;
    if (centerLng.isNaN || centerLng.isInfinite) centerLng = 69.6696795;

    final center = LatLng(centerLat, centerLng);

    // Convert boundary points to LatLng with validation
    final List<LatLng> boundaryPoints =
        zone.boundaryJson
            .map((point) => LatLng(point.lat, point.lng))
            .where(
              (point) =>
                  !point.latitude.isNaN &&
                  !point.latitude.isInfinite &&
                  !point.longitude.isNaN &&
                  !point.longitude.isInfinite,
            )
            .toList();

    // Close the polygon by adding the first point at the end
    if (boundaryPoints.isNotEmpty) {
      boundaryPoints.add(boundaryPoints.first);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: AppConstant.packageName,
        ),
        // Polygon with dotted border
        if (boundaryPoints.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: boundaryPoints,
                color: AppColors.primaryColor.withValues(alpha: 0.2),
                borderStrokeWidth: 2.0,
                borderColor: AppColors.primaryColor,
                pattern:
                    const StrokePattern.dotted(), // This makes the border dotted
              ),
            ],
          ),
        // Center marker
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 40.w,
              height: 40.h,
              child: Icon(
                Icons.location_pin,
                color: AppColors.primaryColor,
                size: 40.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    bool isDark, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.black38 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(text: label, color: Colors.grey.shade700),
          CustomText(text: value, fontSize: 16, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    bool isDark, {
    required String title,
    required List<_DetailItem> items,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.black38 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(text: title, fontSize: 15, fontWeight: FontWeight.w600),
          SizedBox(height: 12.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: item.label,
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  CustomText(
                    text: item.value,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;

  _DetailItem({required this.label, required this.value});
}
