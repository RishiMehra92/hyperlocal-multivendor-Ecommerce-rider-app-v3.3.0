import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/dashboard/bloc/notification/notification_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/colors.dart';
import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_image_container.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/toast_message.dart';
import '../../../settings/bloc/profile_bloc/profile_bloc.dart';
import '../../../settings/bloc/profile_bloc/profile_state.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';

import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/config/app_images.dart';

class HomeHeaderSection extends StatefulWidget {
  final Function() handleToggle;

  const HomeHeaderSection({super.key, required this.handleToggle});

  @override
  State<HomeHeaderSection> createState() => _HomeHeaderSectionState();
}

class _HomeHeaderSectionState extends State<HomeHeaderSection> {
  void _showDeliveryZoneErrorDialog(BuildContext context, String errorMessage) {
    final statusBloc = context.read<DeliveryBoyStatusBloc>();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.red),
              SizedBox(width: 8.w),
              CustomText(text: dialogContext.tr('locationIssue')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(text: errorMessage),
              SizedBox(height: 16.h),
              CustomText(text: dialogContext.tr('toResolveThisIssue'), fontWeight: FontWeight.bold),
              SizedBox(height: 8.h),
              CustomText(text: dialogContext.tr('moveToCoveredDeliveryArea')),
              CustomText(text: dialogContext.tr('checkDeliveryZoneInProfile')),
              CustomText(text: dialogContext.tr('ensureGpsEnabledAccurate')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: CustomText(text: dialogContext.tr('ok')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Navigate to delivery zone page
                context.push('/delivery-zone');
              },
              child: CustomText(text: dialogContext.tr('viewDeliveryZone')),
            ),
            CustomButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Retry getting location
                statusBloc.add(const ToggleStatus(true));
              },
              text: dialogContext.tr('retry'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // context.read<NotificationBloc>().add(FetchNotifications());
    // context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
      listener: (context, state) {
        if (state.status == ApiStatus.success) {
          if (state.message.isNotEmpty && state.isVerified) {
            ToastManager.show(context: context, message: state.message, type: ToastType.success);
          }
        } else if (state.status == ApiStatus.failed) {
          // Show toast for general errors
          ToastManager.show(context: context, message: state.message, type: ToastType.error);

          // Show detailed dialog for delivery zone errors
          if (state.message.contains('delivery zone')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showDeliveryZoneErrorDialog(context, state.message);
            });
          }
        }
      },
      child: BlocBuilder<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
        builder: (context, state) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(100.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          text:
                              state.isOnline
                                  ? context.tr('active')
                                  : context.tr('inactive'),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(width: 6.w),
                        state.status == ApiStatus.loading
                            ? SizedBox(width: 30.w, height: 30.w, child: const CupertinoActivityIndicator())
                            : Transform.scale(
                              scale: 0.8,
                              child: CupertinoSwitch(
                                value: state.isOnline,
                                activeTrackColor: AppColors.primaryColor,
                                onChanged: (newValue) {
                                  widget.handleToggle();
                                },
                              ),
                            ),
                      ],
                    ),
                  ),
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, profileState) {
                      final zoneName = profileState.profile?.deliveryBoy?.deliveryZone?.name;
                      if (zoneName == null || zoneName.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: EdgeInsets.only(top: 6.h, left: 4.w),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 140.w),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, color: Colors.white, size: sz(12, seprateTabletSize: 9).sp),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: CustomText(
                                    text: zoneName,
                                    fontSize: sz(11, seprateTabletSize: 9),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              Expanded(
                child: Row(
                  spacing: isTablet() ? 15 : 5,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    BlocBuilder<NotificationBloc, NotificationState>(
                      builder: (context, notificationState) {
                        int unreadCount = 0;

                        if (notificationState.fetchStatus == ApiStatus.success) {
                          unreadCount = notificationState.unreadCount;
                        }
                        return GestureDetector(
                          onTap: () {
                            context.push(AppRoutes.notifications);
                          },
                          child: Badge.count(
                            count: unreadCount,
                            isLabelVisible: unreadCount > 0, // hide badge when 0
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),

                            offset: const Offset(-1, -5), // fine-tune position

                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                              ),
                              padding: isTablet() ? const EdgeInsets.all(11) : const EdgeInsets.all(8),

                              child: Icon(
                                Icons.notifications,
                                size: (isTablet() ? 12 : 20).sp,
                                color: AppColors.primaryColor,
                              ),
                            ),

                            // IconButton(
                            //   padding: isTablet() ? const EdgeInsets.all(11) : null,
                            //   color: AppColors.primaryColor,
                            //   style: IconButton.styleFrom(backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1)),
                            //   icon: Icon(Ionicons.notifications, size: (isTablet() ? 12 : 20).sp),
                            //   onPressed: () {},
                            // ),
                          ),
                        );
                      },
                    ),
                    BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, profileState) {
                        String profileImageUrl = AppImages.profile;

                        if (profileState.profile?.user?.profileImage != null &&
                            profileState.profile!.user!.profileImage!.isNotEmpty) {
                          profileImageUrl = profileState.profile!.user!.profileImage!;
                        }

                        return GestureDetector(
                          onTap: () {
                            if (!state.isVerified) {
                              ToastManager.show(context: context, message: state.message, type: ToastType.error);
                              return;
                            }
                            context.push(AppRoutes.profile);
                          },
                          child: Opacity(
                            opacity: state.isVerified ? 1.0 : 0.5,
                            child: CustomAvatar(
                              radius: (isTablet() ? 16 : 18).r,
                              backgroundColor: AppColors.primaryColor,
                              imageUrl: profileImageUrl.startsWith('http') ? profileImageUrl : null,
                              fallbackIcon: Icon(Icons.person, size: (isTablet() ? 12 : 20).sp, color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
