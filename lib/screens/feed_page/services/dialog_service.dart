import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:confetti/confetti.dart';
import 'package:hyper_local/utils/widgets/custom_pin_field.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/custom_button.dart';
import '../../../utils/widgets/custom_bottom_sheet.dart';
import '../../../utils/currency_formatter.dart';
import '../../../config/colors.dart';
import '../../../utils/widgets/toast_message.dart';
import '../model/available_orders.dart';

class DialogService {
  static const List<String> deliveryFailureReasons = [
    'customer_unavailable',
    'customer_refused',
    'wrong_address',
    'unsafe_location',
  ];

  static const Map<String, String> deliveryFailureReasonLabels = {
    'customer_unavailable': 'Customer unavailable',
    'customer_refused': 'Customer refused delivery',
    'wrong_address': 'Wrong address',
    'unsafe_location': 'Unsafe location',
  };

  static void showCodPopup(BuildContext context, Orders? order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.money, color: Colors.green),
              SizedBox(width: 8.w),
              CustomText(
                text: context.tr('cashOnDelivery'),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(text: context.tr('pleaseCollectCash')),
              SizedBox(height: 16.h),
              CustomText(
                text:
                    '${context.tr('amount')}: ${CurrencyFormatter.formatAmount(context, order?.finalTotal ?? '0')}',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: CustomText(
                text: context.tr('ok'),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  static void showEarningsPopup(
    BuildContext context,
    Orders? order,
    ConfettiController confettiController,
    bool hasShownConfetti,
    VoidCallback onClose,
  ) {
    // Show confetti only if it hasn't been shown for this order yet
    if (!hasShownConfetti) {
      confettiController.play();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 64.sp),
                SizedBox(height: 16.h),
                CustomText(
                  text: context.tr('orderCompleted'),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                CustomText(
                  text: context.tr('congratulations'),
                  color: Colors.grey[600],
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    children: [
                      CustomText(
                        text:
                            context.tr('yourEarningsBreakdown'),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      SizedBox(height: 12.h),
                      // Breakdown details
                      if (order?.earnings?.breakdown != null) ...[
                        _buildBreakdownRow(
                          context,
                          context.tr('baseFee'),
                          order?.earnings?.breakdown?.baseFee,
                        ),
                        _buildBreakdownRow(
                          context,
                          context.tr('storePickupFee'),
                          order?.earnings?.breakdown?.perStorePickupFee,
                        ),
                        _buildBreakdownRow(
                          context,
                          context.tr('distanceFee'),
                          order?.earnings?.breakdown?.distanceBasedFee,
                        ),
                        _buildBreakdownRow(
                          context,
                          context.tr('orderIncentive'),
                          order?.earnings?.breakdown?.perOrderIncentive,
                        ),
                        const Divider(),
                        _buildBreakdownRow(
                          context,
                          context.tr('totalEarnings'),
                          _calculateTotalEarnings(order?.earnings?.breakdown),
                          isTotal: true,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onClose();
                        },
                        text: context.tr('goToHome'),
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildBreakdownRow(
    BuildContext context,
    String label,
    double? amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: label,
            color: isTotal ? AppColors.primaryColor : Colors.grey[600],
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
          CustomText(
            text: CurrencyFormatter.formatAmount(
              context,
              amount?.toString() ?? '0',
            ),
            color: isTotal ? AppColors.primaryColor : Colors.grey[600],
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ],
      ),
    );
  }

  static double? _calculateTotalEarnings(EarningsBreakdown? breakdown) {
    if (breakdown == null) return null;

    double total = 0.0;
    if (breakdown.baseFee != null) total += breakdown.baseFee!;
    if (breakdown.perStorePickupFee != null) {
      total += breakdown.perStorePickupFee!;
    }
    if (breakdown.distanceBasedFee != null) {
      total += breakdown.distanceBasedFee!;
    }
    if (breakdown.perOrderIncentive != null) {
      total += breakdown.perOrderIncentive!;
    }

    return total;
  }

  static Future<String?> showDeliveryOtpDialog(BuildContext context) async {
    String? errorMessage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otpController = TextEditingController();

    final String? result = await CustomBottomSheet.show<String>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 20.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomText(
                  text: context.tr('deliveryOtpRequired'),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                CustomText(
                  text:
                      context.tr('pleaseEnterOtpFromCustomer'),
                  fontSize: 13,
                  color: Colors.grey[500],
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: PinFieldAuto(
                    controller: otpController,
                    gapSpace: 5,
                    fontSize: 18,
                    onCodeChanged: (code) {
                      setState(() {
                        errorMessage = null; // Clear error when user types
                      });
                    },
                  ),
                ),
                if (errorMessage != null) ...[
                  SizedBox(height: 8.h),
                  CustomText(
                    text: errorMessage!,
                    color: Colors.red,
                    fontSize: 12,
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        textStyle: const TextStyle(color: Colors.red),
                        text: context.tr('cancel'),
                        backgroundColor:
                            isDark ? Colors.grey[800] : Colors.grey[200],
                        onPressed: () => Navigator.of(context).pop(null),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: CustomButton(
                        text: context.tr('verifyOtp'),
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.white,
                        onPressed: () {
                          final enteredOtp = otpController.text;
                          if (enteredOtp.isEmpty || enteredOtp.length < 6) {
                            setState(() {
                              errorMessage =
                                  context.tr('pleaseEnterValidOtp');
                            });
                            return; // Don't close dialog, show error
                          }
                          Navigator.of(context).pop(enteredOtp);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return result;
  }

  static Future<void> showCustomerOtpDialog(
    BuildContext context,
    Orders? order,
  ) async {
    // Check if any item requires OTP
    bool requiresOtp = false;
    if (order?.items != null) {
      for (var item in order!.items!) {
        if (item.product?.requiresOtp == 1) {
          requiresOtp = true;
          break;
        }
      }
    }

    if (!requiresOtp) {
      // No OTP required, proceed with delivery
      return;
    }

    String? errorMessage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otpController = TextEditingController();

    final String? result = await CustomBottomSheet.show<String>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 20.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 50.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                CustomText(
                  text: context.tr('customerOtpRequired'),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                CustomText(
                  text:
                      context.tr('pleaseEnterOtpFromCustomer'),
                  fontSize: 13,
                  color: Colors.grey[500],
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                CustomText(
                  text:
                      order?.shippingName ??
                      context.tr('customer'),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: PinFieldAuto(
                    controller: otpController,
                    gapSpace: 8.w,
                    fontSize: 18,
                    onCodeChanged: (code) {
                      setState(() {
                        errorMessage = null;
                      });
                    },
                  ),
                ),
                if (errorMessage != null) ...[
                  SizedBox(height: 8.h),
                  CustomText(
                    text: errorMessage!,
                    color: Colors.red,
                    fontSize: 12,
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: context.tr('cancel'),
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        onPressed: () => Navigator.of(context).pop(null),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: CustomButton(
                        text: context.tr('verifyAndDeliver'),
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.white,
                        onPressed: () {
                          final enteredOtp = otpController.text;
                          if (enteredOtp.length == 6) {
                            Navigator.pop(context, enteredOtp);
                          } else {
                            setState(() {
                              errorMessage =
                                  context.tr('pleaseEnterValidOtp');
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      // For now, show success message
      ToastManager.show(
        context: context,
        message: context.tr('otpVerifiedSuccessfully'),
        type: ToastType.success,
      );
    }
  }

  static Future<bool?> showCancelOrderDialog({
    required BuildContext context,
    required Future<String?> Function(String reason) onSubmit,
  }) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    bool isSubmitting = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              if (isSubmitting || !formKey.currentState!.validate()) return;

              setState(() {
                isSubmitting = true;
              });

              final error = await onSubmit(controller.text.trim());

              if (!dialogContext.mounted) return;

              setState(() {
                isSubmitting = false;
              });

              if (error == null) {
                Navigator.of(dialogContext).pop(true);
              }
            }

            return PopScope(
              canPop: !isSubmitting,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                title: CustomText(
                  text: context.tr('cancelOrder'),
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text:
                            context.tr('cancelOrderReturnToStore'),
                      ),
                      SizedBox(height: 16.h),
                      TextFormField(
                        controller: controller,
                        enabled: !isSubmitting,
                        minLines: 3,
                        maxLines: 5,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText:
                              context.tr('reasonRequired'),
                          alignLabelWithHint: true,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('reasonIsRequiredError');
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        isSubmitting
                            ? null
                            : () => Navigator.of(dialogContext).pop(false),
                    child: CustomText(
                      text: context.tr('cancel'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : submit,
                    child:
                        isSubmitting
                            ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                            : CustomText(
                              text: context.tr('submit'),
                              color: Colors.white,
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
