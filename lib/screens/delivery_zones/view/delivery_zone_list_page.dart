import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_state.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import '../../../utils/widgets/loading_widget.dart';
import '../bloc/delivery_zone_bloc.dart';
import '../bloc/delivery_zone_event.dart';
import '../bloc/delivery_zone_state.dart';
import '../model/delivery_zone_model.dart';

class DeliveryZoneListPage extends StatefulWidget {
  final bool isSelectionMode;
  final bool isFromAuth;

  const DeliveryZoneListPage({
    super.key, 
    this.isSelectionMode = false,
    this.isFromAuth = false,
  });

  @override
  State<DeliveryZoneListPage> createState() => _DeliveryZoneListPageState();
}

class _DeliveryZoneListPageState extends State<DeliveryZoneListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch delivery zones on init
    context.read<DeliveryZoneBloc>().add(const FetchDeliveryZonesEvent());

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (isBottom(_scrollController)) {
      final state = context.read<DeliveryZoneBloc>().state;
      if (state.status == ApiStatus.success && state.hasMore) {
        context.read<DeliveryZoneBloc>().add(
          const LoadMoreDeliveryZonesEvent(),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    context.read<DeliveryZoneBloc>().add(SearchDeliveryZonesEvent(query));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;
    return BlocBuilder<SystemSettingsBloc, SystemSettingsState>(
      builder: (context, state) {
        final currencySymbol =
            context.read<SystemSettingsBloc>().currencySymbol;
        return CustomScaffold(
          appBar: CustomAppBar(
            title:
                widget.isSelectionMode
                    ? 'Select Delivery Zone'
                    : 'Zone Details',
          ),
          // appBar: AppBar(
          //   backgroundColor: Theme.of(context).colorScheme.surface,
          //   elevation: 0,
          //   leading: IconButton(
          //     icon: const Icon(Icons.arrow_back, color: AppColors.textColor),
          //     onPressed: () => context.pop(),
          //   ),
          //   title: CustomText(
          //     text: widget.isSelectionMode ? 'Select Delivery Zone' : 'Zone Details',
          //     fontWeight: FontWeight.w600,
          //   ),
          //   centerTitle: true,
          // ),
          body: Column(
            children: [
              // Selection mode hint
              if (widget.isSelectionMode)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18.sp,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: CustomText(
                          text:
                              context.tr('tapOnAZoneToSelectItForYourAccount'),
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

              // Search and Filter Section
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: context.tr('search'),
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15.sp,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade500,
                              size: 22.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Zones List
              Expanded(
                child: BlocBuilder<DeliveryZoneBloc, DeliveryZoneState>(
                  builder: (context, state) {
                    if (state.status == ApiStatus.loading) {
                      return const Center(child: LoadingWidget());
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
                    } else if (state.status == ApiStatus.success) {
                      if (state.zones.isEmpty) {
                        return Center(
                          child: CustomText(
                            text: context.tr('noZonesFound'),
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount:
                            state.zones.length + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.zones.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: LoadingWidget()),
                            );
                          }
                          return _buildZoneCard(
                            state.zones[index],
                            currencySymbol,
                            isDark,
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZoneCard(
    DeliveryZoneModel zone,
    String currencySymbol,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        if (widget.isSelectionMode) {
          // Return zone data for selection
          context.pop({
            'id': zone.id,
            'name': zone.name,
            'slug': zone.slug,
            'centerLatitude': zone.centerLatitude,
            'centerLongitude': zone.centerLongitude,
            'radiusKm': zone.radiusKm,
          });
        } else {
          // Navigate to zone details
          context.push(
            '${widget.isFromAuth ? AppRoutes.authDeliveryZoneDetails : AppRoutes.deliveryZoneDetails}/${zone.id}',
            extra: zone,
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.black38 : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
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
            // Zone Name and Status
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.primaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: CustomText(
                    text: zone.name,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!widget.isSelectionMode)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          zone.status == 'active'
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: CustomText(
                      text: zone.status == 'active' ? 'Active' : 'Inactive',
                      fontSize: 12,
                      color:
                          zone.status == 'active' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: AppColors.primaryColor,
                  ),
              ],
            ),
            SizedBox(height: 16.h),

            // Delivery Fees
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    isDark,
                    icon: Icons.local_shipping_outlined,
                    label: 'Delivery Fee',
                    value: '$currencySymbol${zone.regularDeliveryCharges}',
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildInfoCard(
                    isDark,
                    icon: Icons.local_shipping_outlined,
                    label: 'Rush Delivery Fee',
                    value: '$currencySymbol${zone.rushDeliveryCharges}',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Free Delivery Above
            _buildInfoRow(
              isDark,
              icon: Icons.local_shipping_outlined,
              label: 'Free Delivery Above',
              value: '$currencySymbol${zone.radiusKm.toStringAsFixed(3)} km',
            ),

            // View Details button for selection mode
            if (widget.isSelectionMode) ...[
              SizedBox(height: 12.h),
              GestureDetector(
                onTap: () {
                  context.push(
                    '${widget.isFromAuth ? AppRoutes.authDeliveryZoneDetails : AppRoutes.deliveryZoneDetails}/${zone.id}',
                    extra: zone,
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 16.sp,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 6.w),
                      CustomText(
                        text: context.tr('viewDetails'),
                        fontSize: 13,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.black38 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: Colors.grey.shade600),
              SizedBox(width: 4.w),
              Expanded(
                child: CustomText(
                  text: label,
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          CustomText(text: value, fontSize: 16, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.black38 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: Colors.grey.shade600),
          SizedBox(width: 8.w),
          Expanded(
            child: CustomText(
              text: label,
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          CustomText(text: value, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }
}
