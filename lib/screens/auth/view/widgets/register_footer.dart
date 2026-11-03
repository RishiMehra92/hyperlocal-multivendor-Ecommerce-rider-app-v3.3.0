import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import '../../../../utils/widgets/custom_button.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../bloc/auth_bloc/auth_bloc.dart';
import '../../bloc/auth_bloc/auth_state.dart';

import '../../../../config/colors.dart';

class RegisterFooter extends StatelessWidget {
  final VoidCallback onRegister;
  final VoidCallback onLogin;

  const RegisterFooter({
    super.key,
    required this.onRegister,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 32.h),
        // Submit button
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state.status == ApiStatus.loading;
            return SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: context.tr('createAccount'),
                onPressed: isLoading ? null : onRegister,
                backgroundColor: AppColors.primaryColor,
                textColor: Colors.white,
                borderRadius: 8.r,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                isLoading: isLoading,
                textStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        SizedBox(height: 16.h),
        // Login link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(text: context.tr('alreadyHaveAccount')),
            TextButton(
              onPressed: onLogin,
              child: CustomText(
                text: context.tr('login'),
                color: Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
