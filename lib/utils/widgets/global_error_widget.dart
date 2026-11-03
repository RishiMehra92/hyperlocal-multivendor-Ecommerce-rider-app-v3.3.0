import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';

class GlobalErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const GlobalErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final title = context.tr('somethingWentWrong', fallback: 'Something went wrong');
    final description =
        context.tr('unableToLoadData', fallback: 'Unable to load data');
    final buttonText = context.tr('goBack', fallback: 'Go Back');

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDarkMode ? Colors.white70 : const Color(0xFF4B5563);

    return CustomScaffold(
      appBar: CustomAppBar(title: context.tr('error', fallback: "Error")),

      wantSafeArea: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning Shield Icon
              Container(
                width: 72.w,
                height: 72.h,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2), // Light red soft background
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: const Color(0xFFEF4444), // Crimson red error color
                  size: 44.w,
                ),
              ),
              SizedBox(height: 24.h),
              // Title
              CustomText(
                text: title,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              // Message
              CustomText(
                text: description,
                color: subtitleColor,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28.h),
              // Design System Custom Button
              CustomButton(
                text: buttonText,
                onPressed: () {
                  Navigator.pop(context);
                  // Leave onTap empty as requested by the user
                },
                width: double.infinity,
                backgroundColor: const Color(
                  0xFF10B981,
                ), // Premium emerald green
                textColor: Colors.white,
                borderRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
