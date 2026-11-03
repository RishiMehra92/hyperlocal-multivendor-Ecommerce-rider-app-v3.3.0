import 'package:flutter/cupertino.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../utils/widgets/custom_text.dart';

class LoadingOverlayWidget extends StatelessWidget {
  const LoadingOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(),
            SizedBox(height: 16.h),
            CustomText(
              text: context.tr('gettingYourLocation'),
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            SizedBox(height: 8.h),
            CustomText(
              text:
                  context.tr('pleaseEnsureLocationPermissionsAreEnabled'),
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ],
        ),
      ),
    );
  }
}
