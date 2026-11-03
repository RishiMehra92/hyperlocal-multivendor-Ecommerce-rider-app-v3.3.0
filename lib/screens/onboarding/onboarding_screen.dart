import '../../utils/widgets/toast_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'bloc/onboarding_cubit.dart';
import 'bloc/onboarding_state.dart';
import 'model/onboarding_model.dart';
import 'widgets/onboarding_background_widget.dart';
import 'widgets/onboarding_design_helpers.dart';
import 'widgets/onboarding_media_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    const bool isDemoMode = AppConstant.isDemoMode;
    if (!isDemoMode) {
      await Global.setOnboardingComplete(true);
    }
    if (mounted) {
      if (!AppConstant.hasValidBaseUrl) {
        ToastManager.show(
          context: context,
          message: 'user not found',
          type: ToastType.error,
        );
        context.go(AppRoutes.splashScreen);
        return;
      }
      context.go(AppRoutes.login);
    }
  }

  void _onNextPressed(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onSkipPressed() {
    _completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        final screens = cubit.currentScreens;
        final totalCount = screens.length;
        final currentScreen = (_currentPage < totalCount)
            ? screens[_currentPage]
            : (screens.isNotEmpty ? screens.first : null);
        final currentDesign = currentScreen?.design ?? OnboardingDesign.defaultDesign();

        return Scaffold(
          backgroundColor: HexColorHelper.parse(
            currentDesign.background.color,
            fallback: isDark ? AppColors.darkBackgroundColor : AppColors.backgroundColor,
          ),
          body: Stack(
            children: [
              // 1. Full-screen PageView: each slide renders its own background + content + overlay image
              PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: totalCount,
                itemBuilder: (context, index) {
                  return _buildPageContainer(context, screens[index], index, isDark);
                },
              ),

              // 2. Top bar (Skip button) floating with dynamic contrast color
              SafeArea(
                child: _buildTopBar(totalCount, currentDesign),
              ),

              // 3. Floating bottom controls: Dynamic Indicators + Action Button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: _buildBottomControls(totalCount, currentDesign),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageContainer(
    BuildContext context,
    OnboardingScreenItem item,
    int index,
    bool isDark,
  ) {
    final overlay = item.design.overlay;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base background: Video, GIF, Image, Gradient, or Solid + Backdrop Scrim
        OnboardingBackgroundWidget(
          design: item.design,
          isActive: _currentPage == index,
        ),

        // 2. Foreground content with SafeArea (Title & Subtitle anchored at bottom)
        SafeArea(
          child: _buildPageItem(context, item, index, isDark),
        ),

        // 3. Overlay Image on TOP OF STACK (True Overlay)
        if (overlay != null &&
            overlay.enabled &&
            (overlay.isImage || overlay.image.trim().isNotEmpty))
          OnboardingOverlayImageWidget(overlay: overlay),
      ],
    );
  }

  Widget _buildTopBar(int totalCount, OnboardingDesign design) {
    final bgLuminance = HexColorHelper.estimateBackgroundLuminance(design.background, design.overlay);
    Color skipColor = HexColorHelper.parse(design.button.backgroundColor, fallback: AppColors.primaryColor);

    if (bgLuminance < 0.4 && skipColor.computeLuminance() < 0.35) {
      skipColor = Colors.white;
    } else if (bgLuminance > 0.65 && skipColor.computeLuminance() > 0.65) {
      skipColor = const Color(0xFF1F2937);
    }

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 4.h,
        ),
        child: Visibility(
          visible: _currentPage < totalCount - 1,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: TextButton(
            onPressed: _onSkipPressed,
            child: Text(
              context.tr('skip', fallback: 'Skip'),
              style: TextStyle(
                color: skipColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(int totalCount, OnboardingDesign design) {
    final activeIndicatorColor = HexColorHelper.parse(
      design.indicator.activeColor,
      fallback: AppColors.primaryColor,
    );
    final inactiveIndicatorColor = HexColorHelper.parse(
      design.indicator.inactiveColor,
      fallback: const Color(0xFFDBE2EA),
    );
    final buttonBg = HexColorHelper.parse(
      design.button.backgroundColor,
      fallback: AppColors.primaryColor,
    );
    final buttonFg = HexColorHelper.parse(
      design.button.foregroundColor,
      fallback: Colors.white,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dynamic Page indicators
          if (totalCount > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalCount,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  height: 6.h,
                  width: _currentPage == index ? 24.w : 6.w,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? activeIndicatorColor
                        : inactiveIndicatorColor,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 22.h),
          ],

          // Dynamic Next / Get Started Button
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            width: double.infinity,
            height: 54.h,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: buttonBg,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: buttonBg.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () => _onNextPressed(totalCount),
                  child: Center(
                    child: Text(
                      _currentPage >= totalCount - 1
                          ? context.tr('getStarted', fallback: 'Get Started')
                          : context.tr('next', fallback: 'Next'),
                      style: TextStyle(
                        color: buttonFg,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageItem(
    BuildContext context,
    OnboardingScreenItem item,
    int index,
    bool isDark,
  ) {
    // Resolve localized titles/subtitles for fallback items if available
    String displayTitle = item.title;
    String displaySubtitle = item.subtitle;

    if (item.isFallback) {
      if (item.id == -1) {
        displayTitle = context.tr('onboardAcceptOrdersTitle');
        displaySubtitle = context.tr('onboardAcceptOrdersSubtitle');
      } else if (item.id == -2) {
        displayTitle = context.tr('onboardTrackEarningsTitle');
        displaySubtitle = context.tr('onboardTrackEarningsSubtitle');
      } else if (item.id == -3) {
        displayTitle = context.tr('onboardNavigateEasilyTitle');
        displaySubtitle = context.tr('onboardNavigateEasilySubtitle');
      }
    }

    final hasMedia = item.media.trim().isNotEmpty;
    final titleColor = HexColorHelper.parse(
      item.design.text.titleColor,
      fallback: isDark ? Colors.white : AppColors.textColor,
    );
    final subtitleColor = HexColorHelper.parse(
      item.design.text.subtitleColor,
      fallback: isDark ? AppColors.darkTextSecondaryColor : AppColors.textSecondaryColor,
    );
    final textAlign = DesignMapper.mapTextAlign(item.design.text.alignment);
    final crossAxisAlignment = DesignMapper.mapCrossAxisAlignment(item.design.text.alignment);

    return Column(
      children: [
        // Clearance for top bar
        SizedBox(height: 54.h),

        // Upper media stage: flexible remaining area, dynamically centers artwork
        Expanded(
          child: hasMedia
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final maxAvail = constraints.maxHeight;
                    final mediaHeight = (maxAvail * 0.88).clamp(80.0, 340.0).clamp(0.0, maxAvail);

                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                        child: OnboardingMediaWidget(
                          screen: item,
                          isActive: _currentPage == index,
                          height: mediaHeight,
                        ),
                      ),
                    );
                  },
                )
              : const SizedBox.expand(),
        ),

        // Content zone: Anchored firmly at the bottom, directly above the dot indicators
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _buildTextContent(
            displayTitle,
            displaySubtitle,
            textAlign,
            crossAxisAlignment,
            titleColor,
            subtitleColor,
          ),
        ),

        // Exact clearance directly above floating bottom controls
        SizedBox(height: 124.h),
      ],
    );
  }

  Widget _buildTextContent(
    String title,
    String subtitle,
    TextAlign textAlign,
    CrossAxisAlignment crossAxisAlignment,
    Color titleColor,
    Color subtitleColor,
  ) {
    final hasTitle = title.trim().isNotEmpty;
    final hasSubtitle = subtitle.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (hasTitle)
            SizedBox(
              width: double.infinity,
              child: Text(
                title,
                textAlign: textAlign,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  height: 1.25,
                ),
              ),
            ),
          if (hasSubtitle) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: Text(
                subtitle,
                textAlign: textAlign,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: subtitleColor,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
