import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
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
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:hyper_local/utils/widgets/custom_pin_field.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';


class PhoneOTPVerificationPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final bool isRegistration;
  final Map<String, dynamic>? registrationData;

  const PhoneOTPVerificationPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.isRegistration = false,
    this.registrationData,
  });

  @override
  State<PhoneOTPVerificationPage> createState() =>
      _PhoneOTPVerificationPageState();
}

class _PhoneOTPVerificationPageState extends State<PhoneOTPVerificationPage>
    with CodeAutoFill {
  late TextEditingController _otpController;
  final _formKey = GlobalKey<FormState>();
  String _currentOtp = '';
  int _resendTimer = 60;
  Timer? _timer;
  bool _isResentTap = false;

  @override
  void initState() {
    _otpController = TextEditingController();
    super.initState();
    _startResendTimer();
    listenForCode();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _timer?.cancel();
    try {
      _otpController.dispose();
    } catch (e) {
      debugPrint('Error disposing OTP controller: $e');
    }
    cancel();
    super.dispose();
  }

  @override
  void codeUpdated() {
    final c = code;
    if (c == null || c.length != 6) return;
    if (!mounted) return;
    _otpController.text = c;
    setState(() {
      _currentOtp = c;
    });
    _submitOtp(c);
  }

  void _submitOtp(String otp) {
    if (otp.length != 6) return;
    final isCustomSms =
        context
            .read<SystemSettingsBloc>()
            .currentSettings
            ?.isCustomSmsEnabled ??
        false;
    if (widget.isRegistration && widget.registrationData != null) {
      context.read<PhoneAuthBloc>().add(
        VerifyOTPAndRegisterEvent(
          verificationId: widget.verificationId,
          otp: otp,
          registrationData: widget.registrationData!,
          isCustomSms: isCustomSms,
        ),
      );
    } else {
      context.read<PhoneAuthBloc>().add(
        VerifyOTPEvent(
          verificationId: widget.verificationId,
          otp: otp,
          isCustomSms: isCustomSms,
        ),
      );
    }
  }

  void _startResendTimer() {
    _isResentTap = false;
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;

    return CustomScaffold(
      wantSafeArea: false,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor.withValues(alpha: .1),
      ),
      resizeToAvoidBottomInset: true,

      // appBar: AppBar(backgroundColor: AppColors.primaryColor.withValues(alpha: .1)),
      body: BlocListener<PhoneAuthBloc, PhoneAuthState>(
        listener: (BuildContext context, PhoneAuthState state) async {
          if (state.status == PhoneAuthStatus.otpVerified) {
            ToastManager.show(context: context, message: state.message);
          } else if (state.status == PhoneAuthStatus.success) {
            ///Here when i just enter number of Currently Registered User and this called

            ToastManager.show(context: context, message: state.message);
            // context.go(AppRoutes.dashboard);
            redirectionCondition(context);
          } else if (state.status == PhoneAuthStatus.registrationSuccess) {
            ///When New User Registered thnen this Shows up

            ToastManager.show(context: context, message: state.message);
            ToastManager.show(
              context: context,
              message: context.tr('accountNotVerified'),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go(AppRoutes.login);
            });
          } else if (state.status == PhoneAuthStatus.userNotFound) {
            // Phone verified but no account — show message and redirect
            ToastManager.show(context: context, message: state.message);

            // Navigate back to login using go() to clear the phone login/otp stack
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go(AppRoutes.login);
                context.push(AppRoutes.register);
              }
            });
          } else if (state.status == PhoneAuthStatus.failed) {
            setState(() {
              _isResentTap = false;
            });
            ToastManager.show(context: context, message: state.message);
          } else if (state.status == PhoneAuthStatus.otpResent) {
            ToastManager.show(
              context: context,
              message: context.tr('otpResentSuccessfully'),
            );
            _startResendTimer();
          }
        },
        child: Form(
          key: _formKey,
          child: Container(
            color: AppColors.primaryColor.withValues(alpha: .1),
            child: Column(
              children: [
                /// Top section with icon
                const Expanded(
                  flex: 1,
                  child: Icon(
                    Icons.phone_android,
                    size: 200,
                    color: AppColors.primaryColor,
                  ),
                ),

                /// Form section
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22.r),
                        topRight: Radius.circular(22.r),
                      ),
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
                          CustomText(
                            text: context.tr('verifyOtp'),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          CustomText(
                            text:
                                context.tr('enter6DigitCodeSentTo'),
                            color: Colors.grey,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 5.h),
                          CustomText(
                            text: widget.phoneNumber,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 30.h),
                          otpField(),
                          SizedBox(height: 30.h),

                          /// Verify button
                          verifyButton(),
                          SizedBox(height: 15.h),

                          /// Resend OTP
                          resendOTPWidget(),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget otpField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: PinFieldAuto(
        controller: _otpController,
        onCodeChanged: (code) {
          final val = code ?? "";
          if (mounted) {
            setState(() {
              _currentOtp = val;
            });
          }
          if (val.length == 6) {
            _submitOtp(val);
          }
        },
        onCodeSubmitted: (code) {
          if (mounted) {
            setState(() {
              _currentOtp = code;
            });
          }
          if (code.length == 6) {
            _submitOtp(code);
          }
        },
      ),
    );
  }

  Widget verifyButton() {
    return BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
      builder: (context, state) {
        final isLoading =
            state.status == PhoneAuthStatus.verifyingOTP ||
            state.status == PhoneAuthStatus.authenticating ||
            state.status == PhoneAuthStatus.registering;

        String buttonText = context.tr('verifyOtp');
        if (state.status == PhoneAuthStatus.verifyingOTP) {
          buttonText = context.tr('verifying');
        } else if (state.status == PhoneAuthStatus.authenticating) {
          buttonText = context.tr('authenticating');
        } else if (state.status == PhoneAuthStatus.registering) {
          buttonText = context.tr('registering');
        }

        return CustomButton(
          text: buttonText,
          onPressed:
              isLoading
                  ? null
                  : () {
                    if (_currentOtp.length != 6) {
                      ToastManager.show(
                        context: context,
                        message:
                            context.tr('pleaseEnterComplete6DigitOtp'),
                      );
                      return;
                    }

                    _submitOtp(_currentOtp);
                  },
        );
      },
    );
  }

  Widget PhoneAuthBlocOTPWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomText(text: context.tr('didntReceiveCode')),
        if (_resendTimer > 0)
          CustomText(
            text: context.tr('resendInSeconds', positionalArgs: [_resendTimer]),
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          )
        else
          GestureDetector(
            onTap: () {
              final isCustomSms =
                  context
                      .read<SystemSettingsBloc>()
                      .currentSettings
                      ?.isCustomSmsEnabled ??
                  false;
              context.read<PhoneAuthBloc>().add(
                ResendOTPEvent(
                  phoneNumber: widget.phoneNumber,
                  registrationData: widget.registrationData,
                  isCustomSms: isCustomSms,
                ),
              );
            },
            child: CustomText(
              text: context.tr('resend'),
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget resendOTPWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomText(text: context.tr('didntReceiveCode')),

        if (_resendTimer > 0)
          CustomText(
            text: context.tr('resendInSeconds', positionalArgs: [_resendTimer]),
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          )
        else
          GestureDetector(
            onTap: () {
              if (_isResentTap) return;
              setState(() {
                _isResentTap = true;
              });
              final isCustomSms =
                  context
                      .read<SystemSettingsBloc>()
                      .currentSettings
                      ?.isCustomSmsEnabled ??
                  false;
              context.read<PhoneAuthBloc>().add(
                ResendOTPEvent(
                  phoneNumber: widget.phoneNumber,
                  registrationData: widget.registrationData,
                  isCustomSms: isCustomSms,
                ),
              );
            },
            child: CustomText(
              text: context.tr('resend'),
              color: _isResentTap ? Colors.grey : AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
