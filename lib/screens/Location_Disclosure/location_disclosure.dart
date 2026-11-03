import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';

import '../../config/constant.dart';
import '../../router/app_routes.dart';
import '../../utils/location_handler.dart';
import 'package:hyper_local/config/app_images.dart';

class LocationDisclosure extends StatefulWidget {
  const LocationDisclosure({super.key});

  @override
  State<LocationDisclosure> createState() => _LocationDisclosureState();
}

class _LocationDisclosureState extends State<LocationDisclosure> {
  void navigate(BuildContext context) async {
    await Global.setLocationAgree(true);
    LocationHandler.initialize();
    GoRouter.of(context).pushReplacement(AppRoutes.home);
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: CustomText(
            text: context.tr('locationPermissionRequired'),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          content: CustomText(
            text: context.tr('locationMandateTitle'),
            fontSize: 16,
          ),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: CustomText(
                text: context.tr('exitApp'),
                fontSize: 16,
              ),
            ),

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: CustomText(
                text: context.tr('ok'),
                fontSize: 16,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      body: SingleChildScrollView(
        child: Column(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustomImageContainer(imagePath: AppImages.locationDisclosure),
            SizedBox(height: 30.sp),
            CustomText(
              text: context.tr('locationDataUsageDisclosure'),
              fontSize: 25,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.sp),

            CustomText(
              text:
                  "${AppConstant.appName}  ${context.tr('locationUsageDescription')}.",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.sp),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    backgroundColor: Colors.grey,
                    text: context.tr('decline'),
                    textColor: Colors.white,
                    onPressed: () => _showCancelDialog(context),
                  ),
                ),
                SizedBox(width: 10.sp),

                Expanded(
                  child: CustomButton(
                    text: context.tr('accept'),
                    textColor: Colors.white,
                    onPressed: () => navigate(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
