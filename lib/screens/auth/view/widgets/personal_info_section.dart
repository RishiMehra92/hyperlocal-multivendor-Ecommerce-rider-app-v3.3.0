import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../utils/widgets/custom_textfield.dart';
import '../../../../utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/input_formatters.dart';

class PersonalInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController addressController;

  const PersonalInfoSection({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: context.tr('personalInformation'),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 16.h),
        // Name
        CustomTextFormField(
          controller: nameController,
          labelText: context.tr('fullName'),
          hintText: context.tr('enterYourFullName'),
          prefixIcon: Icons.person,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.tr('pleaseEnterYourFullName');
            }
            if (value.length < 2) {
              return context.tr('nameMustBeAtLeast2Characters');
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        // Email
        CustomTextFormField(
          controller: emailController,
          labelText: context.tr('email'),
          hintText: context.tr('enterYourEmail'),
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
            LowerCaseTextFormatter(),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.tr('pleaseEnterYourEmail');
            }
            if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return context.tr('pleaseEnterAValidEmail');
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        // Address
        CustomTextFormField(
          controller: addressController,
          labelText: context.tr('address'),
          hintText: context.tr('enterYourAddress'),
          prefixIcon: Icons.home,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.tr('pleaseEnterYourAddress');
            }
            return null;
          },
        ),
      ],
    );
  }
}
