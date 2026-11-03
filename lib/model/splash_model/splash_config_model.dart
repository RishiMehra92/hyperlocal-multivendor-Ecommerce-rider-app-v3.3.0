Map<String, dynamic>? _asStringMap(dynamic val) {
  if (val == null) return null;
  if (val is Map<String, dynamic>) return val;
  if (val is Map) {
    return val.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

class SplashConfigResponse {
  final bool success;
  final String? message;
  final SplashConfigData? data;

  SplashConfigResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory SplashConfigResponse.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = _asStringMap(rawJson) ?? {};
    final dataMap = _asStringMap(json['data']);
    return SplashConfigResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: dataMap != null ? SplashConfigData.fromJson(dataMap) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null) 'data': data!.toJson(),
    };
  }
}

class SplashConfigData {
  final SplashItemModel? current;
  final SplashItemModel? stagedNext;

  SplashConfigData({
    this.current,
    this.stagedNext,
  });

  factory SplashConfigData.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = _asStringMap(rawJson) ?? {};
    final curMap = _asStringMap(json['current']);
    final stagedMap = _asStringMap(json['staged_next']);
    return SplashConfigData(
      current: curMap != null ? SplashItemModel.fromJson(curMap) : null,
      stagedNext: stagedMap != null ? SplashItemModel.fromJson(stagedMap) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current?.toJson(),
      'staged_next': stagedNext?.toJson(),
    };
  }
}

class SplashItemModel {
  final String id;
  final String version;
  final String cacheKey;
  final int minDisplaySeconds;
  final SplashBackgroundModel background;
  final SplashOverlayModel overlay;
  final List<SplashAssetModel> assets;
  final String? updatedAt;
  final String? localBgPath;
  final String? localOverlayPath;

  SplashItemModel({
    required this.id,
    required this.version,
    required this.cacheKey,
    this.minDisplaySeconds = 2,
    required this.background,
    required this.overlay,
    this.assets = const [],
    this.updatedAt,
    this.localBgPath,
    this.localOverlayPath,
  });

  factory SplashItemModel.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = _asStringMap(rawJson) ?? {};
    var rawAssets = json['assets'];
    List<SplashAssetModel> parsedAssets = [];
    if (rawAssets is List) {
      for (var item in rawAssets) {
        final itemMap = _asStringMap(item);
        if (itemMap != null) {
          parsedAssets.add(SplashAssetModel.fromJson(itemMap));
        }
      }
    }

    final bgMap = _asStringMap(json['background']);
    final overlayMap = _asStringMap(json['overlay']);

    return SplashItemModel(
      id: json['id']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      cacheKey: json['cache_key']?.toString() ?? '',
      minDisplaySeconds: (json['min_display_seconds'] as num?)?.toInt() ?? 2,
      background: bgMap != null
          ? SplashBackgroundModel.fromJson(bgMap)
          : SplashBackgroundModel.fallback(),
      overlay: overlayMap != null
          ? SplashOverlayModel.fromJson(overlayMap)
          : SplashOverlayModel.fallback(),
      assets: parsedAssets,
      updatedAt: json['updated_at']?.toString(),
      localBgPath: json['local_bg_path']?.toString(),
      localOverlayPath: json['local_overlay_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'cache_key': cacheKey,
      'min_display_seconds': minDisplaySeconds,
      'background': background.toJson(),
      'overlay': overlay.toJson(),
      'assets': assets.map((a) => a.toJson()).toList(),
      if (updatedAt != null) 'updated_at': updatedAt,
      if (localBgPath != null) 'local_bg_path': localBgPath,
      if (localOverlayPath != null) 'local_overlay_path': localOverlayPath,
    };
  }

  SplashItemModel copyWith({
    String? localBgPath,
    String? localOverlayPath,
  }) {
    return SplashItemModel(
      id: id,
      version: version,
      cacheKey: cacheKey,
      minDisplaySeconds: minDisplaySeconds,
      background: background,
      overlay: overlay,
      assets: assets,
      updatedAt: updatedAt,
      localBgPath: localBgPath ?? this.localBgPath,
      localOverlayPath: localOverlayPath ?? this.localOverlayPath,
    );
  }

  List<String> get allMediaUrls {
    final urls = <String>{};
    if (background.imageUrl != null && background.imageUrl!.trim().isNotEmpty) {
      urls.add(background.imageUrl!.trim());
    }
    if (background.videoUrl != null && background.videoUrl!.trim().isNotEmpty) {
      urls.add(background.videoUrl!.trim());
    }
    if (overlay.enabled && overlay.url != null && overlay.url!.trim().isNotEmpty) {
      urls.add(overlay.url!.trim());
    }
    for (var a in assets) {
      if (a.url != null && a.url!.trim().isNotEmpty) {
        urls.add(a.url!.trim());
      }
    }
    return urls.toList();
  }

  bool get isValid => id.isNotEmpty && (version.isNotEmpty || cacheKey.isNotEmpty);
}

class SplashBackgroundModel {
  final String type; // 'color', 'image', 'video'
  final String? color;
  final String? imageUrl;
  final String? videoUrl;

  SplashBackgroundModel({
    required this.type,
    this.color,
    this.imageUrl,
    this.videoUrl,
  });

  factory SplashBackgroundModel.fallback() {
    return SplashBackgroundModel(
      type: 'color',
      color: '#006bd5',
    );
  }

  factory SplashBackgroundModel.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = _asStringMap(rawJson) ?? {};
    return SplashBackgroundModel(
      type: json['type']?.toString().toLowerCase() ?? 'color',
      color: json['color']?.toString(),
      imageUrl: json['image_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'color': color,
      'image_url': imageUrl,
      'video_url': videoUrl,
    };
  }

  bool get isImage => type == 'image' && imageUrl != null && imageUrl!.trim().isNotEmpty;
  bool get isVideo => type == 'video' && videoUrl != null && videoUrl!.trim().isNotEmpty;
  bool get isColor => type == 'color';
}

class SplashOverlayModel {
  final bool enabled;
  final String? type; // 'image', 'lottie'
  final String? url;
  final SplashPositionModel position;

  SplashOverlayModel({
    required this.enabled,
    this.type,
    this.url,
    required this.position,
  });

  factory SplashOverlayModel.fallback() {
    return SplashOverlayModel(
      enabled: false,
      position: SplashPositionModel.fallback(),
    );
  }

  factory SplashOverlayModel.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = _asStringMap(rawJson) ?? {};
    final posMap = _asStringMap(json['position']);
    return SplashOverlayModel(
      enabled: json['enabled'] as bool? ?? false,
      type: json['type']?.toString().toLowerCase(),
      url: json['url']?.toString(),
      position: posMap != null
          ? SplashPositionModel.fromJson(posMap)
          : SplashPositionModel.fallback(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'type': type,
      'url': url,
      'position': position.toJson(),
    };
  }

  bool get isImage => type == 'image';
  bool get isLottie => type == 'lottie';
}

class SplashPositionModel {
  final double xPercent;
  final double yPercent;
  final double widthPercent;

  SplashPositionModel({
    this.xPercent = 50.0,
    this.yPercent = 45.0,
    this.widthPercent = 60.0,
  });

  factory SplashPositionModel.fallback() {
    return SplashPositionModel();
  }

  factory SplashPositionModel.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = _asStringMap(rawJson) ?? {};
    return SplashPositionModel(
      xPercent: (json['x_percent'] as num?)?.toDouble() ?? 50.0,
      yPercent: (json['y_percent'] as num?)?.toDouble() ?? 45.0,
      widthPercent: (json['width_percent'] as num?)?.toDouble() ?? 60.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x_percent': xPercent,
      'y_percent': yPercent,
      'width_percent': widthPercent,
    };
  }
}

class SplashAssetModel {
  final String? layer;
  final String? type;
  final String? url;

  SplashAssetModel({
    this.layer,
    this.type,
    this.url,
  });

  factory SplashAssetModel.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = _asStringMap(rawJson) ?? {};
    return SplashAssetModel(
      layer: json['layer']?.toString(),
      type: json['type']?.toString(),
      url: json['url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (layer != null) 'layer': layer,
      if (type != null) 'type': type,
      if (url != null) 'url': url,
    };
  }
}
