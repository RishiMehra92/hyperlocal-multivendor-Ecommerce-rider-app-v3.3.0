import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/location_tracker.dart';
import 'package:hyper_local/config/theme/theme_bloc/theme_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/router/app_routes.dart';
import '../../../../utils/widgets/custom_card.dart';
import '../../../config/colors.dart';
import '../../../config/theme/theme_bloc/theme_event.dart';
import '../../../utils/widgets/custom_image_container.dart';
import '../../system_settings/bloc/system_settings_state.dart';
import '../bloc/profile_bloc/profile_bloc.dart';
import '../bloc/profile_bloc/profile_event.dart';
import '../bloc/profile_bloc/profile_state.dart';
import 'package:hyper_local/bloc/language_bloc/language_bloc.dart';
import '../../../utils/widgets/toast_message.dart';
import 'package:hyper_local/utils/widgets/settings_list_tile.dart';
import 'package:hyper_local/utils/widgets/custom_bottom_sheet.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  @override
  void initState() {
    super.initState();
    // Load profile data
    try {
      context.read<ProfileBloc>().add(const LoadProfile());
    } catch (e) {
      //
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = context.isDarkMode;
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) async {
            final router = GoRouter.of(context);
            if (state.deleteApiStatus == ApiStatus.loading) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (_) => const Center(child: CircularProgressIndicator()),
              );
            }

            if (state.deleteApiStatus == ApiStatus.success) {
              Navigator.of(context, rootNavigator: true).pop();
              ToastManager.show(
                context: context,
                message:
                    state.message.isNotEmpty
                        ? state.message
                        : "Account Deleted Successfully",
                type: ToastType.success,
              );
              LocationTracker().stopTracking();
              await Global.setDeliveryBoyStatus(false);
              await Global.clearDeliveryBoyStatus();
              await Global.clearUserToken();
              await Global.clearIdToken();
              router.go(AppRoutes.login);
            } else if (state.deleteApiStatus == ApiStatus.failed) {
              Navigator.of(context, rootNavigator: true).pop();
              ToastManager.show(
                context: context,
                message:
                    state.message.isNotEmpty ? state.message : "Delete failed",
                type: ToastType.error,
              );
            }
          },
        ),
      ],
      child: CustomScaffold(
        wantSafeArea: false,
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final profile = state.profile;
            final String profileName =
                (profile != null)
                    ? (profile.deliveryBoy?.fullName ??
                        profile.user?.name ??
                        context.tr('deliveryPartner'))
                    : context.tr('deliveryPartner');
            final String? profileImageUrl =
                (profile != null) ? profile.user?.profileImage : null;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blue Header & Overlapping Avatar Stack
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 160.h,
                        width: double.infinity,
                        color: AppColors.primaryColor,
                      ),
                      Positioned(
                        bottom: -45.r,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDarkTheme
                                      ? AppColors.darkBackgroundColor
                                      : Colors.white,
                              width: 4.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10.r,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CustomAvatar(
                            imageUrl: profileImageUrl ?? "",
                            radius: 50.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 55.h),
                  // User Name
                  Center(
                    child: CustomText(
                      text: profileName,
                      fontSize: sz(20, seprateTabletSize: 15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5.h),

                  // Section cards padded
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Details Section
                        _buildSectionCard(
                          context: context,
                          title: context.tr('accountDetails'),
                          children: [
                            SettingsListTile(
                              icon: Icons.account_circle_outlined,
                              title: context.tr('profileInfo'),
                              onTap: () => context.push(AppRoutes.profile),
                              showDivider: true,
                            ),
                            // SettingsListTile(
                            //   icon: Icons.description_outlined,
                            //   title:
                            //       context.tr('documents'),
                            //   onTap:
                            //       () => context.push(AppRoutes.documents),
                            //   showDivider: true,
                            // ),
                            SettingsListTile(
                              icon: Icons.alarm_on_outlined,
                              title:
                                  context.tr('cashCollected'),
                              onTap:
                                  () =>
                                      context.push(AppRoutes.allCashCollection),
                              showDivider: true,
                            ),
                            SettingsListTile(
                              icon: Icons.history_toggle_off_outlined,
                              title:
                                  context.tr('withdrawalHistory'),
                              onTap:
                                  () =>
                                      context.push(AppRoutes.withdrawalHistory),
                              showDivider: false,
                            ),
                          ],
                        ),

                        // App Settings Section
                        _buildSectionCard(
                          context: context,
                          title: context.tr('appSettings'),
                          children: [
                            SettingsListTile(
                              icon: Icons.g_translate_outlined,
                              title: context.tr('language'),
                              onTap:
                                  () => _showLanguageSelectionBottomSheet(
                                    context,
                                    isDarkTheme,
                                  ),
                              onLongPress: () async {
                                HapticFeedback.heavyImpact();
                                final isEnabled =
                                    await Global.toggleHttpInspector();
                                if (context.mounted) {
                                  ToastManager.show(
                                    context: context,
                                    message:
                                        isEnabled
                                            ? "Secret HTTP Inspector Enabled"
                                            : "Secret HTTP Inspector Disabled",
                                    type:
                                        isEnabled
                                            ? ToastType.success
                                            : ToastType.error,
                                  );
                                }
                              },
                              showDivider: true,
                            ),
                            SettingsListTile(
                              icon: Icons.dark_mode_outlined,
                              title: context.tr('darkTheme'),
                              switchValue: isDarkTheme,
                              onSwitchChanged: (value) {
                                context.read<ThemeBloc>().add(
                                  SetTheme(value ? 'dark' : 'light'),
                                );
                              },
                              showDivider: false,
                            ),
                          ],
                        ),

                        // Activity Section
                        _buildSectionCard(
                          context: context,
                          title: context.tr('activity'),
                          children: [
                            SettingsListTile(
                              icon: Icons.shopping_bag_outlined,
                              title: context.tr('myOrders'),
                              onTap: () => context.push(AppRoutes.myOrders),
                              showDivider: true,
                            ),
                            // SettingsListTile(
                            //   icon: Icons.history_outlined,
                            //   title: context.tr('viewHistory'),
                            //   onTap: () => context.push(AppRoutes.viewHistory),
                            //   showDivider: true,
                            // ),
                            BlocBuilder<
                              SystemSettingsBloc,
                              SystemSettingsState
                            >(
                              builder: (context, settingsState) {
                                final bool isReferVisible =
                                    settingsState.settings?.referStatus ??
                                    false;
                                return Column(
                                  children: [
                                    SettingsListTile(
                                      icon: Icons.star_outline,
                                      title:
                                          context.tr('feedback'),
                                      onTap:
                                          () => context.push(AppRoutes.ratings),
                                      showDivider: isReferVisible,
                                    ),
                                    SettingsListTile(
                                      isVisible: isReferVisible,
                                      icon: TablerIcons.moneybag,
                                      title:
                                          context.tr('referAndEarn'),
                                      onTap:
                                          () => context.push(
                                            AppRoutes.referAndEarn,
                                          ),
                                      showDivider: false,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),

                        // Support & Help Section
                        _buildSectionCard(
                          context: context,
                          title: context.tr('supportAndHelp'),
                          children: [
                            SettingsListTile(
                              icon: Icons.support_agent_outlined,
                              title: context.tr('support'),
                              onTap: () => context.push(AppRoutes.support),
                              showDivider: true,
                            ),
                            SettingsListTile(
                              icon: Icons.description_outlined,
                              title:
                                  context.tr('termsOfService'),
                              onTap: () => context.push(AppRoutes.terms),
                              showDivider: true,
                            ),
                            SettingsListTile(
                              icon: Icons.privacy_tip_outlined,
                              title:
                                  context.tr('privacyPolicy'),
                              onTap: () => context.push(AppRoutes.privacy),
                              showDivider: false,
                            ),
                          ],
                        ),

                        // Account Actions Section
                        _buildSectionCard(
                          context: context,
                          title: context.tr('accountActions'),
                          children: [
                            SettingsListTile(
                              icon: Icons.logout_outlined,
                              title: context.tr('logout'),
                              onTap:
                                  () => _showLogoutDialog(context, isDarkTheme),
                              isDestructive: true,
                              showDivider: true,
                            ),
                            SettingsListTile(
                              icon: Icons.no_accounts_outlined,
                              title:
                                  context.tr('deleteAccount'),
                              onTap:
                                  () => _showDeleteDialog(context, isDarkTheme),
                              isDestructive: true,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required BuildContext context,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
            child: CustomText(
              text: title,
              fontWeight: FontWeight.w600,
              fontSize: sz(13, seprateTabletSize: 9),
              color: context.isDarkMode ? null : AppColors.titleBlack,
            ),
          ),
          CustomCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDarkTheme) {
    final router = GoRouter.of(context); // ← capture here, safe

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
          title: CustomText(
            text: context.tr('logout'),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          content: CustomText(
            text: context.tr('areYouSureLogout'),
            fontSize: 16,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: CustomText(
                text: context.tr('cancel'),
                fontSize: 16,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                LocationTracker().stopTracking();
                await Global.setDeliveryBoyStatus(false);
                await Global.clearDeliveryBoyStatus();
                await Global.clearUserToken();
                await Global.clearIdToken();
                // Navigate to login page
                router.go(AppRoutes.login);
              },
              child: CustomText(
                text: context.tr('logout'),
                fontSize: 16,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, bool isDarkTheme) {
    final profileBloc = context.read<ProfileBloc>();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
          title: CustomText(
            text: context.tr('deleteAccount'),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          content: CustomText(
            text: context.tr('deleteAccountDesc'),
            fontSize: 16,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: CustomText(
                text: context.tr('cancel'),
                fontSize: 16,
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                profileBloc.add(const DeleteProfileEvent());
              },
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.errorColor),
              ),
              child: CustomText(
                text: context.tr('delete'),
                color: AppColors.backgroundColor,
              ),
            ),
            // TextButton(
            //   onPressed: () async {
            //     Navigator.of(context).pop();
            //
            //     LocationTracker().stopTracking();
            //     await Global.setDeliveryBoyStatus(false);
            //     await Global.clearDeliveryBoyStatus();
            //     await () {};
            //
            //     await Global.clearUserToken();
            //     await Global.clearIdToken();
            //     // Navigate to login page
            //     if (!context.mounted) return;
            //     GoRouter.of(context).pushReplacement(AppRoutes.login);
            //   },
            //   child: CustomText(text: context.tr('delete'), fontSize: 16),
            // ),
          ],
        );
      },
    );
  }

  void _showLanguageSelectionBottomSheet(
    BuildContext context,
    bool isDarkTheme,
  ) {
    final languageBloc = context.read<LanguageBloc>();
    final languageListBloc = context.read<LanguageListBloc>();

    CustomBottomSheet.show(
      context: context,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: languageBloc),
          BlocProvider.value(value: languageListBloc),
        ],
        child: BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, langState) {
            final currentLanguage = langState is LanguageLoaded
                ? langState.currentLanguage
                : Global.currentLanguage;

            final dynamicLanguages = langState is LanguageLoaded
                ? (langState.languageModel.data?.languages ?? [])
                : [];
            final hasDynamic = dynamicLanguages.isNotEmpty;

            final List<Map<String, String>> availableLanguages = hasDynamic
                ? dynamicLanguages
                    .map<Map<String, String>>((l) => <String, String>{
                          'code': l.code ?? '',
                          'name': (l.nativeName != null && l.nativeName!.isNotEmpty)
                              ? l.nativeName!
                              : (l.name ?? ''),
                          'nameEnglish': l.name ?? '',
                        })
                    .toList()
                : Global.supportedLanguages
                    .map<Map<String, String>>((l) => <String, String>{
                          'code': l['code'] ?? '',
                          'name': l['nativeName'] ?? l['name'] ?? '',
                          'nameEnglish': l['name'] ?? '',
                        })
                    .toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Draggable indicator bar
                SizedBox(height: 12.h),

                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.language_rounded,
                          color: AppColors.primaryColor,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: context.tr('selectLanguage', fallback: 'Select Language'),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(height: 2.h),
                            CustomText(
                              text: context.tr('chooseYourPreferredLanguage', fallback: 'Choose your preferred language'),
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                const Divider(height: 1),

                // Language options list
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: SingleChildScrollView(
                      child: Column(
                        children:
                            availableLanguages.asMap().entries.map((entry) {
                              final index = entry.key;
                              final language = entry.value;
                              final isSelected =
                                  language['code'] == currentLanguage;
                              final isLast =
                                  index == availableLanguages.length - 1;

                              return _buildEnhancedLanguageOption(
                                languageCode: language['code'] as String,
                                languageName: language['name'] as String,
                                languageNameEnglish:
                                    language['nameEnglish'] as String,
                                isSelected: isSelected,
                                isLast: isLast,
                                onTap: () {
                                  final selectedCode = language['code'] as String;
                                  context.read<LanguageBloc>().add(ChangeLanguage(selectedCode));
                                  context.read<LanguageListBloc>().add(FetchLanguageList(locale: selectedCode));
                                  Navigator.of(context).pop();
                                  ToastManager.show(
                                    context: context,
                                    message: context.tr('languageChangedTo', positionalArgs: [language['name']]),
                                    type: ToastType.success,
                                  );
                                },
                                isDarkTheme: isDarkTheme,
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedLanguageOption({
    required String languageCode,
    required String languageName,
    required String languageNameEnglish,
    required bool isSelected,
    required bool isLast,
    required VoidCallback onTap,
    required bool isDarkTheme,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color:
                      isSelected
                          ? AppColors.primaryColor.withValues(alpha: 0.3)
                          : Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Language flag/code container
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryColor,
                                  AppColors.primaryColor.withValues(alpha: 0.8),
                                ],
                              )
                              : LinearGradient(
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                ],
                              ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 12.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ]
                              : [],
                    ),
                    child: Center(
                      child: CustomText(
                        text: languageCode.toUpperCase(),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            isSelected
                                ? Colors.white
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),

                  SizedBox(width: 16.w),

                  // Language names
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: languageName,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected
                                  ? AppColors.primaryColor
                                  : Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(height: 2.h),
                        CustomText(
                          text: languageNameEnglish,
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primaryColor
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primaryColor
                                : Theme.of(context).colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child:
                        isSelected
                            ? Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18.sp,
                            )
                            : null,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Divider (except for last item)
        if (!isLast)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 32.w),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.0),
                  Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.2),
                  Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
