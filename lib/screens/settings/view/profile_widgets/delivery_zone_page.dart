import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import '../../../../config/colors.dart';
import '../../../../utils/widgets/custom_scaffold.dart';
import '../../bloc/profile_bloc/profile_bloc.dart';
import '../../bloc/profile_bloc/profile_event.dart';
import '../../bloc/profile_bloc/profile_state.dart';
import '../../model/profile_model.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';

class DeliveryZonePage extends StatefulWidget {
  const DeliveryZonePage({super.key});

  @override
  State<DeliveryZonePage> createState() => _DeliveryZonePageState();
}

class _DeliveryZonePageState extends State<DeliveryZonePage> {
  @override
  void initState() {
    super.initState();
    // Load profile data
    context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBar(
        title: context.tr('deliveryZones'),
        showRefreshButton: false,
        showThemeToggle: false,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.fetchStatus == ApiStatus.failed &&
              state.message.isNotEmpty) {
            ToastManager.show(
              context: context,
              message: state.message,
              type: ToastType.error,
            );
          }
        },
        builder: (context, state) {
          if (state.profile != null) {
            return _buildDeliveryZoneContent(state.profile!);
          }

          if (state.fetchStatus == ApiStatus.loading) {
            return const Center(child: LoadingWidget());
          }

          if (state.fetchStatus == ApiStatus.failed) {
            return _buildErrorState(state.message);
          }

          return const Center(child: LoadingWidget());
        },
      ),
    );
  }

  Widget _buildDeliveryZoneContent(ProfileModel profile) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final deliveryZone = profile.deliveryBoy?.deliveryZone;
    final currencySymbol = context.read<SystemSettingsBloc>().currencySymbol;

    if (deliveryZone == null) {
      return _buildNoZoneState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone Header
          _buildZoneHeader(deliveryZone, isDarkTheme),
          SizedBox(height: 24.h),

          // Zone Details
          _buildSectionTitle(context.tr('zoneInformation')),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('zoneName'),
            value: deliveryZone.name ?? 'N/A',
            icon: Icons.location_on_outlined,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('zoneSlug'),
            value: deliveryZone.slug ?? 'N/A',
            icon: Icons.tag_outlined,
            color: Colors.blue,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('radius'),
            value: '${deliveryZone.radiusKm?.toStringAsFixed(2) ?? 'N/A'} km',
            icon: Icons.radar_outlined,
            color: Colors.green,
          ),
          SizedBox(height: 24.h),

          // Delivery Charges
          _buildSectionTitle(context.tr('deliveryCharges')),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('regularDeliveryCharges'),
            value:
                deliveryZone.regularDeliveryCharges != null
                    ? '$currencySymbol${deliveryZone.regularDeliveryCharges}'
                    : 'N/A',
            icon: Icons.local_shipping_outlined,
            color: Colors.orange,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('rushDeliveryCharges'),
            value:
                deliveryZone.rushDeliveryCharges != null
                    ? '$currencySymbol${deliveryZone.rushDeliveryCharges}'
                    : 'N/A',
            icon: Icons.flash_on_outlined,
            color: Colors.red,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('freeDeliveryAmount'),
            value:
                deliveryZone.freeDeliveryAmount != null
                    ? '$currencySymbol${deliveryZone.freeDeliveryAmount!.toStringAsFixed(2)}'
                    : 'N/A',
            icon: Icons.free_breakfast_outlined,
            color: Colors.green,
          ),
          SizedBox(height: 24.h),

          // Delivery Times
          _buildSectionTitle(context.tr('deliveryTimes')),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('regularDeliveryTime'),
            value: '${deliveryZone.deliveryTimePerKm ?? 'N/A'} min/km',
            icon: Icons.access_time_outlined,
            color: Colors.blue,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('rushDeliveryTime'),
            value: '${deliveryZone.rushDeliveryTimePerKm ?? 'N/A'} min/km',
            icon: Icons.speed_outlined,
            color: Colors.red,
          ),
          SizedBox(height: 24.h),

          // Delivery Boy Earnings
          _buildSectionTitle(context.tr('yourEarnings')),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('baseFee'),
            value:
                deliveryZone.deliveryBoyBaseFee != null
                    ? '$currencySymbol${deliveryZone.deliveryBoyBaseFee}'
                    : 'N/A',
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.green,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('perStorePickupFee'),
            value:
                deliveryZone.deliveryBoyPerStorePickupFee != null
                    ? '$currencySymbol${deliveryZone.deliveryBoyPerStorePickupFee}'
                    : 'N/A',
            icon: Icons.store_outlined,
            color: Colors.blue,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('distanceBasedFee'),
            value:
                deliveryZone.deliveryBoyDistanceBasedFee != null
                    ? '$currencySymbol${deliveryZone.deliveryBoyDistanceBasedFee}'
                    : 'N/A',
            icon: Icons.route_outlined,
            color: Colors.orange,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('perOrderIncentive'),
            value:
                deliveryZone.deliveryBoyPerOrderIncentive != null
                    ? '$currencySymbol${deliveryZone.deliveryBoyPerOrderIncentive}'
                    : 'N/A',
            icon: Icons.emoji_events_outlined,
            color: Colors.purple,
          ),
          SizedBox(height: 24.h),

          // Additional Information
          _buildSectionTitle(
            context.tr('additionalInformation'),
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('handlingCharges'),
            value:
                deliveryZone.handlingCharges != null
                    ? '$currencySymbol${deliveryZone.handlingCharges!.toStringAsFixed(2)}'
                    : 'N/A',
            icon: Icons.handyman_outlined,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('perStoreDropOffFee'),
            value:
                deliveryZone.perStoreDropOffFee != null
                    ? '$currencySymbol${deliveryZone.perStoreDropOffFee!.toStringAsFixed(2)}'
                    : 'N/A',
            icon: Icons.delivery_dining_outlined,
            color: Colors.teal,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('bufferTime'),
            value: '${deliveryZone.bufferTime ?? 'N/A'} minutes',
            icon: Icons.timer_outlined,
            color: Colors.indigo,
          ),
          SizedBox(height: 16.h),

          _buildInfoCard(
            title: context.tr('rushDelivery'),
            value:
                deliveryZone.rushDeliveryEnabled == true
                    ? context.tr('enabled')
                    : context.tr('disabled'),
            icon: Icons.flash_on_outlined,
            color:
                deliveryZone.rushDeliveryEnabled == true
                    ? Colors.green
                    : Colors.grey,
          ),
          SizedBox(height: 24.h),

          // Zone Status
          _buildSectionTitle(context.tr('zoneStatus')),
          SizedBox(height: 16.h),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: (deliveryZone.status == 'active'
                      ? Colors.green
                      : Colors.red)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: (deliveryZone.status == 'active'
                        ? Colors.green
                        : Colors.red)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  deliveryZone.status == 'active'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color:
                      deliveryZone.status == 'active'
                          ? Colors.green
                          : Colors.red,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomText(
                    text: context.tr('zoneIs', positionalArgs: [deliveryZone.status ?? 'unknown']),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        deliveryZone.status == 'active'
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  Widget _buildZoneHeader(dynamic deliveryZone, bool isDarkTheme) {
    return CustomCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40.r,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.location_on,
              size: 40.sp,
              color:
                  isDarkTheme
                      ? Theme.of(context).colorScheme.onSurface
                      : AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 16.h),
          CustomText(
            text: deliveryZone.name ?? 'Delivery Zone',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color:
                isDarkTheme
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white,
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: (deliveryZone.status == 'active'
                      ? Colors.green
                      : Colors.red)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: CustomText(
              text: deliveryZone.status?.toUpperCase() ?? 'UNKNOWN',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color:
                  isDarkTheme
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomText(
      text: title,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: value,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoZoneState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 64.sp,
            color: Colors.grey.withValues(alpha: 0.6),
          ),
          SizedBox(height: 16.h),
          CustomText(
            text: context.tr('noDeliveryZoneAssigned'),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          SizedBox(height: 8.h),
          CustomText(
            text:
                context.tr('youHaventBeenAssignedToAnyDeliveryZoneYet'),
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red.withValues(alpha: 0.6),
          ),
          SizedBox(height: 16.h),
          CustomText(
            text: context.tr('errorLoadingProfile'),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: message,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: context.tr('retry'),
            onPressed: () {
              context.read<ProfileBloc>().add(const LoadProfile());
            },
            backgroundColor: AppColors.primaryColor,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
