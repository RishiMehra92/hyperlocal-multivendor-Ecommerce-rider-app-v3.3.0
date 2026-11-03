import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_state.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import 'package:hyper_local/utils/input_formatters.dart';

import 'dart:io';
import 'package:hyper_local/utils/widgets/media_picker_bottom_sheet.dart';
import '../../../../config/colors.dart';
import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_image_container.dart';
import '../../bloc/profile_bloc/profile_bloc.dart';
import '../../bloc/profile_bloc/profile_event.dart';
import '../../bloc/profile_bloc/profile_state.dart';
import '../../model/profile_model.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load profile data
    context.read<ProfileBloc>().add(const LoadProfile());

    final profileState = context.read<ProfileBloc>().state;
    if (profileState.profile != null) {
      _populateFields(profileState.profile!);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _populateFields(ProfileModel profile) {
    if (profile.deliveryBoy != null) {
      _fullNameController.text = profile.deliveryBoy!.fullName ?? '';
      _addressController.text = profile.deliveryBoy!.address ?? '';
    }
    if (profile.user != null) {
      _mobileController.text = profile.user!.mobile ?? '';
      _emailController.text = profile.user!.email ?? '';
      _countryController.text = profile.user!.country ?? '';
    }

    // Don't call setState here - let the parent handle it
  }

  void _toggleEdit() {
    final bool isDemo = context.read<SystemSettingsBloc>().isDemo;
    if (isDemo) {
      ToastManager.show(
        context: context,
        message: context.read<SystemSettingsBloc>().demoMessage,
        type: ToastType.info,
      );
      return;
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileBloc>().add(
        UpdateProfile(
          fullName: _fullNameController.text.trim(),
          address: _addressController.text.trim(),
          mobile: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          country: _countryController.text.trim(),
        ),
      );
    }
  }

  void _cancelEdit() {
    // Reload profile data to reset fields
    context.read<ProfileBloc>().add(const LoadProfile());
    setState(() {
      _isEditing = false;
    });
  }

  void _editProfilePicture() async {
    try {
      final bool isDemo = context.read<SystemSettingsBloc>().isDemo;
      if (isDemo) {
        ToastManager.show(
          context: context,
          message: context.read<SystemSettingsBloc>().demoMessage,
          type: ToastType.info,
        );
        return;
      }
      // Pick image from gallery or camera
      final file = await MediaPickerBottomSheet.show(context);

      if (file != null) {
        final fileName = file.path.split('/').last;

        // Show image preview dialog
        _showImagePreviewDialog(file, fileName);
      }
    } catch (e) {
      if (!mounted) return;
      ToastManager.show(
        context: context,
        message: context.tr('failedToPickImage', positionalArgs: [e.toString()]),
        type: ToastType.error,
      );
    }
  }

  void _showImagePreviewDialog(File imageFile, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: CustomText(
            text: context.tr('profilePicturePreview'),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image preview
              Container(
                width: 200.w,
                height: 200.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3), width: 2.w),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100.r),
                  child: Image.file(imageFile, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 16.h),
              CustomText(text: context.tr('file', positionalArgs: [fileName]), color: Colors.grey[600]),
              SizedBox(height: 8.h),
              CustomText(text: context.tr('useImageAsProfilePicture'), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: CustomText(text: context.tr('cancel'), color: Colors.grey[600]),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _uploadProfilePicture(imageFile);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white),
              child: CustomText(
                text: context.tr('useThisImage'),

                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  void _uploadProfilePicture(File imageFile) async {
    context.read<ProfileBloc>().add(UpdateProfile(profileImageFile: imageFile.path));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBar(
        title: context.tr('personalInformation'),
        showRefreshButton: false,
        showThemeToggle: false,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen:
            (previous, current) =>
                previous.fetchStatus != current.fetchStatus || previous.updateStatus != current.updateStatus,
        listener: (context, state) {
          if (state.fetchStatus == ApiStatus.success && state.updateStatus == ApiStatus.initial) {
            if (state.profile != null) _populateFields(state.profile!);
          } else if (state.updateStatus == ApiStatus.loading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state.updateStatus == ApiStatus.success) {
            setState(() {
              _isEditing = false;
              _isLoading = false;
            });
            if (state.profile != null) _populateFields(state.profile!);
            if (state.message.isNotEmpty) {
              ToastManager.show(context: context, message: state.message, type: ToastType.success);
            }
          } else if (state.updateStatus == ApiStatus.failed || state.fetchStatus == ApiStatus.failed) {
            setState(() {
              _isLoading = false;
            });
            if (state.message.isNotEmpty) {
              ToastManager.show(context: context, message: state.message, type: ToastType.error);
            }
          }
        },
        builder: (context, state) {
          return BlocBuilder<SystemSettingsBloc, SystemSettingsState>(
            builder: (context, settingState) {
              // Show content directly, handle loading states gracefully
              if (state.profile != null) {
                return _buildPersonalInfoContent(state.profile!);
              }

              if (state.fetchStatus == ApiStatus.failed) {
                return ErrorStateWidget(
                  onRetry: () {
                    context.read<ProfileBloc>().add(const LoadProfile());
                  },
                );
              }

              if (state.fetchStatus == ApiStatus.loading || state.updateStatus == ApiStatus.loading) {
                // Show content but with loading state
                return _buildPersonalInfoContent(ProfileModel()); // Empty profile for initial state
              }

              // Default case - show content
              return _buildPersonalInfoContent(state.profile ?? ProfileModel());
            },
          );
        },
      ),
    );
  }

  Widget _buildPersonalInfoContent(ProfileModel profile) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final bool isDemo = context.read<SystemSettingsBloc>().isDemo;
    // Check if profile data is available
    final hasProfileData = profile.deliveryBoy != null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(profile, isDarkTheme),
          SizedBox(height: 24.h),

          // Personal Information Form
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context.tr('personalDetails')),
                SizedBox(height: 16.h),

                // Full Name
                _buildInfoField(
                  label: context.tr('fullName'),
                  controller: _fullNameController,
                  icon: Icons.person_outline,
                  isEditing: _isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.tr('fullNameRequired');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Address
                _buildInfoField(
                  label: context.tr('address'),
                  controller: _addressController,
                  icon: Icons.location_on_outlined,
                  isEditing: _isEditing,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.tr('addressRequired');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),

                if (!_isEditing) ...[
                  _buildSectionTitle(context.tr('contactInformation')),
                  SizedBox(height: 16.h),

                  // Mobile Number
                  _buildInfoField(
                    label: context.tr('mobileNumber'),
                    controller: _mobileController,
                    icon: Icons.phone_outlined,
                    isEditing: false,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16.h),

                  // Email Address
                  _buildInfoField(
                    label: context.tr('emailAddress'),
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    isEditing: false,
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s')), LowerCaseTextFormatter()],
                  ),
                  SizedBox(height: 16.h),

                  // Country
                  _buildInfoField(
                    label: context.tr('country'),
                    controller: _countryController,
                    icon: Icons.public_outlined,
                    isEditing: false,
                  ),
                  SizedBox(height: 24.h),
                ],

                // Action Buttons
                if (_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: context.tr('cancel'),
                          onPressed: _cancelEdit,
                          backgroundColor: Colors.grey,
                          textColor: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: CustomButton(
                          text:
                              _isLoading
                                  ? context.tr('saving')
                                  : context.tr('saveChanges'),
                          onPressed: _isLoading ? null : _saveChanges,
                          backgroundColor: AppColors.primaryColor,
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text:
                          hasProfileData
                              ? context.tr('editInformation')
                              : context.tr('loading'),
                      onPressed: !isDemo && hasProfileData ? _toggleEdit : null,
                      backgroundColor: AppColors.primaryColor,
                      textColor: Colors.white,
                    ),
                  ),
                ],
                SizedBox(height: 50.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ProfileModel profile, bool isDarkTheme) {
    final hasProfileData = profile.deliveryBoy != null;
    final profilePictureUrl = profile.user?.profileImage;
    final bool isDemo = context.read<SystemSettingsBloc>().isDemo;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((isTablet() ? 10 : 16).w), // ↓ reduced from 20
      decoration: BoxDecoration(
        color: isDarkTheme ? AppColors.cardDarkColor : AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
          width: 1.2, // ↓ slightly thinner
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CustomAvatar(
                radius: 35.r, // ↓ from 40 (match reference)
                backgroundColor:
                    isDarkTheme
                        ? Theme.of(context).colorScheme.surface
                        : AppColors.primaryColor.withValues(alpha: 0.15),
                imageUrl: profilePictureUrl,
                fallbackIcon: Icon(
                  Icons.person,
                  size: 28.sp, // ↓ slightly reduced
                  color: AppColors.primaryColor,
                ),
              ),

              // Edit button
              if (_isEditing && !isDemo)
                Positioned(
                  bottom: 2.h, // tighter
                  right: 2.w,
                  child: GestureDetector(
                    onTap: _editProfilePicture,
                    child: Container(
                      padding: EdgeInsets.all((isTablet() ? 3 : 6).w), // ↓ from 8
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
                          width: 2.w, // ↓ from 3
                        ),
                      ),
                      child: Icon(Icons.edit, size: (isTablet() ? 6 : 10).sp, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(width: 12.w), // ↓ from 20 (important alignment fix)
          // Name + Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text:
                      hasProfileData
                          ? (profile.deliveryBoy!.fullName ?? context.tr('deliveryPartner'))
                          : context.tr('loading'),
                  fontSize: sz(16, seprateTabletSize: 12), // ↓ from 18.sp
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 6.h), // ↓ from 8
                // Status badge (matched to MorePage)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w, // ↓ from 14
                    vertical: 4.h, // ↓ from 7
                  ),
                  decoration: BoxDecoration(
                    color:
                        hasProfileData
                            ? (profile.deliveryBoy!.verificationStatus == 'verified' ? Colors.green : Colors.orange)
                                .withValues(alpha: isDarkTheme ? 0.3 : 0.15)
                            : Colors.grey.withValues(alpha: isDarkTheme ? 0.3 : 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      // ✅ added like reference
                      color: (hasProfileData
                              ? (profile.deliveryBoy!.verificationStatus == 'verified' ? Colors.green : Colors.orange)
                              : Colors.grey)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color:
                              hasProfileData
                                  ? (profile.deliveryBoy!.verificationStatus == 'verified'
                                      ? Colors.green
                                      : Colors.orange)
                                  : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      CustomText(
                        text:
                            hasProfileData
                                ? (profile.deliveryBoy!.verificationStatus?.toUpperCase() ??
                                    context.tr('pending').toUpperCase())
                                : context.tr('loading').toUpperCase(),
                        fontSize: sz(10, seprateTabletSize: 6), // ↓ from 10.sp
                        fontWeight: FontWeight.w600,
                        color:
                            hasProfileData
                                ? (profile.deliveryBoy!.verificationStatus == 'verified'
                                    ? (isDarkTheme ? Colors.green[300] : Colors.green[700])
                                    : (isDarkTheme ? Colors.orange[300] : Colors.orange[700]))
                                : (isDarkTheme ? Colors.grey[400] : Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomText(text: title, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface);
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool isCountryField = false,
    VoidCallback? onCountryTap,
  }) {
    final isEmpty = controller.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: label,
          fontSize: sz(12, seprateTabletSize: 9), // ↓ from 14.sp
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),

        SizedBox(height: 6.h), // ↓ from 8

        if (isEditing)
          CustomTextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType ?? TextInputType.text,
            inputFormatters: inputFormatters,
            validator: validator,
            prefixIcon: icon,
            borderRadius: 12.0.r,
            borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            focusedBorderColor: AppColors.primaryColor,

            // 🎯 Smart behavior switch
            readOnly: isCountryField,
            onTap: isCountryField ? onCountryTap : null,
            hintText: isCountryField ? context.tr('pleaseSelectACountry') : null,

            textInputAction: TextInputAction.next,
          )
        else
          CustomCard(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w, // better balance than all(10)
              vertical: 10.h,
            ),
            height: 48.h, // perfectly synced with your form fields
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 18.sp, // ↓ from 20
                ),

                SizedBox(width: 10.w), // ↓ from 12

                Expanded(
                  child: CustomText(
                    fontSize: sz(14, seprateTabletSize: 10), // ↓ from 16.sp

                    text: isEmpty ? context.tr('notProvided') : controller.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color:
                        isEmpty
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
