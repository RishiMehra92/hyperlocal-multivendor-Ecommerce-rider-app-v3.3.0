import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/share_helper.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';

import '../../../../../config/constant.dart';
import '../../../../../config/helper.dart';
import '../../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../../../utils/widgets/custom_button.dart';
import '../../../../../utils/widgets/custom_image_container.dart';
import '../../../../../utils/widgets/custom_scaffold.dart';
import '../../../../system_settings/bloc/system_settings_bloc.dart';
import '../bloc/refer_and_earn/refer_and_earn_bloc.dart';
import '../bloc/refer_and_earn/refer_and_earn_event.dart';
import '../bloc/refer_and_earn/refer_and_earn_state.dart';
import '../../../../../utils/widgets/loading_widget.dart';

class ReferAndEarnPage extends StatefulWidget {
  const ReferAndEarnPage({super.key});

  @override
  State<ReferAndEarnPage> createState() => _ReferAndEarnPageState();
}

class _ReferAndEarnPageState extends State<ReferAndEarnPage> {
  // Data from Bloc
  String referralCode = "";
  int totalReferrals = 0;
  double earnedAmount = 0.0;
  String? commissionRate;
  String? maxTimes;

  @override
  void initState() {
    super.initState();
    context.read<ReferAndEarnBloc>().add(FetchReferInfo());
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;
    // return const SizedBox();
    return CustomScaffold(
      appBar: CustomAppBar(title: context.tr('referAndEarn')),
      body: BlocBuilder<ReferAndEarnBloc, ReferAndEarnState>(
        builder: (context, state) {
          if (state.status == ApiStatus.loading) {
            return const Center(child: LoadingWidget());
          }

          if (state.status == ApiStatus.failed) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),

                  CustomText(
                    color: Colors.grey,
                    text:
                        context.tr('failedToLoadReferralData'),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: context.tr('retry'),
                    onPressed:
                        () => context.read<ReferAndEarnBloc>().add(
                          FetchReferInfo(),
                        ),
                  ),
                ],
              ),
            );
          }

          if (state.status == ApiStatus.success) {
            final data = state.referAndEarnData;
            final program = data?.program;

            referralCode = data?.referralCode ?? "NO CODE";
            totalReferrals = data?.totalReferrals ?? 0;
            earnedAmount = (data?.totalEarned ?? 0).toDouble();
            commissionRate = (program?.bonusReferral ?? 0).toString();
            maxTimes = program?.maxTimesBonus ?? "1";

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /*_buildEarningsCard(),
                  const SizedBox(height: 16),*/
                  _buildReferAndEarnIllustrationDescription(),
                  const SizedBox(height: 16),
                  _buildReferralCodeCard(context, isDark),
                  const SizedBox(height: 16),
                  /*_buildAppLinkCard(),
                  const SizedBox(height: 24),*/
                  _buildHowItWorks(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildReferAndEarnIllustrationDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomImageContainer(
          imagePath: "assets/svg/refer-and-earn-illustration.svg",
        ),

        const SizedBox(height: 8),

        CustomText(
          text: context.tr('referAndEarnTitle'),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),

        const SizedBox(height: 8),

        CustomText(text: context.tr('referAndEarnDescription')),
      ],
    );
  }

  Widget _buildReferralCodeCard(BuildContext context, bool isDark) {
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          /*Text(
              context.tr('yourReferralCode'),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),*/
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.darkBorderColor
                      : AppColors.greylightBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    text: referralCode,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark
                            ? AppColors.backgroundColor
                            : AppColors.textColor,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: referralCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('codeCopied')),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildShareButton(context),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    final settingsData = context.read<SystemSettingsBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: context.tr('howItWorks'),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),

        // Text(context.tr('howItWorks'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _buildStep(
          number: '1',
          title: context.tr('shareYourCode'),
          description:
              context.tr('sendYourReferralCodeOrAppLinkToFriends'),
        ),
        _buildStep(
          number: '2',
          title: context.tr('friendSignsUp'),
          description:
              context.tr('theyRegisterUsingYourReferralCode'),
        ),
        _buildStep(
          number: '3',
          title: context.tr('youEarn'),
          description:
              '${context.tr('whenTheyCompleteTheirFirstOrderYouEarn')} ${settingsData.currencySymbol}$commissionRate.',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.greylightBackground,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomText(
                    text: number,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  CustomText(text: title, fontWeight: FontWeight.w600),
                  const SizedBox(height: 4),
                  CustomText(
                    text: description,
                    fontSize: 11,
                    color: AppColors.darkTextSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: context.isDarkMode ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _handleNativeShare,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /*const Icon(Icons.share_rounded, size: 20),
              SizedBox(width: 5,),*/
            CustomText(
              text: context.tr('share'),
              textAlign: TextAlign.center,
              color:
                  context.isDarkMode
                      ? AppColors.textColor
                      : AppColors.backgroundColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  void _handleNativeShare() {
    final settings = context.read<SystemSettingsBloc>().currentSettings;
    final playStore = settings?.riderPlaystoreLink ?? "";
    final appStore = settings?.riderAppstoreLink ?? "";

    final String message =
        "Hey! Use my referral code *$referralCode* to join ${AppConstant.appName}.\n\n"
        "Download now:\n"
        "Android: $playStore\n"
        "Apple: $appStore";

    ShareHelper.shareText(message);

    // SharePlus.instance.share(ShareParams(text: message));
  }
}
