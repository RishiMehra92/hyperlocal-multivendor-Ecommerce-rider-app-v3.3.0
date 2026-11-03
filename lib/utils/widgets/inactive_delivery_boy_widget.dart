import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import 'package:hyper_local/config/app_images.dart';

class InactiveDeliveryBoyWidget extends StatelessWidget {
  final String? message;
  final String? buttonText;

  const InactiveDeliveryBoyWidget({super.key, this.message, this.buttonText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  heightFactor: 0.7,
                  child: Lottie.asset(
                    AppImages.notActiveLottie,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              CustomText(
                text: context.tr('accountInactive'),
                fontSize: sz(22, seprateTabletSize: 20),
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 12.h),
              CustomText(
                text:
                    message ??
                    context.tr('activateAccountToViewOrders'),
                color: Colors.grey[600],
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<DeliveryBoyStatusBloc>().add(
                    const ToggleStatus(true),
                  );
                },
                icon: Icon(
                  Icons.power_settings_new,
                  color: Colors.white,
                  size: 20.sp,
                ),
                label: CustomText(
                  text: buttonText ?? context.tr('goOnline'),
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.w,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
