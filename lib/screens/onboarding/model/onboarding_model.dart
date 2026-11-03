class OnboardingResponse {
  final bool success;
  final String message;
  final OnboardingConfig? data;

  OnboardingResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory OnboardingResponse.fromJson(Map<String, dynamic> json) {
    // 1. Standard API response: { "success": true, "data": { ... } }
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      return OnboardingResponse(
        success: json['success'] as bool? ?? true,
        message: json['message']?.toString() ?? '',
        data: OnboardingConfig.fromJson(json['data'] as Map<String, dynamic>),
      );
    }

    // 2. Direct root response: { "app_type": "rider", "is_enabled": true, "screens": [...] }
    if (json.containsKey('app_type') || json.containsKey('screens')) {
      return OnboardingResponse(
        success: json['success'] as bool? ?? true,
        message: json['message']?.toString() ?? '',
        data: OnboardingConfig.fromJson(json),
      );
    }

    return OnboardingResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      data: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class OnboardingConfig {
  final String appType;
  final bool isEnabled;
  final List<OnboardingScreenItem> screens;

  OnboardingConfig({
    required this.appType,
    required this.isEnabled,
    required this.screens,
  });

  factory OnboardingConfig.fromJson(Map<String, dynamic> json) {
    var rawScreens = json['screens'];
    List<OnboardingScreenItem> screensList = [];
    if (rawScreens is List) {
      screensList = rawScreens
          .whereType<Map<String, dynamic>>()
          .map((item) => OnboardingScreenItem.fromJson(item))
          .toList();
    }

    return OnboardingConfig(
      appType: json['app_type'] as String? ?? 'rider',
      isEnabled: json['is_enabled'] as bool? ?? true,
      screens: screensList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_type': appType,
      'is_enabled': isEnabled,
      'screens': screens.map((s) => s.toJson()).toList(),
    };
  }
}

class OnboardingScreenItem {
  final int id;
  final String title;
  final String subtitle;
  final String media;
  final String mediaType;
  final String mediaMimeType;
  final OnboardingDesign design;
  final bool isFallback;

  OnboardingScreenItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.media,
    required this.mediaType,
    required this.mediaMimeType,
    OnboardingDesign? design,
    this.isFallback = false,
  }) : design = design ?? OnboardingDesign.defaultDesign();

  factory OnboardingScreenItem.fromJson(Map<String, dynamic> json) {
    return OnboardingScreenItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      media: json['media']?.toString() ?? '',
      mediaType: json['media_type']?.toString().toLowerCase().trim() ?? '',
      mediaMimeType:
          json['media_mime_type']?.toString().toLowerCase().trim() ?? '',
      design: json['design'] != null && json['design'] is Map<String, dynamic>
          ? OnboardingDesign.fromJson(json['design'] as Map<String, dynamic>)
          : OnboardingDesign.defaultDesign(),
      isFallback: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'media': media,
      'media_type': mediaType,
      'media_mime_type': mediaMimeType,
      'design': design.toJson(),
    };
  }

  bool get isNetworkMedia =>
      media.startsWith('http://') || media.startsWith('https://');

  bool get isVideo {
    final type = mediaType.toLowerCase();
    final mime = mediaMimeType.toLowerCase();
    final url = media.toLowerCase();
    return type == 'video' ||
        mime.contains('video') ||
        url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.webm') ||
        url.endsWith('.mkv') ||
        url.endsWith('.avi');
  }

  bool get isLottie {
    final type = mediaType.toLowerCase();
    final mime = mediaMimeType.toLowerCase();
    final url = media.toLowerCase();
    return type == 'lottie' ||
        type == 'json' ||
        mime.contains('json') ||
        url.endsWith('.json');
  }

  bool get isSvg {
    final type = mediaType.toLowerCase();
    final mime = mediaMimeType.toLowerCase();
    final url = media.toLowerCase();
    return type == 'svg' ||
        mime.contains('svg') ||
        url.endsWith('.svg');
  }

  bool get isImage {
    final type = mediaType.toLowerCase();
    final mime = mediaMimeType.toLowerCase();
    final url = media.toLowerCase();
    return type == 'image' ||
        mime.contains('image') ||
        url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.webp') ||
        url.endsWith('.gif');
  }
}

class OnboardingDesign {
  final OnboardingBackground background;
  final OnboardingOverlay? overlay;
  final double overlayOpacity;
  final OnboardingTextDesign text;
  final OnboardingMediaDesign media;
  final OnboardingButtonDesign button;
  final OnboardingIndicatorDesign indicator;

  OnboardingDesign({
    required this.background,
    this.overlay,
    this.overlayOpacity = 0.0,
    required this.text,
    required this.media,
    required this.button,
    required this.indicator,
  });

  factory OnboardingDesign.fromJson(Map<String, dynamic> json) {
    final parentOverlayOpacity = _parseDouble(json['overlay_opacity'], fallback: 0.0);
    return OnboardingDesign(
      background: json['background'] is Map<String, dynamic>
          ? OnboardingBackground.fromJson(json['background'] as Map<String, dynamic>)
          : OnboardingBackground.defaultBackground(),
      overlay: json['overlay'] != null && json['overlay'] is Map<String, dynamic>
          ? OnboardingOverlay.fromJson(
              json['overlay'] as Map<String, dynamic>,
              parentOpacity: parentOverlayOpacity,
            )
          : null,
      overlayOpacity: parentOverlayOpacity,
      text: json['text'] is Map<String, dynamic>
          ? OnboardingTextDesign.fromJson(json['text'] as Map<String, dynamic>)
          : OnboardingTextDesign.defaultText(),
      media: json['media'] is Map<String, dynamic>
          ? OnboardingMediaDesign.fromJson(json['media'] as Map<String, dynamic>)
          : OnboardingMediaDesign.defaultMedia(),
      button: json['button'] is Map<String, dynamic>
          ? OnboardingButtonDesign.fromJson(json['button'] as Map<String, dynamic>)
          : OnboardingButtonDesign.defaultButton(),
      indicator: json['indicator'] is Map<String, dynamic>
          ? OnboardingIndicatorDesign.fromJson(json['indicator'] as Map<String, dynamic>)
          : OnboardingIndicatorDesign.defaultIndicator(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'background': background.toJson(),
      'overlay': overlay?.toJson(),
      'overlay_opacity': overlayOpacity,
      'text': text.toJson(),
      'media': media.toJson(),
      'button': button.toJson(),
      'indicator': indicator.toJson(),
    };
  }

  factory OnboardingDesign.defaultDesign({bool isDark = false}) {
    return OnboardingDesign(
      background: OnboardingBackground.defaultBackground(isDark: isDark),
      overlay: null,
      overlayOpacity: 0.0,
      text: OnboardingTextDesign.defaultText(isDark: isDark),
      media: OnboardingMediaDesign.defaultMedia(),
      button: OnboardingButtonDesign.defaultButton(),
      indicator: OnboardingIndicatorDesign.defaultIndicator(),
    );
  }
}

class OnboardingBackground {
  final String type; // "solid", "gradient", "image"
  final String color;
  final String gradientStartColor;
  final String gradientEndColor;
  final double gradientAngle;
  final String image;
  final String imageFit; // "cover", "contain", "fill"
  final String imagePosition; // "center", "top", "bottom", "left", "right"

  OnboardingBackground({
    required this.type,
    required this.color,
    required this.gradientStartColor,
    required this.gradientEndColor,
    required this.gradientAngle,
    required this.image,
    required this.imageFit,
    required this.imagePosition,
  });

  bool get isSolid => type.toLowerCase().trim() == 'solid';
  bool get isGradient => type.toLowerCase().trim() == 'gradient';

  bool get isVideo {
    final t = type.toLowerCase().trim();
    final url = image.toLowerCase().trim();
    return t == 'video' ||
        url.endsWith('.mp4') ||
        url.endsWith('.webm') ||
        url.endsWith('.mov') ||
        url.endsWith('.m4v') ||
        url.contains('.mp4?') ||
        url.contains('.webm?') ||
        url.contains('.mov?');
  }

  bool get isGif {
    final url = image.toLowerCase().trim();
    return url.endsWith('.gif') || url.contains('.gif?');
  }

  bool get isImage => !isVideo && (type.toLowerCase().trim() == 'image' || image.isNotEmpty);

  bool get hasMedia => image.trim().isNotEmpty;

  factory OnboardingBackground.fromJson(Map<String, dynamic> json) {
    return OnboardingBackground(
      type: json['type']?.toString().toLowerCase().trim() ?? 'solid',
      color: json['color']?.toString() ?? '#ffffff',
      gradientStartColor: json['gradient_start_color']?.toString() ?? '#0d6efd',
      gradientEndColor: json['gradient_end_color']?.toString() ?? '#20c997',
      gradientAngle: _parseDouble(json['gradient_angle'], fallback: 180.0),
      image: json['image']?.toString() ?? '',
      imageFit: json['image_fit']?.toString().toLowerCase().trim() ?? 'cover',
      imagePosition: json['image_position']?.toString().toLowerCase().trim() ?? 'center',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'color': color,
      'gradient_start_color': gradientStartColor,
      'gradient_end_color': gradientEndColor,
      'gradient_angle': gradientAngle,
      'image': image,
      'image_fit': imageFit,
      'image_position': imagePosition,
    };
  }

  factory OnboardingBackground.defaultBackground({bool isDark = false}) {
    return OnboardingBackground(
      type: 'solid',
      color: isDark ? '#121212' : '#ffffff',
      gradientStartColor: isDark ? '#1E1E2E' : '#F8F9FF',
      gradientEndColor: isDark ? '#121212' : '#FFFFFF',
      gradientAngle: 180.0,
      image: '',
      imageFit: 'cover',
      imagePosition: 'center',
    );
  }
}

class OnboardingOverlay {
  final bool enabled;
  final String type; // "color", "image"
  final String color;
  final double opacity;
  final String image;
  final String imageFit;
  final String imagePosition;
  final double imageSize;

  OnboardingOverlay({
    required this.enabled,
    required this.type,
    required this.color,
    required this.opacity,
    required this.image,
    required this.imageFit,
    required this.imagePosition,
    required this.imageSize,
  });

  bool get isColor => type.toLowerCase().trim() == 'color';
  bool get isImage => type.toLowerCase().trim() == 'image';

  factory OnboardingOverlay.fromJson(Map<String, dynamic> json, {dynamic parentOpacity}) {
    return OnboardingOverlay(
      enabled: _parseBool(json['enabled'], fallback: true),
      type: json['type']?.toString().toLowerCase().trim() ?? 'color',
      color: json['color']?.toString() ?? '#000000',
      opacity: _parseDouble(json['opacity'] ?? parentOpacity, fallback: 0.5),
      image: json['image']?.toString() ?? '',
      imageFit: json['image_fit']?.toString().toLowerCase().trim() ?? 'contain',
      imagePosition: json['image_position']?.toString().toLowerCase().trim() ?? 'center',
      imageSize: _parseDouble(json['image_size'], fallback: 80.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'type': type,
      'color': color,
      'opacity': opacity,
      'image': image,
      'image_fit': imageFit,
      'image_position': imagePosition,
      'image_size': imageSize,
    };
  }
}

class OnboardingTextDesign {
  final String titleColor;
  final String subtitleColor;
  final String alignment; // "center", "left", "right"

  OnboardingTextDesign({
    required this.titleColor,
    required this.subtitleColor,
    required this.alignment,
  });

  factory OnboardingTextDesign.fromJson(Map<String, dynamic> json) {
    return OnboardingTextDesign(
      titleColor: json['title_color']?.toString() ?? '#111827',
      subtitleColor: json['subtitle_color']?.toString() ?? '#6b7280',
      alignment: json['alignment']?.toString().toLowerCase().trim() ?? 'center',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title_color': titleColor,
      'subtitle_color': subtitleColor,
      'alignment': alignment,
    };
  }

  factory OnboardingTextDesign.defaultText({bool isDark = false}) {
    return OnboardingTextDesign(
      titleColor: isDark ? '#FFFFFF' : '#111827',
      subtitleColor: isDark ? '#9CA3AF' : '#6b7280',
      alignment: 'center',
    );
  }
}

class OnboardingMediaDesign {
  final String fit; // "cover", "contain", "fill"

  OnboardingMediaDesign({
    required this.fit,
  });

  factory OnboardingMediaDesign.fromJson(Map<String, dynamic> json) {
    return OnboardingMediaDesign(
      fit: json['fit']?.toString().toLowerCase().trim() ?? 'contain',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fit': fit,
    };
  }

  factory OnboardingMediaDesign.defaultMedia() {
    return OnboardingMediaDesign(fit: 'contain');
  }
}

class OnboardingButtonDesign {
  final String backgroundColor;
  final String foregroundColor;

  OnboardingButtonDesign({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  factory OnboardingButtonDesign.fromJson(Map<String, dynamic> json) {
    return OnboardingButtonDesign(
      backgroundColor: json['background_color']?.toString() ?? '#0d6efd',
      foregroundColor: json['foreground_color']?.toString() ?? '#ffffff',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'background_color': backgroundColor,
      'foreground_color': foregroundColor,
    };
  }

  factory OnboardingButtonDesign.defaultButton() {
    return OnboardingButtonDesign(
      backgroundColor: '#0d6efd',
      foregroundColor: '#ffffff',
    );
  }
}

class OnboardingIndicatorDesign {
  final String activeColor;
  final String inactiveColor;

  OnboardingIndicatorDesign({
    required this.activeColor,
    required this.inactiveColor,
  });

  factory OnboardingIndicatorDesign.fromJson(Map<String, dynamic> json) {
    return OnboardingIndicatorDesign(
      activeColor: json['active_color']?.toString() ?? '#0d6efd',
      inactiveColor: json['inactive_color']?.toString() ?? '#dbe2ea',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active_color': activeColor,
      'inactive_color': inactiveColor,
    };
  }

  factory OnboardingIndicatorDesign.defaultIndicator() {
    return OnboardingIndicatorDesign(
      activeColor: '#0d6efd',
      inactiveColor: '#dbe2ea',
    );
  }
}

double _parseDouble(dynamic val, {double fallback = 0.0}) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? fallback;
}

bool _parseBool(dynamic val, {bool fallback = true}) {
  if (val == null) return fallback;
  if (val is bool) return val;
  final str = val.toString().toLowerCase().trim();
  if (str == 'true' || str == '1') return true;
  if (str == 'false' || str == '0') return false;
  return fallback;
}
