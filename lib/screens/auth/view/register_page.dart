import 'dart:developer';
import 'package:hyper_local/utils/extensions/translation_extension.dart';


import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/screens/auth/bloc/auth_bloc/auth_event.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_dropdown.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/media_picker_bottom_sheet.dart';
import 'dart:io';
import '../../../config/colors.dart';
import '../../../config/helper.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/custom_textfield.dart';
import '../../../utils/widgets/custom_button.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../system_settings/bloc/system_settings_state.dart';
import '../bloc/auth_bloc/auth_bloc.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import '../bloc/auth_bloc/auth_state.dart';
import '../bloc/phone_auth_bloc/phone_auth_bloc.dart';
import '../bloc/phone_auth_bloc/phone_auth_event.dart';
import '../bloc/phone_auth_bloc/phone_auth_state.dart';
import 'package:hyper_local/utils/input_formatters.dart';
import '../bloc/delivery_zone_bloc/delivery_zone_bloc.dart';
import '../bloc/delivery_zone_bloc/delivery_zone_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final _addressController = TextEditingController();
  final _delievryZoneController = TextEditingController();
  final _deliveryLicenseNumberController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _friends_code = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  MobileANdEmailStatus _mobileStatus = MobileANdEmailStatus.initial;
  MobileANdEmailStatus _emailStatus = MobileANdEmailStatus.initial;

  // Phone field data
  String _countryIso2 = 'IN';
  String _countryCode = '+91';
  String _countryName = 'India';

  // File picker variables (Index 0: Front Side, Index 1: Back Side)
  final List<File?> _driverLicenseFiles = [null, null];
  final List<File?> _vehicleRegistrationFiles = [null, null];
  final List<String?> _driverLicenseFileNames = [null, null];
  final List<String?> _vehicleRegistrationFileNames = [null, null];
  int? _selectedDeliveryZoneId;
  String? _selectedVehicleType;

  @override
  void initState() {
    super.initState();
    _countryIso2 = 'IN';
    _countryCode = '+91';
    _countryName = 'India';
    _countryController.text = ' ';
  }

  // File picker method
  Future<void> _pickFile({required String type, required int index}) async {
    try {
      final File? pickedFile = await MediaPickerBottomSheet.show(context, allowFile: true);

      if (!mounted) return;

      if (pickedFile == null) {
        ToastManager.show(context: context, message: context.tr('noFilesSelected'));
        return;
      }

      setState(() {
        if (type == 'driver_license') {
          _driverLicenseFiles[index] = pickedFile;
          _driverLicenseFileNames[index] = pickedFile.path.split('/').last;
        } else if (type == 'vehicle_registration') {
          _vehicleRegistrationFiles[index] = pickedFile;
          _vehicleRegistrationFileNames[index] = pickedFile.path.split('/').last;
        }
      });
    } catch (e) {
      ToastManager.show(context: context, message: 'Error picking file: $e');
    }
  }

  // Remove file method
  void _removeFile(String type, int index) {
    setState(() {
      if (type == 'driver_license') {
        _driverLicenseFiles[index] = null;
        _driverLicenseFileNames[index] = null;
      } else if (type == 'vehicle_registration') {
        _vehicleRegistrationFiles[index] = null;
        _vehicleRegistrationFileNames[index] = null;
      }
    });
  }

  String countryFlag(String countryCode) {
    return countryCode.toUpperCase().replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
    );
  }

  String get _fullPhoneNumber {
    final phone = _phoneNumberController.text.trim();
    if (phone.isEmpty || _countryCode.isEmpty) return '';
    // Ensure E.164 format with + prefix
    String countryCode = _countryCode;
    if (!countryCode.startsWith('+')) {
      countryCode = '+$countryCode';
    }
    return '$countryCode$phone'; // e.g., +919876543210
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    final isDark = context.isDarkMode;
    return Row(
      spacing: 5,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: isDark ? 0.25 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 20),
        ),
        CustomText(text: title, fontWeight: FontWeight.w600, color: AppColors.primaryColor),
      ],
    );
  }

  Widget _buildUploadCard({required String title, required String type, required List<File?> files}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: title,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _buildDocumentBox(
              label: context.tr('frontSide'),
              file: files[0],
              onUpload: () => _pickFile(type: type, index: 0),
              onRemove: () => _removeFile(type, 0),
            ),
            const SizedBox(width: 16),
            _buildDocumentBox(
              label: context.tr('backSide'),
              file: files[1],
              onUpload: () => _pickFile(type: type, index: 1),
              onRemove: () => _removeFile(type, 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentBox({
    required String label,
    required File? file,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    final isDark = context.isDarkMode;
    final hasImage = file != null;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: label,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          SizedBox(height: 6.h),
          AspectRatio(
            aspectRatio: 1.5,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDarkColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Stack(
                children: [
                  if (hasImage) ...[
                    Builder(
                      builder: (context) {
                        final path = file.path.toLowerCase();
                        final isPdf = path.endsWith('.pdf');
                        final isDoc = path.endsWith('.doc') || path.endsWith('.docx');

                        if (isPdf || isDoc) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: Icon(
                                isPdf ? TablerIcons.file_type_pdf : TablerIcons.file_type_doc,
                                size: 32.sp,
                                color: isPdf ? Colors.red : Colors.blue,
                              ),
                            ),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.file(file, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                        );
                      },
                    ),
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: GestureDetector(
                        onTap: onUpload,
                        child: Icon(Icons.add_a_photo_outlined, color: AppColors.primaryColor, size: 24.sp),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return CustomScaffold(
      wantSafeArea: false,
      appBar: CustomAppBar(title: context.tr('register')),

      body: BlocListener<PhoneAuthBloc, PhoneAuthState>(
        listener: (BuildContext context, PhoneAuthState state) {
          if (state.status == PhoneAuthStatus.otpSent) {
            ToastManager.show(context: context, message: state.message);
            final isCustomSms = context.read<SystemSettingsBloc>().currentSettings?.isCustomSmsEnabled ?? false;
            context.push(
              AppRoutes.phoneOtpVerification,
              extra: {
                'verificationId': state.verificationId,
                'phoneNumber': isCustomSms ? _phoneNumberController.text.trim() : _fullPhoneNumber,
                'isRegistration': true,
                'registrationData': {
                  'name': _nameController.text.trim(),
                  'email': _emailController.text.trim(),
                  'mobile': _phoneNumberController.text.trim(),
                  'password': _passwordController.text,
                  'country': _countryName,
                  'iso2': _countryIso2,
                  'countryCode': _countryCode,
                  'completePhoneNumber': _fullPhoneNumber,
                  'confirmPassword': _confirmPasswordController.text,
                  'driverLicenseFiles': _driverLicenseFiles.whereType<File>().toList(),
                  'vehicleRegistrationFiles': _vehicleRegistrationFiles.whereType<File>().toList(),
                  'address': _addressController.text.trim(),
                  'vehicleType': _selectedVehicleType!,
                  'driverLicenseNumber': _deliveryLicenseNumberController.text.trim(),
                  'deliveryZoneId': _selectedDeliveryZoneId ?? 0,
                  "friends_code": _friends_code.text.trim(),
                },
              },
            );
          } else if (state.status == PhoneAuthStatus.registrationSuccess) {
            // Note: Redirection to Login is handled by PhoneOTPVerificationPage.
            // Do not call redirectionCondition(context) here to avoid navigating to home.
            // ToastManager.show(context: context, message: state.message);
          } else if (state.status == PhoneAuthStatus.failed) {
            ToastManager.show(context: context, message: state.message);
          }
        },
        child: BlocListener<AuthBloc, AuthState>(
          listener: (BuildContext context, AuthState state) {
            if (state.status == ApiStatus.success) {
              context.pop();
              ToastManager.show(context: context, message: state.message);
            } else if (state.status == ApiStatus.failed) {
              ToastManager.show(context: context, message: state.message);
            }

            if (state.mobileANdEmailStatus == MobileANdEmailStatus.loading ||
                state.mobileANdEmailStatus == MobileANdEmailStatus.isnew ||
                state.mobileANdEmailStatus == MobileANdEmailStatus.isuse) {
              setState(() {
                _mobileStatus = state.mobileANdEmailStatus;
              });
            }

            if (state.emailStatus == MobileANdEmailStatus.loading ||
                state.emailStatus == MobileANdEmailStatus.isnew ||
                state.emailStatus == MobileANdEmailStatus.isuse) {
              setState(() {
                _emailStatus = state.emailStatus;
              });
            }
          },
          child: BlocListener<DeliveryZoneBloc, DeliveryZoneState>(
            listener: (context, state) {
              if (state.fetchStatus == ApiStatus.success && state.selectedZone != null) {
                setState(() {
                  _delievryZoneController.text = state.selectedZone!.name ?? "";
                  _selectedDeliveryZoneId = state.selectedZone!.id;
                });
              }
            },
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo

                    // Title Text
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: context.tr('createSpan'),
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                ),
                                TextSpan(
                                  text: context.tr('accountSpan'),
                                  style: const TextStyle(color: AppColors.primaryColor),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          CustomText(
                            text: context.tr('signUpToStartDeliveringHappiness'),
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Form Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: CustomCard(
                        padding: EdgeInsets.all(16.w),
                        borderRadius: 20.r,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Personal Information Section
                            _buildSectionHeader(
                              icon: TablerIcons.user,
                              title: context.tr('personalInformation'),
                            ),
                            SizedBox(height: 16.h),
                            CustomTextFormField(
                              controller: _nameController,
                              labelText: context.tr('fullName'),
                              hintText: context.tr('enterYourFullName'),
                              prefixIcon: TablerIcons.user,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              borderRadius: 16.r,
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
                            SizedBox(height: 12.h),
                            CustomTextFormField(
                              mySuffixColor: switch (_emailStatus) {
                                MobileANdEmailStatus.loading => AppColors.darkPrimaryColor,
                                MobileANdEmailStatus.isuse => AppColors.errorColor,
                                MobileANdEmailStatus.isnew => AppColors.successColor,
                                _ => null,
                              },
                              suffixIcon: switch (_emailStatus) {
                                MobileANdEmailStatus.loading => TablerIcons.loader,
                                MobileANdEmailStatus.isuse => Icons.cancel_outlined,
                                MobileANdEmailStatus.isnew => Icons.check_circle_outline,
                                _ => null,
                              },
                              controller: _emailController,
                              labelText: context.tr('emailAddress'),
                              hintText: context.tr('enterYourEmail'),
                              prefixIcon: TablerIcons.mail,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                LowerCaseTextFormatter(),
                              ],
                              borderRadius: 16.r,
                              onChanged: (val) {
                                final email = val.trim();
                                if (RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                                  context.read<AuthBloc>().add(EmailOrMobileNumber(type: "email", value: email));
                                } else {
                                  setState(() {
                                    _emailStatus = MobileANdEmailStatus.initial;
                                  });
                                }
                              },
                              validator: (value) {
                                if (_emailStatus == MobileANdEmailStatus.loading) {
                                  return context.tr('loading');
                                }
                                if (_emailStatus == MobileANdEmailStatus.isuse) {
                                  return context.tr('emailAlreadyRegistered');
                                }
                                if (value == null || value.isEmpty) {
                                  return context.tr('pleaseEnterYourEmail');
                                }
                                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                  return context.tr('pleaseEnterAValidEmail');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 12.h),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Country Selection Field (Left)
                                  InkWell(
                                    onTap: () {
                                      showCountryPicker(
                                        context: context,
                                        showPhoneCode: true,
                                        countryListTheme: CountryListThemeData(
                                          flagSize: 24,
                                          backgroundColor: isDark ? AppColors.cardDarkColor : Colors.white,
                                          textStyle: TextStyle(
                                            fontSize: 14,
                                            color: isDark ? Colors.white : Colors.black,
                                          ),
                                          bottomSheetHeight: 500,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20.r),
                                            topRight: Radius.circular(20.r),
                                          ),
                                          inputDecoration: InputDecoration(
                                            labelText: context.tr('search'),
                                            hintText: context.tr('search'),
                                            prefixIcon: const Icon(Icons.search),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16.r),
                                              borderSide: BorderSide(
                                                color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
                                              ),
                                            ),
                                          ),
                                        ),
                                        onSelect: (Country country) {
                                          setState(() {
                                            _countryController.text = country.name;
                                            _countryIso2 = country.countryCode;
                                            String phoneCode = country.phoneCode;
                                            if (!phoneCode.startsWith('+')) {
                                              phoneCode = '+$phoneCode';
                                            }
                                            _countryCode = phoneCode;
                                            _countryName = country.name;
                                          });
                                        },
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.cardDarkColor : AppColors.cardLightColor,
                                        borderRadius: BorderRadius.circular(16.r),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            TablerIcons.globe,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                          ),
                                          SizedBox(width: 8.w),
                                          CustomText(
                                            text: '$_countryCode $_countryIso2',
                                            fontSize: sz(11, seprateTabletSize: 7),
                                            fontWeight: FontWeight.w600,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Icon(TablerIcons.chevron_down, color: Colors.grey, size: 14.sp),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  // Phone Number Field (Right)
                                  Expanded(
                                    flex: 3,
                                    child: CustomTextFormField(
                                      mySuffixColor: switch (_mobileStatus) {
                                        MobileANdEmailStatus.loading => AppColors.darkPrimaryColor,
                                        MobileANdEmailStatus.isuse => AppColors.errorColor,
                                        MobileANdEmailStatus.isnew => AppColors.successColor,
                                        _ => null,
                                      },
                                      suffixIcon: switch (_mobileStatus) {
                                        MobileANdEmailStatus.loading => TablerIcons.loader,
                                        MobileANdEmailStatus.isuse => TablerIcons.x,
                                        MobileANdEmailStatus.isnew => TablerIcons.circle_check,
                                        _ => null,
                                      },
                                      controller: _phoneNumberController,
                                      labelText: context.tr('phoneNumber'),
                                      hintText: context.tr('enterYourPhoneNumber'),
                                      prefixIcon: TablerIcons.phone,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      borderRadius: 16.r,
                                      onChanged: (val) {
                                        if (val.length > 9) {
                                          context.read<AuthBloc>().add(
                                            EmailOrMobileNumber(type: "mobile", value: val.toString()),
                                          );
                                        } else {
                                          setState(() {
                                            _mobileStatus = MobileANdEmailStatus.initial;
                                          });
                                        }
                                      },
                                      validator: (value) {
                                        if (_mobileStatus == MobileANdEmailStatus.loading) {
                                          return context.tr('loading');
                                        }
                                        if (_mobileStatus == MobileANdEmailStatus.isuse) {
                                          return context.tr('mobileNoInUse');
                                        }
                                        if (value == null || value.isEmpty) {
                                          return context.tr('pleaseEnterYourPhoneNumber');
                                        }
                                        if (value.length < 5 || value.length > 17) {
                                          return context.tr('invalidPhone');
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // 2. Security Section
                            _buildSectionHeader(
                              icon: TablerIcons.shield_lock,
                              title: context.tr('security'),
                            ),
                            SizedBox(height: 16.h),
                            CustomTextFormField(
                              controller: _passwordController,
                              labelText: context.tr('password'),
                              hintText: context.tr('enterYourPassword'),
                              prefixIcon: TablerIcons.lock,
                              suffixIcon: _isPasswordVisible ? TablerIcons.eye_off : TablerIcons.eye,
                              onSuffixIconTap: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              obscureText: !_isPasswordVisible,
                              textInputAction: TextInputAction.next,
                              borderRadius: 16.r,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return context.tr('pleaseEnterYourPassword');
                                }
                                if (value.length < 8) {
                                  return context.tr('passwordMustBeAtLeast8Characters');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 12.h),
                            CustomTextFormField(
                              controller: _confirmPasswordController,
                              labelText: context.tr('confirmPassword'),
                              hintText: context.tr('confirmYourPassword'),
                              prefixIcon: TablerIcons.lock,
                              suffixIcon: _isConfirmPasswordVisible ? TablerIcons.eye_off : TablerIcons.eye,
                              onSuffixIconTap: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                              obscureText: !_isConfirmPasswordVisible,
                              textInputAction: TextInputAction.next,
                              borderRadius: 16.r,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return context.tr('pleaseConfirmYourPassword');
                                }
                                if (value != _passwordController.text) {
                                  return context.tr('passwordsDoNotMatch');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 24.h),

                            // 3. Professional Details Section
                            _buildSectionHeader(icon: TablerIcons.license, title: 'Professional Details'),
                            SizedBox(height: 16.h),
                            CustomDropdownFormField<String>(
                              labelText: context.tr('vehicleType'),
                              hintText: context.tr('selectVehicleType'),
                              prefixIcon: TablerIcons.car,
                              value: _selectedVehicleType,
                              borderRadius: 16.r,
                              items: const [
                                DropdownMenuItem(value: 'car', child: Text('Car')),
                                DropdownMenuItem(value: 'bike', child: Text('Bike')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedVehicleType = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return context.tr('pleaseSelectVehicleType');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 12.h),
                            CustomTextFormField(
                              controller: _deliveryLicenseNumberController,
                              labelText: context.tr('driverLicenseNumber'),
                              hintText: context.tr('enterYourLicenseNumber'),
                              prefixIcon: TablerIcons.credit_card,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              borderRadius: 16.r,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return context.tr('pleaseEnterYourLicenseNumber');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 12.h),
                            CustomTextFormField(
                              readOnly: true,
                              controller: _delievryZoneController,
                              labelText: context.tr('deliveryZone'),
                              hintText: context.tr('selectYourDeliveryZone'),
                              prefixIcon: TablerIcons.map_pin,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              borderRadius: 16.r,
                              onTap: () async {
                                final result = await GoRouter.of(
                                  context,
                                ).push(AppRoutes.authDeliveryZoneList, extra: {'isSelectionMode': true});

                                if (result != null && result is Map<String, dynamic>) {
                                  setState(() {
                                    _delievryZoneController.text = result['name'] ?? '';
                                    _selectedDeliveryZoneId = result['id'];
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return context.tr('pleaseSelectYourDeliveryZone');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 12.h),
                            BlocBuilder<SystemSettingsBloc, SystemSettingsState>(
                              builder: (context, settingsState) {
                                final bool isReferVisible = settingsState.settings?.referStatus ?? false;
                                print(isReferVisible);

                                return !isReferVisible
                                    ? const SizedBox()
                                    : CustomTextFormField(
                                      controller: _friends_code,
                                      labelText: context.tr('referAndEarn'),
                                      hintText: context.tr('enterrefercode'),
                                      prefixIcon: TablerIcons.gift,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      borderRadius: 16.r,
                                      inputFormatters: [UpperCaseTextFormatter()],
                                    );
                              },
                            ),
                            SizedBox(height: 24.h),

                            // 4. Address Section
                            _buildSectionHeader(icon: TablerIcons.home, title: context.tr('address')),
                            SizedBox(height: 16.h),
                            CustomTextFormField(
                              controller: _addressController,
                              labelText: context.tr('address'),
                              hintText: context.tr('enterYourAddress'),
                              prefixIcon: TablerIcons.map_pin,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.done,
                              maxLines: 4,
                              borderRadius: 16.r,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return context.tr('pleaseEnterYourAddress');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 24.h),

                            // 5. Verification Documents Section
                            _buildSectionHeader(icon: TablerIcons.file_upload, title: 'Verification Documents'),
                            SizedBox(height: 16.h),
                            _buildUploadCard(
                              title: context.tr('driverLicense'),
                              type: 'driver_license',
                              files: _driverLicenseFiles,
                            ),
                            SizedBox(height: 16.h),
                            _buildUploadCard(
                              title: context.tr('vehicleRegistration'),
                              type: 'vehicle_registration',
                              files: _vehicleRegistrationFiles,
                            ),
                            SizedBox(height: 32.h),

                            // Submit Button
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, authState) {
                                return BlocBuilder<PhoneAuthBloc, PhoneAuthState>(
                                  builder: (context, phoneAuthState) {
                                    final isLoading =
                                        authState.status == ApiStatus.loading ||
                                        phoneAuthState.status == PhoneAuthStatus.sendingOTP;
                                    return SizedBox(
                                      width: double.infinity,
                                      child: CustomButton(
                                        text: context.tr('createAccount'),
                                        onPressed: isLoading ? null : _handleRegister,
                                        backgroundColor: AppColors.primaryColor,
                                        isLoading: isLoading,
                                        borderRadius: 16.r,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            SizedBox(height: 16.h),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomText(
                                  text: context.tr('alreadyHaveAccount'),
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.pop();
                                  },
                                  child: CustomText(
                                    text: context.tr('login'),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      final fullPhone = _fullPhoneNumber;
      log('Full phone number: $fullPhone');

      if (fullPhone.isEmpty) {
        ToastManager.show(context: context, message: context.tr('pleaseEnterAValidPhoneNumber'));
        return;
      }
      if (_driverLicenseFiles.whereType<File>().isEmpty) {
        ToastManager.show(
          context: context,
          message: context.tr('pleaseUploadAtLeastOneDriverLicenseFile'),
        );
        return;
      }
      if (_vehicleRegistrationFiles.whereType<File>().isEmpty) {
        ToastManager.show(
          context: context,
          message: context.tr('pleaseUploadAtLeastOneVehicleRegistrationFile'),
        );
        return;
      }

      final isCustomSms = context.read<SystemSettingsBloc>().currentSettings?.isCustomSmsEnabled ?? false;
      context.read<PhoneAuthBloc>().add(
        SendOTPForRegistrationEvent(
          phoneNumber: isCustomSms ? _phoneNumberController.text.trim() : _fullPhoneNumber,
          isCustomSms: isCustomSms,
          registrationData: {
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'mobile': _phoneNumberController.text.trim(),
            'password': _passwordController.text,
            'country': _countryName,
            'iso2': _countryIso2,
            'countryCode': _countryCode,
            'completePhoneNumber': _fullPhoneNumber,
            'confirmPassword': _confirmPasswordController.text,
            'driverLicenseFiles': _driverLicenseFiles.whereType<File>().toList(),
            'vehicleRegistrationFiles': _vehicleRegistrationFiles.whereType<File>().toList(),
            'address': _addressController.text.trim(),
            'vehicleType': _selectedVehicleType!,
            'driverLicenseNumber': _deliveryLicenseNumberController.text.trim(),
            'deliveryZoneId': _selectedDeliveryZoneId ?? 0,
            "friends_code": _friends_code.text.trim(),
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _vehicleTypeController.dispose();
    _deliveryLicenseNumberController.dispose();
    _phoneNumberController.dispose();
    _countryController.dispose();
    _delievryZoneController.dispose();
    _friends_code.dispose();
    _mobileStatus = MobileANdEmailStatus.initial;
    _emailStatus = MobileANdEmailStatus.initial;
    super.dispose();
  }
}
