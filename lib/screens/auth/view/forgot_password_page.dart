import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/screens/auth/bloc/forgot_password/forgot_password_cubit.dart';
import 'package:hyper_local/screens/auth/repo/auth_repo.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/input_formatters.dart';

import '../bloc/forgot_password/forgot_password_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    final isValid =
        email.isNotEmpty &&
        RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

    if (_isEmailValid != isValid) {
      setState(() {
        _isEmailValid = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocProvider(
      create:
          (context) => ForgotPasswordCubit(authRepository: AuthRepository()),
      child: CustomScaffold(
        appBar: CustomAppBar(
          title: context.tr('forgotPassword'),
        ),
        body: BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
          listener: (context, state) {
            if (state.status == ApiStatus.success) {
              ToastManager.show(context: context, message: state.message);
              context.pop();
            } else if (state.status == ApiStatus.failed) {
              ToastManager.show(context: context, message: state.errorMessage);
            }
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Form(
                key: _formKey,
                child: CustomCard(
                  padding: EdgeInsets.all(20.w),
                  borderRadius: 24.r,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Circular Lock Icon
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor.withValues(
                              alpha: isDark ? 0.25 : 0.1,
                            ),
                          ),
                          child: Icon(
                            TablerIcons.lock_open,
                            size: 60.r,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Title
                      CustomText(
                        text: context.tr('forgotPassword'),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 10.h),

                      // Description
                      CustomText(
                        text:
                            context.tr('forgotPasswordDescription'),
                        textAlign: TextAlign.center,
                        fontSize: 13,
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                        height: 1.4,
                      ),

                      SizedBox(height: 28.h),

                      // Email field
                      CustomTextFormField(
                        controller: _emailController,
                        labelText: context.tr('emailAddress'),
                        hintText: context.tr('enterYourEmail'),
                        prefixIcon: TablerIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          LowerCaseTextFormatter(),
                        ],
                        borderRadius: 16.r,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('pleaseEnterYourEmail');
                          }
                          if (!RegExp(
                            r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value.trim())) {
                            return context.tr('pleaseEnterAValidEmail');
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 28.h),

                      // Submit button
                      BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
                        builder: (context, state) {
                          final isLoading = state.status == ApiStatus.loading;

                          return CustomButton(
                            text: context.tr('sendResetLink'),
                            isLoading: isLoading,
                            borderRadius: 16.r,
                            backgroundColor:
                                _isEmailValid && !isLoading
                                    ? AppColors.primaryColor
                                    : AppColors.primaryColor.withValues(
                                      alpha: 0.5,
                                    ),
                            onPressed:
                                (_isEmailValid && !isLoading)
                                    ? () {
                                      if (_formKey.currentState!.validate()) {
                                        context
                                            .read<ForgotPasswordCubit>()
                                            .forgotPassword(
                                              email:
                                                  _emailController.text.trim(),
                                            );
                                      }
                                    }
                                    : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    super.dispose();
  }
}
