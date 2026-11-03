import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import '../model/onboarding_model.dart';
import 'onboarding_design_helpers.dart';

class OnboardingMediaWidget extends StatefulWidget {
  final OnboardingScreenItem screen;
  final bool isActive;
  final double height;

  const OnboardingMediaWidget({
    super.key,
    required this.screen,
    required this.isActive,
    required this.height,
  });

  @override
  State<OnboardingMediaWidget> createState() => _OnboardingMediaWidgetState();
}

class _OnboardingMediaWidgetState extends State<OnboardingMediaWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    if (widget.screen.isVideo && widget.screen.isNetworkMedia) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.screen.isVideo) {
      if (widget.screen.media != oldWidget.screen.media) {
        _disposeVideo();
        _initVideo();
      } else if (_videoController != null && _isVideoInitialized) {
        if (widget.isActive && !_videoController!.value.isPlaying) {
          _videoController!.play();
        } else if (!widget.isActive && _videoController!.value.isPlaying) {
          _videoController!.pause();
        }
      }
    }
  }

  Future<void> _initVideo() async {
    try {
      final uri = Uri.parse(widget.screen.media);
      _videoController = VideoPlayerController.networkUrl(uri);
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0.0);
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        if (widget.isActive) {
          _videoController!.play();
        }
      }
    } catch (e) {
      log('[Onboarding] Error initializing video player (${widget.screen.media}): $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
        });
      }
    }
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _hasVideoError = false;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = widget.screen;

    // Handle empty media (when media is cleared in dynamic design)
    if (screen.media.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final fit = DesignMapper.mapBoxFit(screen.design.media.fit);

    // 1. Fallback / Local Assets
    if (!screen.isNetworkMedia) {
      return SizedBox(
        height: widget.height,
        child: _buildLocalMedia(screen.media, fit),
      );
    }

    // 2. Video Media
    if (screen.isVideo) {
      if (_hasVideoError) {
        return _buildErrorPlaceholder(Icons.videocam_off_rounded);
      }
      if (!_isVideoInitialized || _videoController == null) {
        return SizedBox(
          height: widget.height,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryColor,
            ),
          ),
        );
      }
      return SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FittedBox(
            fit: fit,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
      );
    }

    // 3. Lottie Animation
    if (screen.isLottie) {
      return SizedBox(
        height: widget.height,
        child: Lottie.network(
          screen.media,
          fit: fit,
          animate: widget.isActive,
          errorBuilder: (context, error, stackTrace) {
            log('[Onboarding] Error loading Lottie: $error');
            return _buildErrorPlaceholder(Icons.animation_rounded);
          },
        ),
      );
    }

    // 4. SVG Vector
    if (screen.isSvg) {
      return SizedBox(
        height: widget.height,
        child: SvgPicture.network(
          screen.media,
          fit: fit,
          placeholderBuilder: (context) => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      );
    }

    // 5. Standard Raster Image (PNG, JPG, WebP)
    return SizedBox(
      height: widget.height,
      child: CachedNetworkImage(
        imageUrl: screen.media,
        fit: fit,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primaryColor,
          ),
        ),
        errorWidget: (context, url, error) {
          log('[Onboarding] Error loading image ($url): $error');
          return _buildErrorPlaceholder(Icons.broken_image_rounded);
        },
      ),
    );
  }

  Widget _buildLocalMedia(String path, BoxFit fit) {
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        fit: fit,
      );
    }
    if (path.endsWith('.json')) {
      return Lottie.asset(
        path,
        fit: fit,
        animate: widget.isActive,
      );
    }
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          _buildErrorPlaceholder(Icons.image_not_supported_rounded),
    );
  }

  Widget _buildErrorPlaceholder(IconData icon) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }
}
