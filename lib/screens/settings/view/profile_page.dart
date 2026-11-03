import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/settings_list_tile.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/media_picker_bottom_sheet.dart';
import 'package:hyper_local/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import '../../../config/helper.dart';
import '../bloc/profile_bloc/profile_bloc.dart';
import '../bloc/profile_bloc/profile_event.dart';
import '../bloc/profile_bloc/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBar(
        title: context.tr('profile'),
        showRefreshButton: true,
        onRefreshPressed: () {
          context.read<ProfileBloc>().add(const LoadProfile());
        },
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, profileState) {
          if (profileState.profile != null) {
            final profile = profileState.profile!;
            final profilePictureUrl = profile.user?.profileImage;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
                    builder: (context, statusState) {
                      final isOnline = statusState.isOnline;
                      return CustomCard(
                        padding: EdgeInsets.all(10.w),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final file = await MediaPickerBottomSheet.show(
                                  context,
                                  allowFile: false,
                                );
                                if (file != null && context.mounted) {
                                  context.read<ProfileBloc>().add(
                                    UpdateProfile(profileImageFile: file.path),
                                  );
                                }
                              },
                              child: Stack(
                                children: [
                                  CustomAvatar(
                                    imageUrl: profilePictureUrl ?? "",
                                    radius: 35.r,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(4.w),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 14.r,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text:
                                        profile.deliveryBoy?.fullName ??
                                        profile.user?.name ??
                                        context.tr('deliveryPartner'),
                                    fontSize: sz(16, seprateTabletSize: 12),
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  SizedBox(height: 8.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          profile.deliveryBoy != null
                                              ? (isOnline
                                                      ? Colors.green
                                                      : Colors.orange)
                                                  .withValues(
                                                    alpha:
                                                        context.isDarkMode
                                                            ? 0.3
                                                            : 0.15,
                                                  )
                                              : Colors.grey.withValues(
                                                alpha:
                                                    context.isDarkMode
                                                        ? 0.3
                                                        : 0.15,
                                              ),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: CustomText(
                                      text:
                                          isOnline
                                              ? context.tr('active')
                                              : context.tr('inactive'),
                                      fontSize: sz(10, seprateTabletSize: 6),
                                      fontWeight: FontWeight.w600,
                                      color:
                                          profile.deliveryBoy != null
                                              ? (isOnline
                                                  ? (context.isDarkMode
                                                      ? Colors.green[300]
                                                      : Colors.green[700])
                                                  : (context.isDarkMode
                                                      ? Colors.orange[300]
                                                      : Colors.orange[700]))
                                              : (context.isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24.h),

                  // Profile Options
                  CustomCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SettingsListTile(
                          icon: Icons.person_outline,
                          title:
                              context.tr('personalInformation'),
                          onTap: () => context.push(AppRoutes.personalInfo),
                          showDivider: true,
                        ),
                        SettingsListTile(
                          icon: Icons.directions_car_outlined,
                          title:
                              context.tr('vehicleInformation'),
                          onTap: () => context.push(AppRoutes.vehicleInfo),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (profileState.fetchStatus == ApiStatus.failed) {
            return ErrorStateWidget(
              onRetry: () {
                context.read<ProfileBloc>().add(const LoadProfile());
              },
            );
          }

          // Loading state
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomCard(
                  padding: EdgeInsets.all(10.w),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35.r,
                        backgroundColor: Colors.grey[200],
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120.w,
                              height: 16.h,
                              color: Colors.grey[200],
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              width: 80.w,
                              height: 12.h,
                              color: Colors.grey[200],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                CustomCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SettingsListTile(
                        icon: Icons.person_outline,
                        title:
                            context.tr('personalInformation'),
                        onTap: null,
                        showDivider: true,
                      ),
                      SettingsListTile(
                        icon: Icons.phone_outlined,
                        title: context.tr('contactInformation'),
                        onTap: null,
                        showDivider: true,
                      ),
                      SettingsListTile(
                        icon: Icons.directions_car_outlined,
                        title: context.tr('vehicleInformation'),
                        onTap: null,
                        showDivider: true,
                      ),
                      SettingsListTile(
                        icon: Icons.verified_user_outlined,
                        title: context.tr('verificationStatus'),
                        onTap: null,
                        showDivider: true,
                      ),
                      SettingsListTile(
                        icon: Icons.document_scanner_outlined,
                        title: context.tr('documents'),
                        onTap: null,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
