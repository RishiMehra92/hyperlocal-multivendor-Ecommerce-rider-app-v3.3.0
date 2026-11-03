import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/app_routes.dart';
import '../../../../utils/widgets/custom_textfield.dart';
import '../../../../utils/widgets/custom_text.dart';

class VehicleInfoSection extends StatelessWidget {
  final TextEditingController vehicleTypeController;
  final TextEditingController deliveryLicenseNumberController;
  final TextEditingController deliveryZoneController;
  final int? selectedDeliveryZoneId;

  const VehicleInfoSection({
    super.key,
    required this.vehicleTypeController,
    required this.deliveryLicenseNumberController,
    required this.deliveryZoneController,
    this.selectedDeliveryZoneId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: context.tr('vehicleInformation'),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 16.h),
        // Vehicle Type
        CustomTextFormField(
          controller: vehicleTypeController,
          labelText: context.tr('vehicleType'),
          hintText: context.tr('enterYourVehicleType'),
          prefixIcon: Icons.electric_bike,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.tr('pleaseEnterYourVehicleType');
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        // Driver License Number
        CustomTextFormField(
          controller: deliveryLicenseNumberController,
          labelText: context.tr('driverLicenseNumber'),
          hintText: context.tr('enterYourLicenseNumber'),
          prefixIcon: Icons.card_membership,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.tr('pleaseEnterYourLicenseNumber');
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        // Delivery Zone
        CustomTextFormField(
          readOnly: true,
          controller: deliveryZoneController,
          labelText: context.tr('deliveryZone'),
          hintText: context.tr('selectYourDeliveryZone'),
          prefixIcon: Icons.location_on,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          onTap: () async {
            await GoRouter.of(context).push(AppRoutes.deliveryZone);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.tr('pleaseSelectYourDeliveryZone');
            }
            return null;
          },
        ),
      ],
    );
  }
}
