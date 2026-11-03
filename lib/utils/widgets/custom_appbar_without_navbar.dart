import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/extensions.dart';
import '../../config/colors.dart';
import '../../utils/widgets/custom_text.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final VoidCallback? onBackPressed;
  final VoidCallback? onRefreshPressed;
  final bool showRefreshButton;
  final bool showThemeToggle;
  final List<Widget>? additionalActions;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.onBackPressed,
    this.onRefreshPressed,
    this.showRefreshButton = true,
    this.showThemeToggle = true,
    this.additionalActions,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = context.isDarkMode;
    final double appBarHeight =
        (titleWidget != null && isTablet(context: context))
            ? 85.0
            : kToolbarHeight;

    return AppBar(
      backgroundColor:
          isDarkTheme
              ? AppColors.darkBackgroundColor
              : AppColors.backgroundColor,
      elevation: 0,
      toolbarHeight: appBarHeight,
      leading: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        icon: Icon(
          Icons.arrow_back_ios,
          color:
              isDarkTheme
                  ? AppColors.backgroundColor
                  : AppColors.darkBackgroundColor,
        ),
        onPressed:
            onBackPressed ??
            () {
              context.pop(context);
              // Always navigate to Feed tab (index 0) instead of just going back
              // context.go('/feed');
            },
      ),
      title:
          titleWidget ??
          (title != null
              ? CustomText(
                text: title!,

                color:
                    isDarkTheme
                        ? AppColors.backgroundColor
                        : AppColors.darkBackgroundColor,
                fontWeight: FontWeight.w600,
                fontSize: sz(18, seprateTabletSize: 11),
              )
              : null),
      centerTitle: true,
      actions: [
        // Additional actions if provided
        if (additionalActions != null) ...additionalActions!,

        // // Refresh button
        // if (showRefreshButton)
        //   IconButton(
        //     icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
        //     onPressed: onRefreshPressed,
        //   ),
        //
        // // Theme toggle button
        // if (showThemeToggle)
        //   IconButton(
        //     icon: Icon(
        //       theme.brightness == Brightness.dark
        //         ? Icons.light_mode
        //         : Icons.dark_mode,
        //       color: theme.colorScheme.onSurface,
        //     ),
        //     onPressed: () {
        //       context.read<ThemeBloc>().add(ToggleTheme());
        //     },
        //   ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    (titleWidget != null && isTablet()) ? 85.0 : kToolbarHeight,
  );
}
