import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../utils/widgets/custom_textfield.dart';
import '../../../../utils/widgets/custom_text.dart';

class PasswordSection extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const PasswordSection({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends State<PasswordSection> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: context.tr('security'),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 16.h),
        // Password
        CustomTextFormField(
          controller: widget.passwordController,
          labelText: context.tr('password'),
          hintText: context.tr('enterYourPassword'),
          prefixIcon: Icons.lock,
          suffixIcon:
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          onSuffixIconTap: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.tr('pleaseEnterYourPassword');
            }
            if (value.length < 8) {
              return context.tr('passwordMustBeAtLeast8Characters');
            }
            // if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
            //   return context.tr('passwordMustContainUppercaseLowercaseAndNumber');
            // }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        // Confirm Password
        CustomTextFormField(
          controller: widget.confirmPasswordController,
          labelText: context.tr('confirmPassword'),
          hintText: context.tr('confirmYourPassword'),
          prefixIcon: Icons.lock_outline,
          suffixIcon:
              _isConfirmPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility,
          onSuffixIconTap: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
          obscureText: !_isConfirmPasswordVisible,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.tr('pleaseConfirmYourPassword');
            }
            if (value != widget.passwordController.text) {
              return context.tr('passwordsDoNotMatch');
            }
            return null;
          },
        ),
      ],
    );
  }
}
