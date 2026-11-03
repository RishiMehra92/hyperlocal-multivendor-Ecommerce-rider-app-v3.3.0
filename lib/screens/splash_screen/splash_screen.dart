import '../../utils/widgets/toast_message.dart';
import 'dart:developer';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/onboarding/bloc/onboarding_cubit.dart';
import 'package:hyper_local/utils/app_update/bloc/app_update_state.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_event.dart';
import '../../config/colors.dart';
import '../../config/global.dart';
import '../../config/helper.dart';
import '../../model/splash_model/splash_config_model.dart';
import '../../services/splash/splash_cache_service.dart';
import '../../services/splash/splash_repository.dart';
import '../../utils/app_update/bloc/app_update_bloc.dart';
import '../../utils/app_update/bloc/app_update_event.dart';
import '../../utils/app_update/model/update_config.dart';
import '../../utils/app_update/widgets/app_update_dialog.dart';
import '../../utils/notification_manager.dart';

Color? _getColorFromHex(String? hexString) {
  if (hexString == null || hexString.trim().isEmpty) return null;
  final buffer = StringBuffer();
  String cleanHex = hexString.trim().replaceAll('#', '');
  if (cleanHex.length == 6) buffer.write('ff');
  buffer.write(cleanHex);
  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (_) {
    return null;
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver {
  bool _updateDialogShowing = false;
  bool _hasNavigated = false;
  Timer? _safetyTimer;
  SplashItemModel? _activeSplash;
  DateTime? _splashStartTime;
  VideoPlayerController? _bgVideoController;

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();
    _activeSplash = SplashCacheService().getActiveSplash();
    if (_activeSplash != null) {
      debugPrint('[SplashScreen] 🎨 Loaded active splash from cache (Rider): ${_activeSplash!.cacheKey}');
      debugPrint('[SplashScreen]    👉 Background : ${_activeSplash!.background.type} (image: ${_activeSplash!.background.imageUrl}, color: ${_activeSplash!.background.color})');
      debugPrint('[SplashScreen]    👉 Overlay    : enabled=${_activeSplash!.overlay.enabled}, type=${_activeSplash!.overlay.type}, url=${_activeSplash!.overlay.url}');
      debugPrint('[SplashScreen]    👉 Local Paths: bg=${_activeSplash!.localBgPath}, overlay=${_activeSplash!.localOverlayPath}');
    } else {
      debugPrint('[SplashScreen] 🎨 No cached active splash found (Rider). Showing fallback while fetching remote...');
    }
    _initVideoIfApplicable();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!AppConstant.hasValidBaseUrl) {
          _safetyTimer?.cancel();
          ToastManager.show(
            context: context,
            message: 'user not found',
            type: ToastType.error,
          );
          return;
        }
        context.read<AppUpdateBloc>().add(CheckAppUpdate());
        context.read<OnboardingCubit>().preloadOnboarding();

        // 0-1 Mechanism: Fetch and sync assets purely in the background for NEXT launch.
        // Whatever splash screen started on Frame 0 remains locked for this entire session.
        SplashRepository().fetchAndSync();
      }
    });

    // Safety fallback timer: ensure splash never freezes indefinitely
    if (AppConstant.hasValidBaseUrl) {
      _safetyTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && !_hasNavigated) {
          log('⚠️ SPLASH SCREEN: Safety timeout reached, triggering navigate()');
          navigate();
        }
      });
    }
  }

  void _initVideoIfApplicable() {
    final bg = _activeSplash?.background;
    if (bg != null && bg.isVideo) {
      // 1. Priority A: Local file on disk (Instant Frame-0 initialization, zero network lag)
      final localPath = _activeSplash?.localBgPath;
      if (localPath != null && File(localPath).existsSync()) {
        debugPrint('⚡ [SplashScreen] Initializing video controller from local file: $localPath');
        _bgVideoController = VideoPlayerController.file(File(localPath))
          ..initialize().then((_) {
            if (mounted) {
              _bgVideoController?.setLooping(true);
              _bgVideoController?.setVolume(0);
              _bgVideoController?.play();
              setState(() {});
            }
          }).catchError((e) {
            log('[SplashScreen] Local video init error: $e');
          });
        return;
      }

      // 2. Priority B: Network URL fallback
      if (bg.videoUrl != null && bg.videoUrl!.isNotEmpty) {
        final uri = Uri.tryParse(bg.videoUrl!);
        if (uri != null) {
          debugPrint('🌐 [SplashScreen] Initializing video controller from network: ${bg.videoUrl}');
          _bgVideoController = VideoPlayerController.networkUrl(uri)
            ..initialize().then((_) {
              if (mounted) {
                _bgVideoController?.setLooping(true);
                _bgVideoController?.setVolume(0);
                _bgVideoController?.play();
                setState(() {});
              }
            }).catchError((e) {
              log('[SplashScreen] Video background init error: $e');
            });
        }
      }
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _bgVideoController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> navigate() async {
    if (_hasNavigated || !mounted || !AppConstant.hasValidBaseUrl) return;
    _hasNavigated = true;
    _safetyTimer?.cancel();

    // Respect minDisplaySeconds from splash config
    final elapsedMs = DateTime.now().difference(_splashStartTime ?? DateTime.now()).inMilliseconds;
    final minDisplayMs = (_activeSplash?.minDisplaySeconds ?? 2) * 1000;
    if (elapsedMs < minDisplayMs) {
      await Future.delayed(Duration(milliseconds: minDisplayMs - elapsedMs));
    }

    if (!mounted) return;

    try {
      try {
        await NotificationManager().initialize();
      } catch (e) {
        log('NotificationManager error: $e');
      }

      // Fetch system settings even if token is empty
      final settingsCompleter = Completer<void>();
      if (mounted) {
        context.read<SystemSettingsBloc>().add(
          FetchSystemSettings(completer: settingsCompleter),
        );
      }
      try {
        await settingsCompleter.future.timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            log('⚠️ SPLASH SCREEN: System Settings fetch timed out');
          },
        );
      } catch (e) {
        log('SystemSettings fetch error: $e');
      }

      if (!mounted) return;

      const bool isDemoMode = AppConstant.isDemoMode;
      final bool shouldCheckOnboarding =
          isDemoMode || !Global.isOnboardingComplete;

      if (shouldCheckOnboarding) {
        final onboardingCubit = context.read<OnboardingCubit>();
        if (onboardingCubit.shouldShowOnboarding) {
          log('[Onboarding] Showing rider onboarding (isDemoMode: $isDemoMode, isOnboardingComplete: ${Global.isOnboardingComplete})');
          if (mounted) {
            GoRouter.of(context).pushReplacement(AppRoutes.onBoarding);
          }
          return;
        } else {
          log('[Onboarding] Rider onboarding disabled (is_enabled: false) - skipping');
          if (!isDemoMode) {
            await Global.setOnboardingComplete(true);
          }
        }
      }

      final token = await Global.getUserToken();
      log('✅ SPLASH SCREEN: User Token Here $token');

      if (token != null) {
        // User is authenticated, go to dashboard
        if (mounted) {
          redirectionCondition(context);
        }
      } else {
        // User is not authenticated, go to login
        if (mounted) {
          GoRouter.of(context).pushReplacement(AppRoutes.login);
        }
      }
    } catch (e) {
      log('❌ SPLASH SCREEN: Navigation error: $e');
      // If there's an error, redirect to login as fallback
      if (mounted) {
        try {
          GoRouter.of(context).pushReplacement(AppRoutes.login);
        } catch (navigationError) {
          log('❌ SPLASH SCREEN: Navigation fallback error: $navigationError');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      wantSafeArea: false,
      backgroundColor: _activeSplash != null && _activeSplash!.isValid
          ? Colors.black
          : AppColors.primaryColor,
      body: BlocListener<AppUpdateBloc, AppUpdateState>(
        listener: (context, state) {
          log('🔍 SPLASH SCREEN: AppUpdateState listener -> status: ${state.status}');
          if (state.status == AppUpdateStatus.success) {
            if (!state.isUpdateAvailable) {
              log('🔍 SPLASH SCREEN: No update available, navigating...');
              navigate();
            } else {
              log('🔍 SPLASH SCREEN: Update available (forced: ${state.isForced})');
              final isForced = state.isForced;
              _showUpdateDialog(state.config!, isForced: isForced);
            }
          }

          if (state.status == AppUpdateStatus.failure) {
            log('🔍 SPLASH SCREEN: Update check failed, failing open...');
            navigate();
          }
        },
        child: _activeSplash != null && _activeSplash!.isValid
            ? _buildDynamicSplash(context, _activeSplash!)
            : _buildFallbackSplash(context),
      ),
    );
  }

  Widget _buildDynamicSplash(BuildContext context, SplashItemModel splash) {
    final bg = splash.background;
    final overlay = splash.overlay;
    final bgColor = _getColorFromHex(bg.color) ?? AppColors.primaryColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── LAYER 1: BASE BACKGROUND ──────────────────────────────────
        Positioned.fill(
          child: _buildBackgroundWidget(context, splash, bgColor),
        ),

        // ── LAYER 2: OVERLAY (Image or Lottie) ────────────────────────
        if (overlay.enabled && overlay.url != null && overlay.url!.trim().isNotEmpty)
          _buildOverlayWidget(context, overlay, splash.localOverlayPath),
      ],
    );
  }

  Widget _buildBackgroundWidget(
    BuildContext context,
    SplashItemModel splash,
    Color bgColor,
  ) {
    final bg = splash.background;

    // 1. Image Background
    if (bg.isImage) {
      // Priority A: Direct local file on disk (Instant Frame 0 render, 0ms latency, zero flash)
      if (splash.localBgPath != null && File(splash.localBgPath!).existsSync()) {
        debugPrint('⚡ [SplashScreen] Rendering background image directly from local disk: ${splash.localBgPath}');
        return Image.file(
          File(splash.localBgPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Error loading local background image: $error');
            return const SizedBox.expand();
          },
        );
      }

      // Priority B: CachedNetworkImage (Zero fade transition duration, neutral placeholder)
      if (bg.imageUrl != null && bg.imageUrl!.trim().isNotEmpty) {
        final cleanUrl = bg.imageUrl!.trim();
        return CachedNetworkImage(
          imageUrl: cleanUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) {
            debugPrint('⏳ [SplashScreen] Loading background image from cache/network: $url');
            return const SizedBox.expand();
          },
          imageBuilder: (context, imageProvider) {
            debugPrint('✅ [SplashScreen] Background image rendered successfully!');
            return Image(
              image: imageProvider,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
            );
          },
          errorWidget: (context, url, error) {
            debugPrint('❌ [SplashScreen] Background image failed to load: $url | Error: $error');
            return const SizedBox.expand();
          },
        );
      }
      return const SizedBox.expand();
    }

    // 2. Video Background
    if (bg.isVideo) {
      if (_bgVideoController != null && _bgVideoController!.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _bgVideoController!.value.size.width,
            height: _bgVideoController!.value.size.height,
            child: VideoPlayer(_bgVideoController!),
          ),
        );
      }
      // While video is initializing, show neutral widget — NEVER color!
      return const SizedBox.expand();
    }

    // 3. Solid Color Background - EXCLUSIVELY rendered when backend explicitly says type is 'color'
    if (bg.isColor) {
      return Container(color: bgColor);
    }

    return const SizedBox.expand();
  }

  Widget _buildOverlayWidget(
    BuildContext context,
    SplashOverlayModel overlay,
    String? localOverlayPath,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rawWidth = screenWidth * (overlay.position.widthPercent / 100.0);
    final clampedWidth = rawWidth.clamp(80.0, 400.0);
    final cleanUrl = overlay.url!.trim();

    debugPrint('🖼️ [SplashScreen] Rendering overlay ${overlay.type} (url: $cleanUrl, width: $clampedWidth, x: ${overlay.position.xPercent}%, y: ${overlay.position.yPercent}%)');

    Widget overlayContent;

    if (overlay.isLottie) {
      if (localOverlayPath != null && File(localOverlayPath).existsSync()) {
        debugPrint('⚡ [SplashScreen] Rendering overlay Lottie directly from local disk: $localOverlayPath');
        overlayContent = Lottie.file(
          File(localOverlayPath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Overlay Local Lottie failed: $error');
            return const SizedBox();
          },
        );
      } else {
        overlayContent = Lottie.network(
          cleanUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Overlay Lottie failed to load: $cleanUrl | Error: $error');
            return const SizedBox();
          },
        );
      }
    } else {
      if (localOverlayPath != null && File(localOverlayPath).existsSync()) {
        debugPrint('⚡ [SplashScreen] Rendering overlay image directly from local disk: $localOverlayPath');
        overlayContent = Image.file(
          File(localOverlayPath),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Overlay Local Image failed: $error');
            return const SizedBox();
          },
        );
      } else {
        overlayContent = CachedNetworkImage(
          imageUrl: cleanUrl,
          fit: BoxFit.contain,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) {
            debugPrint('⏳ [SplashScreen] Overlay image loading from cache/network: $url');
            return const SizedBox();
          },
          imageBuilder: (context, imageProvider) {
            debugPrint('✅ [SplashScreen] Overlay image rendered successfully: $cleanUrl');
            return Image(image: imageProvider, fit: BoxFit.contain, gaplessPlayback: true);
          },
          errorWidget: (context, url, error) {
            debugPrint('❌ [SplashScreen] Overlay Image failed to load: $url | Error: $error');
            return const SizedBox();
          },
        );
      }
    }

    return Align(
      alignment: FractionalOffset(
        (overlay.position.xPercent / 100.0).clamp(0.0, 1.0),
        (overlay.position.yPercent / 100.0).clamp(0.0, 1.0),
      ),
      child: SizedBox(
        width: clampedWidth,
        child: overlayContent,
      ),
    );
  }

  Widget _buildFallbackSplash(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SvgPicture.asset(
          "assets/svg/doodle.svg",
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.primaryColor.withValues(alpha: 0.75),
            BlendMode.srcATop,
          ),
        ),
        Center(
          child: Image.asset(
            myLogoImage(),
            width: 300,
            height: 300,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  void _onForceUpdatePressed() {
    // Dialog stays open; url_launcher opens the store.
    // Nothing to resolve here — navigation stays blocked.
  }
  void _onSoftUpdateLater() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _updateDialogShowing = false;
    navigate();
  }

  void _showUpdateDialog(UpdateConfig config, {required bool isForced}) {
    if (_updateDialogShowing || !mounted) return;
    _updateDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AppUpdateDialog(
            config: config,
            isForced: isForced,
            onLater: isForced ? _onForceUpdatePressed : _onSoftUpdateLater,
          ),
    );
  }
}
