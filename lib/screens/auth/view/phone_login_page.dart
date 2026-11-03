import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/auth/bloc/phone_auth_bloc/phone_auth_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/phone_auth_bloc/phone_auth_event.dart';
import 'package:hyper_local/screens/auth/bloc/phone_auth_bloc/phone_auth_state.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'dart:async';


class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _completePhoneNumber = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PhoneAuthBloc>().add(ResetPhoneAuthEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;
    return CustomScaffold(
      wantSafeArea: false,
      body: BlocListener<PhoneAuthBloc, PhoneAuthState>(
        listener: (BuildContext context, PhoneAuthState state) {
          if (state.status == PhoneAuthStatus.otpSent) {
            ToastManager.show(context: context, message: state.message);
            // Navigate to OTP verification page using GoRouter
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final isCustomSms =
                    context
                        .read<SystemSettingsBloc>()
                        .currentSettings
                        ?.isCustomSmsEnabled ??
                    false;
                context.push(
                  AppRoutes.phoneOtpVerification,
                  extra: {
                    'verificationId': state.verificationId,
                    'phoneNumber':
                        isCustomSms
                            ? _phoneController.text.trim()
                            : _completePhoneNumber,
                  },
                );
              }
            });
          } else if (state.status == PhoneAuthStatus.failed) {
            ToastManager.show(context: context, message: state.message);
          } else if (state.status == PhoneAuthStatus.success) {
            ToastManager.show(context: context, message: state.message);
            // Use go() to replace navigation stack

            redirectionCondition(context);
            // context.go(AppRoutes.dashboard);
          } else if (state.status == PhoneAuthStatus.userNotFound ||
              state.status == PhoneAuthStatus.userExists) {
            _formKey.currentState?.validate();
          }
        },
        child: Container(
          height: double.infinity,
          color: AppColors.primaryColor.withValues(alpha: .1),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  logo(isDark),

                  Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 10.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 15.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                text: context.tr('phoneLogin'),
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: CustomText(
                                  text:
                                      context.tr('enterPhoneNumberToReceiveOtp'),
                                  color: Colors.grey,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30.h),
                          phoneNumberField(isDark),
                          SizedBox(height: 20.h),

                          /// Submit button
                          submitButton(),
                          SizedBox(height: 15.h),

                          /// Divider with OR
                          orDivider(),
                          SizedBox(height: 15.h),

                          /// Navigate to email login
                          navigateToEmailLogin(),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Widget logo(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: kToolbarHeight),
      child: CustomImageContainer(
        imagePath: myLogoImage(),
        width: 300,
        height: 300,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget phoneNumberField(bool isDark) {
    return BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
      builder: (context, state) {
        return IntlPhoneField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: context.tr('phoneNumber'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColors.primaryColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor:
                isDark ? AppColors.cardDarkColor : AppColors.cardLightColor,
          ),
          initialCountryCode: 'IN',
          onChanged: (phone) {
            setState(() {
              // Ensure E.164 format with + prefix
              String phoneNumber = phone.completeNumber;
              if (!phoneNumber.startsWith('+')) {
                phoneNumber = '+$phoneNumber';
              }
              _completePhoneNumber = phoneNumber;
            });

            // Cancel previous timer
            _debounceTimer?.cancel();

            // If phone number is too short, reset status to valid
            if (phone.number.length < 8) {
              context.read<PhoneAuthBloc>().add(ResetPhoneAuthEvent());
              return;
            }

            // Start new debouncer
            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
              context.read<PhoneAuthBloc>().add(
                VerifyUserExistsEvent(
                  phoneNumber: phone.number,
                  isVerify: true,
                ),
              );
            });
          },
          validator: (phone) {
            if (phone == null || phone.number.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        );
      },
    );
  }

  Widget submitButton() {
    return BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
      builder: (context, state) {
        final isLoading = state.status == PhoneAuthStatus.sendingOTP;
        final isValidatingUser = state.status == PhoneAuthStatus.userChecking;
        final isUserInvalid = state.status == PhoneAuthStatus.userNotFound;
        final isButtonDisabled = isLoading || isUserInvalid || isValidatingUser;

        return CustomButton(
          text:
              isLoading
                  ? context.tr('sendingOtp')
                  : (isValidatingUser
                      ? context.tr('verifying')
                      : (isUserInvalid
                          ? (state.message.isNotEmpty
                              ? state.message
                              : context.tr('userNotFound'))
                          : context.tr('sendOtp'))),
          onPressed:
              isButtonDisabled
                  ? null
                  : () {
                    if (_formKey.currentState!.validate()) {
                      if (_completePhoneNumber.isEmpty) {
                        ToastManager.show(
                          context: context,
                          message: 'Please enter a valid phone number',
                        );
                        return;
                      }
                      final isCustomSms =
                          context
                              .read<SystemSettingsBloc>()
                              .currentSettings
                              ?.isCustomSmsEnabled ??
                          false;
                      context.read<PhoneAuthBloc>().add(
                        SendOTPEvent(
                          phoneNumber:
                              isCustomSms
                                  ? _phoneController.text.trim()
                                  : _completePhoneNumber,
                          isCustomSms: isCustomSms,
                        ),
                      );
                    }
                  },
        );
      },
    );
  }

  Widget orDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: CustomText(
            text: context.tr('or'),
            color: Colors.grey,
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }

  Widget navigateToEmailLogin() {
    return GestureDetector(
      onTap: () {
        context.pop();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(text: context.tr('loginWithEmail')),
          SizedBox(width: 5.w),
          CustomText(
            text: context.tr('clickHere'),
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
