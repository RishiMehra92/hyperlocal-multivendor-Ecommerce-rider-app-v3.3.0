import 'package:flutter/material.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/utils/extensions.dart';

class CustomBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;

  const CustomBottomSheet({super.key, required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    // The bottom sheet takes height but leaves kToolbarHeight from the top
    final double calculatedHeight = height ?? (screenHeight - kToolbarHeight);
    final isDarkTheme = context.isDarkMode;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: kToolbarHeight),
      height: height,
      constraints:
          height == null ? BoxConstraints(maxHeight: calculatedHeight) : null,
      decoration: BoxDecoration(
        color: isDarkTheme ? AppColors.darkBackgroundColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: child,
      ),
    );
  }

  /// Helper method to show the themed custom bottom sheet with calculated height
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    double? height,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return CustomBottomSheet(height: height, child: child);
      },
    );
  }
}
