import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/extensions.dart';
import '../../config/colors.dart';
import '../../config/helper.dart';
import 'custom_text.dart';

class SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final bool isDestructive;
  final bool showDivider;
  final bool isVisible;

  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.onLongPress,
    this.switchValue,
    this.onSwitchChanged,
    this.isDestructive = false,
    this.showDivider = true,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final isDarkTheme = context.isDarkMode;
    final hasSwitch = switchValue != null && onSwitchChanged != null;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: hasSwitch ? null : onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: hasSwitch ? 10.h : 15.h,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color:
                        isDestructive
                            ? Colors.red
                            : (isDarkTheme ? Colors.white70 : Colors.black54),
                    size: (isTablet(context: context) ? 12 : 22).sp,
                  ),
                  SizedBox(width: (isTablet(context: context) ? 10 : 16).w),
                  Expanded(
                    child: CustomText(
                      text: title,
                      fontWeight: FontWeight.w600,
                      color:
                          isDestructive
                              ? Colors.red
                              : (isDarkTheme ? Colors.white : Colors.black),
                    ),
                  ),
                  if (hasSwitch)
                    CupertinoSwitch(
                      value: switchValue!,
                      onChanged: onSwitchChanged,
                      activeTrackColor: AppColors.primaryColor,
                      inactiveTrackColor:
                          isDarkTheme
                              ? Colors.grey.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.4),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: isDarkTheme ? Colors.white54 : Colors.grey,
                      size: (isTablet(context: context) ? 12 : 20).sp,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            color:
                isDarkTheme
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.15),
            height: 1.h,
            indent: 52.w,
          ),
      ],
    );
  }
}
