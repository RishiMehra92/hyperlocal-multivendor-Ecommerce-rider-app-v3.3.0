import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/colors.dart';
import '../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../utils/widgets/custom_scaffold.dart';
import '../../../utils/widgets/toast_message.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../system_settings/bloc/system_settings_bloc.dart';
import '../../system_settings/bloc/system_settings_state.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ToastManager.show(
        context: context,
        message: context.tr('unableToOpen'),
        type: ToastType.error,
      );
    }
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ToastManager.show(
      context: context,
      message: message,
      type: ToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return CustomScaffold(
      appBar: CustomAppBar(title: context.tr('support')),
      body: BlocBuilder<SystemSettingsBloc, SystemSettingsState>(
        builder: (context, state) {
          final value = state.settings?.systemSettings?.value;
          final String phoneNumber = value?.sellerSupportNumber ?? '';
          final String email = value?.sellerSupportEmail ?? '';

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Hero Section with beautiful character illustration
                Container(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isDark
                              ? [
                                theme.colorScheme.surface,
                                theme.colorScheme.surface.withValues(
                                  alpha: 0.8,
                                ),
                              ]
                              : [
                                AppColors.primaryColor.withValues(alpha: 0.05),
                                AppColors.primaryColor.withValues(alpha: 0.02),
                              ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                  child: Column(
                    children: [
                      _buildSupportIllustration(context),
                      SizedBox(height: 16.h),
                      CustomText(
                        text: context.tr('weAreHereToHelp'),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      CustomText(
                        text: context.tr('supportSubtitle'),
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        textAlign: TextAlign.center,
                        height: 1.4,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Contact Cards Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: context.tr('contactChannels'),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: 12.h),
                      _buildContactCard(
                        context: context,
                        icon: Icons.phone_in_talk_rounded,
                        title: context.tr('callUs'),
                        subtitle: phoneNumber,
                        description: context.tr('callDescription'),
                        iconColor: Colors.green,
                        onTap:
                            phoneNumber.isEmpty
                                ? null
                                : () => _launchUrl(context, 'tel:$phoneNumber'),
                        onLongPress:
                            phoneNumber.isEmpty
                                ? null
                                : () => _copyToClipboard(
                                  context,
                                  phoneNumber,
                                  context.tr('phoneNumberCopied'),
                                ),
                      ),
                      SizedBox(height: 14.h),
                      _buildContactCard(
                        context: context,
                        icon: Icons.alternate_email_rounded,
                        title: context.tr('emailUs'),
                        subtitle: email,
                        description: context.tr('emailDescription'),
                        iconColor: Colors.blue,
                        onTap:
                            email.isEmpty
                                ? null
                                : () => _launchUrl(
                                  context,
                                  'mailto:$email?subject=Support Request',
                                ),
                        onLongPress:
                            email.isEmpty
                                ? null
                                : () => _copyToClipboard(
                                  context,
                                  email,
                                  context.tr('emailCopied'),
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
    );
  }

  Widget _buildSupportIllustration(BuildContext context) {
    const primaryColor = AppColors.primaryColor;
    return SizedBox(
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing concentric background circles
          Container(
            width: 150,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.05),
            ),
          ),
          Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.08),
            ),
          ),
          // Stylized character avatar representing a support agent
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          // Floating chat bubble (left vector element)
          Positioned(
            top: 15.h,
            left: 100.w,
            child: _buildFloatingElement(
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 14,
              ),
              backgroundColor: primaryColor,
            ),
          ),
          // Floating question mark (right vector element)
          Positioned(
            bottom: 15.h,
            right: 100.w,
            child: _buildFloatingElement(
              child: const Text(
                '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingElement({
    required Widget child,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color iconColor,
    required VoidCallback? onTap,
    required VoidCallback? onLongPress,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Glowing Icon Avatar
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text:
                        subtitle.isNotEmpty
                            ? subtitle
                            : context.tr('notAvailable'),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        subtitle.isNotEmpty
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text: description,
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            // Tap indicator
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
