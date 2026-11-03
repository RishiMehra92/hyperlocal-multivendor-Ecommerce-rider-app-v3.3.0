import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import '../../../../config/colors.dart';
import '../../../../config/helper.dart';
import '../../../../utils/currency_formatter.dart';
import '../../../../utils/widgets/custom_button.dart';
import '../../../../utils/widgets/custom_dropdown.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../model/available_orders.dart';
import '../../services/dialog_service.dart';

class CancelDeliverySheet extends StatefulWidget {
  final List<Items> items;
  final Future<String?> Function(
    List<int> itemIds,
    String reasonCode,
    String? note,
  )
  onSubmit;

  const CancelDeliverySheet({
    super.key,
    required this.items,
    required this.onSubmit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required List<Items> items,
    required Future<String?> Function(
      List<int> itemIds,
      String reasonCode,
      String? note,
    )
    onSubmit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return CancelDeliverySheet(items: items, onSubmit: onSubmit);
      },
    );
  }

  @override
  State<CancelDeliverySheet> createState() => _CancelDeliverySheetState();
}

class _CancelDeliverySheetState extends State<CancelDeliverySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Set<int> _selectedIds = {};
  final TextEditingController _remarkController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(
      widget.items.where((i) => i.id != null).map((i) => i.id!),
    );
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_selectedIds.isEmpty) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
    });

    final remark = _remarkController.text.trim();
    final error = await widget.onSubmit(
      _selectedIds.toList(),
      _selectedReason!,
      remark.isEmpty ? null : remark,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (error == null) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    return PopScope(
      canPop: !_isSubmitting,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: AbsorbPointer(
            absorbing: _isSubmitting,
            child: Padding(
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHandle(),
                  _buildHeader(theme),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        (isTablet() ? 20 : 16).w,
                        16.h,
                        (isTablet() ? 20 : 16).w,
                        16.h,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildExplainer(theme),
                            SizedBox(height: 16.h),
                            ..._buildItemRows(theme),
                            SizedBox(height: 16.h),
                            _buildReasonField(),
                            SizedBox(height: 12.h),
                            _buildRemarkField(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: EdgeInsets.only(top: 10.h, bottom: 6.h),
      child: Center(
        child: Container(
          width: 40.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        (isTablet() ? 20 : 16).w,
        8.h,
        (isTablet() ? 12 : 8).w,
        12.h,
      ),
      child: Row(
        children: [
          Icon(
            Icons.cancel_outlined,
            color: AppColors.errorColor,
            size: sz(22, seprateTabletSize: 18).sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: CustomText(
              text: context.tr('cancelDelivery'),
              fontSize: sz(18, seprateTabletSize: 14),
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              size: sz(22, seprateTabletSize: 18).sp,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildExplainer(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.errorColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: sz(18, seprateTabletSize: 14).sp,
            color: AppColors.errorColor,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: CustomText(
              text: context.tr('cancelDeliveryExplanation'),
              fontSize: sz(12, seprateTabletSize: 10),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItemRows(ThemeData theme) {
    return widget.items.map((item) {
      final id = item.id;
      final isSelected = id != null && _selectedIds.contains(id);
      return Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.errorColor.withValues(alpha: 0.06)
                    : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color:
                  isSelected
                      ? AppColors.errorColor.withValues(alpha: 0.5)
                      : theme.colorScheme.outline.withValues(alpha: 0.15),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              CustomImageContainer(
                width: (isTablet() ? 36 : 44).w,
                height: (isTablet() ? 36 : 44).h,
                imagePath: item.product?.image ?? '',
                backgroundColor: Colors.blue[100],
                borderRadius: BorderRadius.circular(8.r),
                errorWidget: Center(
                  child: Icon(
                    Icons.shopping_bag,
                    color: Colors.blue,
                    size: sz(18, seprateTabletSize: 14).sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: item.title ?? 'Item',
                      fontSize: sz(14, seprateTabletSize: 11),
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      color: theme.colorScheme.onSurface,
                    ),
                    SizedBox(height: 2.h),
                    CustomText(
                      text:
                          'Qty: ${item.quantity ?? 1}  ·  ${CurrencyFormatter.formatAmount(context, item.price ?? '0')}',
                      fontSize: sz(12, seprateTabletSize: 9),
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildReasonField() {
    return CustomDropdownFormField<String>(
      labelText: context.tr('reasonRequired'),
      hintText: context.tr('selectAReason'),
      value: _selectedReason,
      enabled: !_isSubmitting,
      items:
          DialogService.deliveryFailureReasons
              .map(
                (reason) => DropdownMenuItem<String>(
                  value: reason,
                  child: Text(
                    DialogService.deliveryFailureReasonLabels[reason] ?? reason,
                  ),
                ),
              )
              .toList(),
      onChanged: (value) {
        setState(() {
          _selectedReason = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Reason is required';
        }
        return null;
      },
    );
  }

  Widget _buildRemarkField() {
    return TextFormField(
      controller: _remarkController,
      enabled: !_isSubmitting,
      minLines: 3,
      maxLines: 5,
      maxLength: 250,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        labelText: context.tr('remarksOptional'),
        hintText: context.tr('addAnyAdditionalContext'),
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        counterText: '',
      ),
    );
  }

  Widget _buildFooter() {
    final canSubmit = !_isSubmitting && _selectedIds.isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        (isTablet() ? 20 : 16).w,
        12.h,
        (isTablet() ? 20 : 16).w,
        12.h,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: (isTablet() ? 10 : 14).h,
                ),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: CustomText(
                text: context.tr('back'),
                fontSize: sz(14, seprateTabletSize: 11),
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: context.tr('confirmCancellation'),
              onPressed: canSubmit ? _submit : null,
              isLoading: _isSubmitting,
              backgroundColor: AppColors.errorColor,
              textColor: Colors.white,
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: (isTablet() ? 10 : 12).h),
              textStyle: TextStyle(
                fontSize: sz(14, seprateTabletSize: 11).sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
