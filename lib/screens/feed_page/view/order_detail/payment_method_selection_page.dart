import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import '../../bloc/order_details_bloc/order_details_bloc.dart';
import '../../bloc/order_details_bloc/order_details_event.dart';
import '../../bloc/order_details_bloc/order_details_state.dart';

class PaymentMethodSelectionPage extends StatefulWidget {
  final int orderId;
  final String? paymentUrl;
  final bool canPayOnline;
  final String codAmount;

  const PaymentMethodSelectionPage({
    super.key,
    required this.orderId,
    this.paymentUrl,
    required this.canPayOnline,
    required this.codAmount,
  });

  @override
  State<PaymentMethodSelectionPage> createState() =>
      _PaymentMethodSelectionPageState();
}

class _PaymentMethodSelectionPageState
    extends State<PaymentMethodSelectionPage> {
  late String _selectedMethod;
  Timer? _pollingTimer;
  bool _isCashCollected = false;

  @override
  void initState() {
    super.initState();
    // Default to 'upi' if online payment is allowed and payment url is available, else fallback to 'cod'
    _selectedMethod =
        (widget.canPayOnline && widget.paymentUrl != null) ? 'upi' : 'cod';
    if (_selectedMethod == 'upi') {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Dispatch check status event to the Bloc every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      context.read<OrderDetailsBloc>().add(CheckPaymentStatus(widget.orderId));
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
  }

  void _selectMethod(String method) {
    if (_selectedMethod == method) return;
    setState(() {
      _selectedMethod = method;
      if (method != 'cod') {
        _isCashCollected = false;
      }
    });

    if (method == 'upi') {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<OrderDetailsBloc, OrderDetailsState>(
      listener: (context, state) {
        if (state.status == ApiStatus.success && state.order != null) {
          final isCodPaidOnline = state.order!.isCodPaidOnline == true;
          final paymentStatus = state.order!.paymentStatus?.toLowerCase();

          if (isCodPaidOnline || paymentStatus == 'completed') {
            _stopPolling();
            Navigator.pop(context, 'online_completed');
          }
        }
      },
      child: CustomScaffold(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        appBar: CustomAppBar(title: context.tr('paymentCollection')),
        body: BlocBuilder<OrderDetailsBloc, OrderDetailsState>(
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: context.tr('selectPaymentMethod'),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        SizedBox(height: 4.h),
                        CustomText(
                          text: context.tr('selectPaymentMethodSubtitle'),
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        SizedBox(height: 24.h),

                        // UPI Option Card
                        if (widget.canPayOnline &&
                            widget.paymentUrl != null) ...[
                          _buildPaymentOptionCard(
                            id: 'upi',
                            title: context.tr('onlinePayment'),
                            subtitle: context.tr('onlinePaymentSubtitle'),
                            icon: Icons.qr_code_2,
                            isSelected: _selectedMethod == 'upi',
                            isDark: isDark,
                          ),
                          SizedBox(height: 16.h),
                        ],

                        // COD Option Card
                        _buildPaymentOptionCard(
                          id: 'cod',
                          title: context.tr('cashOnDelivery'),
                          subtitle: context.tr('cashOnDeliverySubtitle'),
                          icon: Icons.payments_outlined,
                          isSelected: _selectedMethod == 'cod',
                          isDark: isDark,
                        ),

                        if (_selectedMethod == 'cod') ...[
                          SizedBox(height: 16.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isCashCollected = !_isCashCollected;
                                });
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 24.w,
                                      height: 24.h,
                                      child: Checkbox(
                                        value: _isCashCollected,
                                        onChanged: (value) {
                                          setState(() {
                                            _isCashCollected = value ?? false;
                                          });
                                        },
                                        activeColor: AppColors.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4.r,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    CustomText(
                                      text:
                                          '${context.tr('cashCollect')}: ${widget.codAmount}',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        // QR Code Display Section (when UPI is selected)
                        if (_selectedMethod == 'upi' &&
                            widget.paymentUrl != null) ...[
                          SizedBox(height: 32.h),
                          Center(
                            child: CustomCard(
                              padding: EdgeInsets.all(20.w),
                              backgroundColor:
                                  isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                              border: Border.all(
                                color:
                                    isDark
                                        ? Colors.grey[800]!
                                        : Colors.grey[200]!,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    text: context.tr('scanToPayOnline'),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                  SizedBox(height: 16.h),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Container(
                                      width: 200.w,
                                      height: 200.h,
                                      color: Colors.white,
                                      padding: EdgeInsets.all(12.w),
                                      child: QrImageView(
                                        data: widget.paymentUrl!,
                                        version: QrVersions.auto,
                                        size: 200.w,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Colors.black,
                                        ),
                                        dataModuleStyle:
                                            const QrDataModuleStyle(
                                              dataModuleShape:
                                                  QrDataModuleShape.square,
                                              color: Colors.black,
                                            ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 14.w,
                                        height: 14.h,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                isDark
                                                    ? Colors.grey[400]!
                                                    : Colors.grey[600]!,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      CustomText(
                                        text: context.tr('waitingForPayment'),
                                        fontSize: 12,
                                        color:
                                            isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),

                                  // Warning Box UI
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 12.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.red[700],
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: CustomText(
                                            text: context.tr('paymentWarning'),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red[700],
                                            textAlign: TextAlign.left,
                                            maxLines: 4,
                                          ),
                                        ),
                                      ],
                                    ),
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

                // Done Button Container (only shown for COD)
                if (_selectedMethod == 'cod')
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isCashCollected
                                  ? AppColors.primaryColor
                                  : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: _isCashCollected ? 2 : 0,
                          shadowColor:
                              _isCashCollected
                                  ? AppColors.primaryColor.withValues(
                                    alpha: 0.3,
                                  )
                                  : Colors.transparent,
                        ),
                        onPressed:
                            _isCashCollected
                                ? () {
                                  context.read<OrderDetailsBloc>().add(
                                    CancelPaymentLink(widget.orderId),
                                  );
                                  Navigator.pop(context, 'cod');
                                }
                                : null,
                        child: CustomText(
                          text: context.tr('done'),
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentOptionCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
  }) {
    return CustomCard(
      onTap: () => _selectMethod(id),
      padding: EdgeInsets.all(16.w),
      backgroundColor:
          isSelected
              ? (isDark
                  ? AppColors.primaryColor.withValues(alpha: 0.15)
                  : AppColors.primaryColor.withValues(alpha: 0.06))
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      border: Border.all(
        color:
            isSelected
                ? AppColors.primaryColor
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
        width: isSelected ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color:
              isSelected
                  ? AppColors.primaryColor.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? AppColors.primaryColor.withValues(alpha: 0.1)
                      : (isDark ? Colors.grey[800] : Colors.grey[100]),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color:
                  isSelected
                      ? AppColors.primaryColor
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: subtitle,
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            width: 22.w,
            height: 22.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primaryColor : Colors.grey[400]!,
                width: 2,
              ),
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
            ),
            child:
                isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 14.sp)
                    : null,
          ),
        ],
      ),
    );
  }
}
