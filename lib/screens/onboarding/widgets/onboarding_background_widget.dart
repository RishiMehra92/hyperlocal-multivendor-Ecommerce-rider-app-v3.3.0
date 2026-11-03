import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local/screens/onboarding/model/onboarding_model.dart';
import 'package:hyper_local/screens/onboarding/widgets/onboarding_design_helpers.dart';
import 'package:video_player/video_player.dart';

class OnboardingBackgroundWidget extends StatefulWidget {
  final OnboardingDesign design;
  final bool isActive;

  const OnboardingBackgroundWidget({
    super.key,
    required this.design,
    this.isActive = true,
  });

  @override
  State<OnboardingBackgroundWidget> createState() => _OnboardingBackgroundWidgetState();
}

class _OnboardingBackgroundWidgetState extends State<OnboardingBackgroundWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String? _lastVideoUrl;

  @override
  void initState() {
    super.initState();
    _checkAndInitVideo();
  }

  @override
  void didUpdateWidget(covariant OnboardingBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bg = widget.design.background;
    if (bg.isVideo && bg.image.isNotEmpty) {
      if (bg.image != _lastVideoUrl) {
        _disposeVideo();
        _checkAndInitVideo();
      } else if (_videoController != null && _isVideoInitialized) {
        if (widget.isActive && !_videoController!.value.isPlaying) {
          _videoController!.play();
        } else if (!widget.isActive && _videoController!.value.isPlaying) {
          _videoController!.pause();
        }
      }
    } else if (_videoController != null) {
      _disposeVideo();
    }
  }

  Future<void> _checkAndInitVideo() async {
    final bg = widget.design.background;
    if (bg.isVideo && bg.image.isNotEmpty) {
      final videoUrl = bg.image.trim();
      _lastVideoUrl = videoUrl;
      try {
        final uri = Uri.parse(videoUrl);
        _videoController = VideoPlayerController.networkUrl(uri);
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.setVolume(0.0); // Muted background video
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          if (widget.isActive) {
            _videoController!.play();
          }
        }
      } catch (e) {
        log('[Onboarding] Error initializing background video player ($videoUrl): $e');
      }
    }
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _lastVideoUrl = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.design.background;
    final overlay = widget.design.overlay;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base background layer (Video, GIF, Image, Gradient, or Solid)
        _buildBaseBackground(bg),

        // 2. Backdrop Color Tint Scrim (if overlay is enabled)
        if (overlay != null && overlay.enabled)
          _buildOverlay(overlay, bg),
      ],
    );
  }

  Widget _buildBaseBackground(OnboardingBackground bg) {
    final fallbackColor = HexColorHelper.parse(bg.color, fallback: Colors.white);

    // 1. Video background
    if (bg.isVideo && bg.image.isNotEmpty) {
      if (_videoController != null && _isVideoInitialized) {
        final fit = DesignMapper.mapBoxFit(bg.imageFit);
        final size = _videoController!.value.size;

        return Container(
          color: fallbackColor,
          width: double.infinity,
          height: double.infinity,
          child: FittedBox(
            fit: fit,
            alignment: DesignMapper.mapAlignment(bg.imagePosition),
            child: SizedBox(
              width: size.width > 0 ? size.width : 16,
              height: size.height > 0 ? size.height : 9,
              child: VideoPlayer(_videoController!),
            ),
          ),
        );
      }
      return Container(color: fallbackColor);
    }

    // 2. Animated GIF background
    if (bg.isGif && bg.image.isNotEmpty) {
      return Image.network(
        bg.image,
        fit: DesignMapper.mapBoxFit(bg.imageFit),
        alignment: DesignMapper.mapAlignment(bg.imagePosition),
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          log('[Onboarding] Error loading GIF (${bg.image}): $error');
          return Container(color: fallbackColor);
        },
      );
    }

    // 3. Regular Raster Image (PNG, JPG, WebP)
    if (bg.isImage && bg.image.isNotEmpty) {
      if (bg.image.startsWith('http://') || bg.image.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: bg.image,
          fit: DesignMapper.mapBoxFit(bg.imageFit),
          alignment: DesignMapper.mapAlignment(bg.imagePosition),
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Container(color: fallbackColor),
          errorWidget: (context, url, error) => Container(color: fallbackColor),
        );
      } else {
        return Image.asset(
          bg.image,
          fit: DesignMapper.mapBoxFit(bg.imageFit),
          alignment: DesignMapper.mapAlignment(bg.imagePosition),
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(color: fallbackColor),
        );
      }
    }

    // 4. Gradient background
    if (bg.isGradient) {
      final (begin, end) = GradientAngleHelper.alignmentsForAngle(bg.gradientAngle);
      final startColor = HexColorHelper.parse(
        bg.gradientStartColor,
        fallback: const Color(0xFF0D6EFD),
      );
      final endColor = HexColorHelper.parse(
        bg.gradientEndColor,
        fallback: const Color(0xFF20C997),
      );

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [startColor, endColor],
          ),
        ),
      );
    }

    // 5. Solid background
    return Container(color: fallbackColor);
  }

  Widget _buildOverlay(OnboardingOverlay overlay, OnboardingBackground bg) {
    final overlayColor = HexColorHelper.parse(overlay.color, fallback: Colors.black);

    // Color tint layer (scrim over video/image background)
    double tintAlpha = overlay.opacity.clamp(0.0, 1.0);

    if (overlay.color.isNotEmpty && overlayColor != Colors.transparent) {
      if (overlay.isImage) {
        // Subtle backdrop scrim behind overlay image
        tintAlpha = (tintAlpha * 0.35).clamp(0.0, 0.60);
      } else if (bg.hasMedia) {
        // Translucent tint over background video/image
        if (tintAlpha >= 0.8) {
          tintAlpha = 0.45;
        } else {
          tintAlpha = tintAlpha.clamp(0.05, 0.70);
        }
      }
      if (tintAlpha <= 0.01) {
        return const SizedBox.shrink();
      }
      return Container(
        color: overlayColor.withValues(alpha: tintAlpha),
      );
    } else if (overlay.isColor) {
      if (bg.hasMedia && tintAlpha >= 0.8) {
        tintAlpha = 0.45;
      }
      if (tintAlpha <= 0.01) {
        return const SizedBox.shrink();
      }
      return Container(
        color: overlayColor.withValues(alpha: tintAlpha),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Overlay Image widget rendered on TOP OF STACK so it acts as a true overlay
class OnboardingOverlayImageWidget extends StatelessWidget {
  final OnboardingOverlay overlay;

  const OnboardingOverlayImageWidget({
    super.key,
    required this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    if (!overlay.enabled || (!overlay.isImage && overlay.image.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isNetwork = overlay.image.startsWith('http://') || overlay.image.startsWith('https://');
        final fit = DesignMapper.mapBoxFit(overlay.imageFit);
        final alignment = DesignMapper.mapAlignment(overlay.imagePosition);

        // Calculate proportioned dimensions based on image_size (e.g. 80 -> 80% width)
        double targetWidth;
        if (overlay.imageSize > 0 && overlay.imageSize <= 100) {
          targetWidth = screenWidth * (overlay.imageSize / 100.0);
        } else if (overlay.imageSize > 100) {
          targetWidth = overlay.imageSize.clamp(50.0, screenWidth);
        } else {
          targetWidth = screenWidth * 0.80; // default 80% width
        }

        // Allow full-bleed coverage if explicitly set to ~100% cover,
        // otherwise cap max height to upper/middle stage to avoid overlapping bottom controls.
        final bool isFullScreenCover = (overlay.imageSize >= 95 && fit == BoxFit.cover);
        final maxHeight = isFullScreenCover ? screenHeight : screenHeight * 0.55;

        // Opacity handling: if backend specifies > 0, respect it.
        // If 0 or omitted, default to 1.0 for image overlays so they are not invisible.
        final double imageOpacity = (overlay.opacity > 0)
            ? overlay.opacity.clamp(0.05, 1.0)
            : 1.0;

        Widget rawImage = isNetwork
            ? CachedNetworkImage(
                imageUrl: overlay.image,
                fit: fit,
                alignment: alignment,
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              )
            : Image.asset(
                overlay.image,
                fit: fit,
                alignment: alignment,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              );

        return IgnorePointer(
          child: SafeArea(
            child: Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: targetWidth,
                    maxHeight: maxHeight,
                  ),
                  child: Opacity(
                    opacity: imageOpacity,
                    child: rawImage,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
