import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';

import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';

import 'package:hyper_local/utils/widgets/loading_widget.dart';

import '../../system_settings/bloc/system_settings_bloc.dart';
import '../../system_settings/bloc/system_settings_event.dart';
import '../../system_settings/bloc/system_settings_state.dart';
import 'package:hyper_local/config/helper.dart';

class TermsPrivacyPage extends StatefulWidget {
  final bool isTerms;

  const TermsPrivacyPage({super.key, required this.isTerms});

  @override
  State<TermsPrivacyPage> createState() => _TermsPrivacyPageState();
}

class _TermsPrivacyPageState extends State<TermsPrivacyPage> {
  @override
  void initState() {
    super.initState();
    context.read<SystemSettingsBloc>().add(FetchDeliveryBoySettings());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemSettingsBloc, SystemSettingsState>(
      builder: (context, state) {
        return CustomScaffold(
          appBar: CustomAppBar(
            title:
                widget.isTerms
                    ? context.tr('termsOfService')
                    : context.tr('privacyPolicy'),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SystemSettingsState state) {
    if (state.fetchStatus == ApiStatus.loading) {
      return const Center(child: LoadingWidget());
    }

    if (state.fetchStatus == ApiStatus.failed) {
      return ErrorStateWidget(
        onRetry: () {
          context.read<SystemSettingsBloc>().add(FetchDeliveryBoySettings());
        },
      );
    }

    if (state.fetchStatus == ApiStatus.success && state.settings != null) {
      final settings = state.settings!;

      final content =
          widget.isTerms ? settings.termsCondition : settings.privacyPolicy;

      if (content == null || content.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
              SizedBox(height: 16.h),
              CustomText(
                text: context.tr('noContentFound'),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(8.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content
            Html(
              data: content,
              style: {
                "body": Style(
                  fontSize: FontSize(16.sp),
                  lineHeight: const LineHeight(1.6),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                "h1": Style(
                  fontSize: FontSize(24.sp),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                  margin: Margins.only(bottom: 16.h),
                ),
                "h2": Style(
                  fontSize: FontSize(20.sp),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                  margin: Margins.only(top: 24.h, bottom: 12.h),
                ),
                "h3": Style(
                  fontSize: FontSize(18.sp),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  margin: Margins.only(top: 20.h, bottom: 10.h),
                ),
                "p": Style(
                  fontSize: FontSize(16.sp),
                  margin: Margins.only(bottom: 12.h),
                  lineHeight: const LineHeight(1.6),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                "ul": Style(margin: Margins.only(bottom: 16.h, left: 16.w)),
                "li": Style(
                  fontSize: FontSize(16.sp),
                  margin: Margins.only(bottom: 8.h),
                  lineHeight: const LineHeight(1.6),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                "strong": Style(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                "a": Style(
                  color: AppColors.primaryColor,
                  textDecoration: TextDecoration.underline,
                ),
              },
            ),

            SizedBox(height: 24.h),
          ],
        ),
      );
    }

    return const Center(child: LoadingWidget());
  }
}
