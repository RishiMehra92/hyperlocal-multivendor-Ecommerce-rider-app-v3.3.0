// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';

import 'dart:io';
import 'package:hyper_local/utils/widgets/media_picker_bottom_sheet.dart';
import '../../../../config/colors.dart';
import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_card.dart';
import '../../bloc/profile_bloc/profile_bloc.dart';
import '../../bloc/profile_bloc/profile_event.dart';
import '../../bloc/profile_bloc/profile_state.dart';
import '../../model/profile_model.dart';
import '../../../../utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/custom_dropdown.dart';

class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({super.key});

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleTypeController = TextEditingController();
  final _driverLicenseNumberController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  // Temporary lists that combine API images and newly selected files
  // Index 0: Front Side, Index 1: Back Side
  List<String?> _tempDriverLicenseImages = [null, null];
  List<String?> _tempVehicleRegistrationImages = [null, null];

  @override
  void initState() {
    super.initState();
    // Load profile data
    context.read<ProfileBloc>().add(const LoadProfile());

    // Populate fields immediately if profile is already loaded
    final profileState = context.read<ProfileBloc>().state;
    if (profileState.profile != null) {
      _populateFields(profileState.profile!);
    }
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _driverLicenseNumberController.dispose();
    super.dispose();
  }

  void _populateFields(ProfileModel profile) {
    if (profile.deliveryBoy != null) {
      _vehicleTypeController.text = profile.deliveryBoy!.vehicleType ?? '';
      _driverLicenseNumberController.text = profile.deliveryBoy!.driverLicenseNumber ?? '';

      // Populate temporary lists with API images
      _tempDriverLicenseImages = [null, null];
      final dlList = profile.deliveryBoy!.driverLicense?.toList() ?? [];
      if (dlList.isNotEmpty) _tempDriverLicenseImages[0] = dlList[0];
      if (dlList.length > 1) _tempDriverLicenseImages[1] = dlList[1];

      _tempVehicleRegistrationImages = [null, null];
      final vrList = profile.deliveryBoy!.vehicleRegistration?.toList() ?? [];
      if (vrList.isNotEmpty) _tempVehicleRegistrationImages[0] = vrList[0];
      if (vrList.length > 1) _tempVehicleRegistrationImages[1] = vrList[1];
    }
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
      setState(() {
        _isLoading = true;
      });

      context.read<ProfileBloc>().add(
        UpdateProfile(
          // Only pass the vehicle info fields we're updating
          driverLicenseNumber: _driverLicenseNumberController.text.trim(),
          vehicleType: _vehicleTypeController.text.trim(),
          // Include all non-null documents from temporary lists (API + newly selected)
          driverLicenseFiles: _tempDriverLicenseImages.whereType<String>().toList(),
          vehicleRegistrationFiles: _tempVehicleRegistrationImages.whereType<String>().toList(),
        ),
      );
    }
  }

  void _cancelEdit() {
    // Reload profile data to reset fields
    context.read<ProfileBloc>().add(const LoadProfile());
    setState(() {
      _isEditing = false;
      // Clear temporary lists
      _tempDriverLicenseImages = [null, null];
      _tempVehicleRegistrationImages = [null, null];
    });
  }

  /// Checks if the given path is a local file path
  bool _isLocalFile(String path) {
    return path.startsWith('/') || path.contains('\\') || (!path.startsWith('http://') && !path.startsWith('https://'));
  }

  Future<void> _pickAndUploadDocument(String documentType, int index) async {
    try {
      final file = await MediaPickerBottomSheet.show(context, allowFile: true);

      if (file != null) {
        final filePath = file.path;

        // Check file size (max 10MB)
        if (File(filePath).lengthSync() > 10 * 1024 * 1024) {
          ToastManager.show(
            context: context,
            message: context.tr('fileSizeLimit'),
            type: ToastType.error,
          );
          return;
        }

        setState(() {
          if (documentType == 'driver_license') {
            _tempDriverLicenseImages[index] = filePath;
          } else if (documentType == 'vehicle_registration') {
            _tempVehicleRegistrationImages[index] = filePath;
          }
        });
      }
    } catch (e) {
      ToastManager.show(context: context, message: 'Error picking file: $e', type: ToastType.error);
    }
  }

  void _removeSpecificImage(String documentType, int index) {
    setState(() {
      if (documentType == 'driver_license') {
        _tempDriverLicenseImages[index] = null;
      } else if (documentType == 'vehicle_registration') {
        _tempVehicleRegistrationImages[index] = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBar(
        title: context.tr('vehicleInformation'),
        showRefreshButton: false,
        showThemeToggle: false,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen:
            (previous, current) =>
                previous.fetchStatus != current.fetchStatus ||
                previous.updateStatus != current.updateStatus ||
                previous.documentUploadStatus != current.documentUploadStatus,
        listener: (context, state) {
          if (state.fetchStatus == ApiStatus.success &&
              state.updateStatus == ApiStatus.initial &&
              state.documentUploadStatus == ApiStatus.initial) {
            if (state.profile != null) _populateFields(state.profile!);
          } else if (state.updateStatus == ApiStatus.success) {
            if (state.profile != null) _populateFields(state.profile!);
            setState(() {
              _isEditing = false;
              _isLoading = false;
            });
            if (state.message.isNotEmpty) {
              ToastManager.show(context: context, message: state.message, type: ToastType.success);
            }
          } else if (state.documentUploadStatus == ApiStatus.loading) {
            setState(() {
              _isLoading = true;
            });
            if (state.documentType.isNotEmpty) {
              ToastManager.show(
                context: context,
                message: context.tr('uploadingDocumentProgress', positionalArgs: [state.documentType.replaceAll('_', ' ')]),
                type: ToastType.info,
              );
            }
          } else if (state.documentUploadStatus == ApiStatus.success) {
            setState(() {
              _isLoading = false;
            });
            if (state.documentType.isNotEmpty) {
              ToastManager.show(
                context: context,
                message: context.tr('documentUploadedSuccess', positionalArgs: [state.documentType.replaceAll('_', ' ')]),
                type: ToastType.success,
              );
            }
            context.read<ProfileBloc>().add(const LoadProfile());
          } else if (state.fetchStatus == ApiStatus.failed ||
              state.updateStatus == ApiStatus.failed ||
              state.documentUploadStatus == ApiStatus.failed) {
            setState(() {
              _isLoading = false;
            });
            if (state.message.isNotEmpty) {
              ToastManager.show(context: context, message: state.message, type: ToastType.error);
            }
          }
        },
        builder: (context, state) {
          if (state.profile != null) {
            return _buildVehicleInfoContent(state.profile!);
          }
          if (state.fetchStatus == ApiStatus.failed) {
            return ErrorStateWidget(
              onRetry: () {
                context.read<ProfileBloc>().add(const LoadProfile());
              },
            );
          }
          return _buildVehicleInfoContent(state.profile ?? ProfileModel());
        },
      ),
    );
  }

  Widget _buildVehicleInfoContent(ProfileModel profile) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Header
          _buildVehicleHeader(profile, isDarkTheme),
          SizedBox(height: 16.h),

          // Verification Remarks Card
          if (profile.deliveryBoy?.verificationRemark != null &&
              profile.deliveryBoy!.verificationRemark!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: context.tr('verificationRemarks'),
                          fontWeight: FontWeight.bold,
                          fontSize: sz(13, seprateTabletSize: 10),
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          text: profile.deliveryBoy!.verificationRemark!,
                          fontSize: sz(12, seprateTabletSize: 9),
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Account Status Card (if inactive)
          if (profile.deliveryBoy?.status != 'active') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: context.tr('accountStatus'),
                          fontWeight: FontWeight.bold,
                          fontSize: sz(13, seprateTabletSize: 10),
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          text:
                              'Your account is currently ${profile.deliveryBoy?.status ?? 'inactive'}. Please contact support for assistance.',
                          fontSize: sz(12, seprateTabletSize: 9),
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Vehicle Information Form
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context.tr('vehicleDetails')),
                SizedBox(height: 16.h),

                // Vehicle Type
                _buildVehicleTypeField(isEditing: _isEditing),
                SizedBox(height: 16.h),

                // Driver License Number
                _buildInfoField(
                  label: context.tr('driverLicenseNumber'),
                  controller: _driverLicenseNumberController,
                  icon: Icons.drive_file_rename_outline,
                  isEditing: _isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.tr('driverLicenseRequired');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),

                // Documents
                _buildSectionTitle(context.tr('vehicleDocuments')),
                SizedBox(height: 16.h),

                _buildDocumentField(
                  title: context.tr('driverLicense'),
                  documentType: 'driver_license',
                  tempImages: _tempDriverLicenseImages,
                  icon: Icons.credit_card,
                  color: AppColors.primaryColor,
                  verificationStatus: profile.deliveryBoy?.verificationStatus,
                ),
                SizedBox(height: 16.h),

                _buildDocumentField(
                  title: context.tr('vehicleRegistration'),
                  documentType: 'vehicle_registration',
                  tempImages: _tempVehicleRegistrationImages,
                  icon: Icons.description_outlined,
                  color: AppColors.primaryColor,
                  verificationStatus: profile.deliveryBoy?.verificationStatus,
                ),
                SizedBox(height: 24.h),

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
                      text: context.tr('editInformation'),
                      onPressed: _toggleEdit,
                      backgroundColor: AppColors.primaryColor,
                      textColor: Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleHeader(ProfileModel profile, bool isDarkTheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((isTablet() ? 10 : 20).w),
      decoration: BoxDecoration(
        color: isDarkTheme ? AppColors.cardDarkColor : AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          // Bike Icon Avatar (Left)
          CircleAvatar(
            radius: 35.r,
            backgroundColor:
                isDarkTheme ? Theme.of(context).colorScheme.surface : AppColors.primaryColor.withValues(alpha: 0.15),
            child: Icon(Icons.directions_bike, size: (isTablet() ? 22 : 30).sp, color: AppColors.primaryColor),
          ),

          SizedBox(width: 12.w),

          // Vehicle Type + Verification Status (Right)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vehicle Type / Title
                CustomText(
                  text: profile.deliveryBoy?.vehicleType ?? context.tr('vehicleInformation'),
                  fontSize: sz(16, seprateTabletSize: 12),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 8.h),

                // Verification Status Badge
                Builder(
                  builder: (context) {
                    final status = profile.deliveryBoy?.verificationStatus?.toLowerCase() ?? 'pending';
                    Color statusColor;
                    Color textColor;
                    if (status == 'verified') {
                      statusColor = Colors.green;
                      textColor = isDarkTheme ? Colors.green[300]! : Colors.green[700]!;
                    } else if (status == 'rejected') {
                      statusColor = Colors.red;
                      textColor = isDarkTheme ? Colors.red[300]! : Colors.red[700]!;
                    } else {
                      statusColor = Colors.orange;
                      textColor = isDarkTheme ? Colors.orange[300]! : Colors.orange[700]!;
                    }

                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: isDarkTheme ? 0.3 : 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: CustomText(
                        text:
                            profile.deliveryBoy?.verificationStatus?.toUpperCase() ??
                            context.tr('pending').toUpperCase(),
                        fontSize: sz(10, seprateTabletSize: 6),
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return CustomText(
      text: title,
      fontSize: sz(12, seprateTabletSize: 9),
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: label,
          fontSize: sz(12, seprateTabletSize: 9),
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        SizedBox(height: 6.h),
        if (isEditing) ...[
          CustomTextFormField(
            controller: controller,
            validator: validator,
            prefixIcon: icon,
            borderRadius: 12.0.r,
            borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            focusedBorderColor: AppColors.primaryColor,
          ),
        ] else ...[
          CustomCard(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            height: 48.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primaryColor, size: 18.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: CustomText(
                    text: controller.text.isEmpty ? context.tr('notProvided') : controller.text,
                    fontSize: sz(14, seprateTabletSize: 10),
                    color:
                        controller.text.isEmpty
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.onSurface,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentField({
    required String title,
    required String documentType,
    required List<String?> tempImages,
    required IconData icon,
    required Color color,
    String? verificationStatus,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: title,
                      fontSize: sz(16, seprateTabletSize: 11),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    if (verificationStatus != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (verificationStatus == 'verified'
                                  ? Colors.green
                                  : (verificationStatus == 'rejected' ? Colors.red : Colors.orange))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomText(
                          text: verificationStatus.toUpperCase(),
                          fontSize: sz(10, seprateTabletSize: 6),
                          fontWeight: FontWeight.bold,
                          color:
                              verificationStatus == 'verified'
                                  ? Colors.green
                                  : (verificationStatus == 'rejected' ? Colors.red : Colors.orange),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDocumentBox(
                label: context.tr('frontSide'),
                imageUrl: tempImages[0],
                onUpload: () => _pickAndUploadDocument(documentType, 0),
                onRemove: () => _removeSpecificImage(documentType, 0),
                isEditing: _isEditing,
              ),
              const SizedBox(width: 16),
              _buildDocumentBox(
                label: context.tr('backSide'),
                imageUrl: tempImages[1],
                onUpload: () => _pickAndUploadDocument(documentType, 1),
                onRemove: () => _removeSpecificImage(documentType, 1),
                isEditing: _isEditing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentBox({
    required String label,
    required String? imageUrl,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
    required bool isEditing,
  }) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: label,
            fontSize: sz(12, seprateTabletSize: 9),
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          SizedBox(height: 8.h),
          AspectRatio(
            aspectRatio: 1.5,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkTheme ? AppColors.cardDarkColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Stack(
                children: [
                  if (hasImage) ...[
                    GestureDetector(
                      onTap: () => _openFullScreenImage(imageUrl),
                      child: Builder(
                        builder: (context) {
                          final path = imageUrl.toLowerCase();
                          final isPdf = path.endsWith('.pdf');
                          final isDoc = path.endsWith('.doc') || path.endsWith('.docx');

                          if (isPdf || isDoc) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isPdf ? Icons.picture_as_pdf : Icons.description,
                                      size: 32.sp,
                                      color: isPdf ? Colors.red : Colors.blue,
                                    ),
                                    SizedBox(height: 4.h),
                                    CustomText(
                                      text:
                                          _isLocalFile(imageUrl)
                                              ? imageUrl.split('/').last
                                              : context.tr('fileSource'),
                                      fontSize: 10,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child:
                                _isLocalFile(imageUrl)
                                    ? Image.file(
                                      File(imageUrl),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                    : CustomImageContainer(
                                      imagePath: imageUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                          );
                        },
                      ),
                    ),

                    if (isEditing)
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
                        onTap: isEditing ? onUpload : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: isEditing ? AppColors.primaryColor : Colors.grey,
                              size: 28.sp,
                            ),
                            SizedBox(height: 8.h),
                            CustomText(
                              text:
                                  isEditing
                                      ? context.tr('uploadDocument')
                                      : context.tr('notProvided'),
                              fontSize: sz(11, seprateTabletSize: 8),
                              color: isEditing ? AppColors.primaryColor : Colors.grey,
                            ),
                          ],
                        ),
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

  Widget _buildVehicleTypeField({required bool isEditing}) {
    final label = context.tr('vehicleType');
    const icon = Icons.directions_car_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: label,
          fontSize: sz(12, seprateTabletSize: 9),
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        SizedBox(height: 6.h),
        if (isEditing) ...[
          CustomDropdownFormField<String>(
            hintText: context.tr('selectVehicleType'),
            prefixIcon: icon,
            borderRadius: 12.0.r,
            value:
                ['car', 'bike'].contains(_vehicleTypeController.text.toLowerCase())
                    ? _vehicleTypeController.text.toLowerCase()
                    : null,
            items: const [
              DropdownMenuItem(value: 'car', child: Text('Car')),
              DropdownMenuItem(value: 'bike', child: Text('Bike')),
            ],
            onChanged: (value) {
              if (value != null) {
                _vehicleTypeController.text = value;
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('pleaseSelectVehicleType');
              }
              return null;
            },
          ),
        ] else ...[
          CustomCard(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            height: 48.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primaryColor, size: 18.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: CustomText(
                    text: _vehicleTypeController.text.toUpperCase(),
                    fontSize: sz(14, seprateTabletSize: 11),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _openFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child:
                    _isLocalFile(imageUrl)
                        ? Image.file(
                          File(imageUrl),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        )
                        : CustomImageContainer(
                          imagePath: imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
              ),
              Positioned(
                top: 40.h,
                right: 30.w,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),

                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
