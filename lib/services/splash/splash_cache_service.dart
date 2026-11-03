import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../config/global.dart';
import '../../model/splash_model/splash_config_model.dart';

class SplashCacheService {
  final BaseCacheManager _cacheManager;

  SplashCacheService({BaseCacheManager? cacheManager})
      : _cacheManager = cacheManager ?? DefaultCacheManager();

  /// Synchronously get currently active splash config from memory/Hive
  SplashItemModel? getActiveSplash() {
    try {
      final json = Global.cachedActiveSplashConfig;
      if (json != null) {
        final model = SplashItemModel.fromJson(json);
        if (model.isValid) {
          // If background is an image or video, verify that the local file exists on disk
          if ((model.background.isImage || model.background.isVideo) && model.localBgPath != null) {
            if (!File(model.localBgPath!).existsSync()) {
              debugPrint('⚠️ [SplashCacheService] Active splash localBgPath missing on disk: ${model.localBgPath}');
              return null;
            }
          }
          // If overlay is enabled and has a local path, verify it exists on disk
          if (model.overlay.enabled && model.localOverlayPath != null) {
            if (!File(model.localOverlayPath!).existsSync()) {
              debugPrint('⚠️ [SplashCacheService] Active splash localOverlayPath missing on disk: ${model.localOverlayPath}');
              return null;
            }
          }
          return model;
        }
      }
    } catch (e) {
      debugPrint('❌ [SplashCacheService] Error reading active splash: $e');
    }
    return null;
  }

  /// Get cached staged splash config
  SplashItemModel? getStagedSplash() {
    try {
      final json = Global.cachedStagedSplashConfig;
      if (json != null) {
        final model = SplashItemModel.fromJson(json);
        if (model.isValid) return model;
      }
    } catch (e) {
      debugPrint('❌ [SplashCacheService] Error reading staged splash: $e');
    }
    return null;
  }

  /// Get cached File from cache manager for a URL (e.g. for Lottie or Video)
  Future<File?> getCachedFile(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url.trim());
      if (fileInfo != null && fileInfo.file.existsSync()) {
        return fileInfo.file;
      }
    } catch (e) {
      debugPrint('❌ [SplashCacheService] Error getting file from cache: $e');
    }
    return null;
  }

  /// Checks if two splash configs are deeply identical in content and metadata
  bool _isSplashContentEqual(SplashItemModel? a, SplashItemModel? b) {
    if (a == null || b == null) return false;
    if (a.cacheKey != b.cacheKey) return false;
    if (a.version != b.version) return false;
    if (a.updatedAt != b.updatedAt) return false;
    if (a.minDisplaySeconds != b.minDisplaySeconds) return false;

    // Check background
    if (a.background.type != b.background.type) return false;
    if (a.background.color != b.background.color) return false;
    if (a.background.imageUrl != b.background.imageUrl) return false;
    if (a.background.videoUrl != b.background.videoUrl) return false;

    // Check overlay
    if (a.overlay.enabled != b.overlay.enabled) return false;
    if (a.overlay.type != b.overlay.type) return false;
    if (a.overlay.url != b.overlay.url) return false;
    if (a.overlay.position.xPercent != b.overlay.position.xPercent) return false;
    if (a.overlay.position.yPercent != b.overlay.position.yPercent) return false;
    if (a.overlay.position.widthPercent != b.overlay.position.widthPercent) return false;

    return true;
  }

  /// Verifies that all declared media files actually exist and are non-empty on disk
  Future<bool> _areAllAssetsOnDisk(SplashItemModel splash) async {
    final urls = splash.allMediaUrls;
    if (urls.isEmpty) return true;
    for (final url in urls) {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo == null || !fileInfo.file.existsSync() || fileInfo.file.lengthSync() == 0) {
        debugPrint('[Splash Check] ⚠️ Asset missing on local disk: $url');
        return false;
      }
    }
    return true;
  }

  /// Sync with remote data: handles promotion, pre-caching, and garbage collection
  Future<void> syncSplashData(SplashConfigData remoteData) async {
    try {
      final localActive = getActiveSplash();
      final localStaged = getStagedSplash();
      final serverCurrent = remoteData.current;
      final serverStaged = remoteData.stagedNext;

      debugPrint('───────────────────────────────────────────────────────');
      debugPrint('[Splash Sync] 🔄 Starting splash sync (Rider)...');
      debugPrint('[Splash Sync]    Local Active  : ${localActive?.cacheKey ?? "None"}');
      debugPrint('[Splash Sync]    Server Current: ${serverCurrent?.cacheKey ?? "None"}');

      // ── STEP 1: Handle Server Current ──────────────────────────────────────
      if (serverCurrent != null && serverCurrent.isValid) {
        final bool contentMatches = _isSplashContentEqual(localActive, serverCurrent);
        final bool filesReady = contentMatches && await _areAllAssetsOnDisk(serverCurrent);

        if (contentMatches && filesReady) {
          debugPrint('[Splash Sync] 🟢 Active splash is completely up to date & all files verified on disk: ${serverCurrent.cacheKey}');
          if (localActive?.localBgPath == null || (serverCurrent.overlay.enabled && localActive?.localOverlayPath == null)) {
            final resolved = await _downloadAndResolveAssets(serverCurrent);
            if (resolved != null) {
              await Global.saveCachedActiveSplashConfig(resolved.toJson());
              debugPrint('[Splash Sync] 💾 Linked local file paths to active splash in Hive.');
            }
          }
        } else if (localStaged != null && _isSplashContentEqual(localStaged, serverCurrent) && await _areAllAssetsOnDisk(localStaged)) {
          // PROMOTION: Server promoted our pre-cached staged splash to current!
          debugPrint('[Splash Sync] 🚀 PROMOTING staged splash to active: ${serverCurrent.cacheKey}');
          final resolvedCurrent = await _downloadAndResolveAssets(serverCurrent);
          await Global.saveCachedActiveSplashConfig((resolvedCurrent ?? serverCurrent).toJson());
          await Global.saveCachedStagedSplashConfig(null);
          debugPrint('[Splash Sync] ✅ Staged splash successfully promoted to Active!');
        } else {
          if (!contentMatches) {
            debugPrint('[Splash Sync] 🔄 Server current changed or was incomplete in local cache! Downloading new assets...');
          } else {
            debugPrint('[Splash Sync] 🔄 Server current config matches, but asset files are missing on disk! Downloading assets...');
          }
          final resolvedCurrent = await _downloadAndResolveAssets(serverCurrent);
          if (resolvedCurrent != null) {
            await Global.saveCachedActiveSplashConfig(resolvedCurrent.toJson());
            debugPrint('[Splash Sync] 💾 Successfully saved new active splash with local paths to Hive.');
          } else {
            debugPrint('[Splash Sync] ⚠️ Failed to download all current assets; keeping existing active splash.');
          }
        }
      }

      // ── STEP 2: Handle Server Staged Next ──────────────────────────────────
      if (serverStaged != null && serverStaged.isValid) {
        final bool stagedContentMatches = _isSplashContentEqual(localStaged, serverStaged);
        final bool stagedFilesReady = stagedContentMatches && await _areAllAssetsOnDisk(serverStaged);

        if (stagedContentMatches && stagedFilesReady) {
          debugPrint('[Splash Sync] 🟢 Staged splash is already pre-cached & files verified on disk: ${serverStaged.cacheKey}');
          if (localStaged?.localBgPath == null || (serverStaged.overlay.enabled && localStaged?.localOverlayPath == null)) {
            final resolved = await _downloadAndResolveAssets(serverStaged);
            if (resolved != null) {
              await Global.saveCachedStagedSplashConfig(resolved.toJson());
            }
          }
        } else {
          debugPrint('[Splash Sync] 📦 Staged splash needs download / pre-caching: ${serverStaged.cacheKey}');
          if (localStaged != null && localStaged.cacheKey != localActive?.cacheKey) {
            await _evictAssets(localStaged);
          }
          final resolvedStaged = await _downloadAndResolveAssets(serverStaged);
          if (resolvedStaged != null) {
            await Global.saveCachedStagedSplashConfig(resolvedStaged.toJson());
            debugPrint('[Splash Sync] 💾 Successfully pre-cached staged splash with local paths.');
          }
        }
      } else {
        // Server staged next is null: clear local staged if any
        if (localStaged != null) {
          debugPrint('[Splash Sync] 🗑️ Server staged splash is empty; clearing local staged splash.');
          if (localStaged.cacheKey != localActive?.cacheKey) {
            await _evictAssets(localStaged);
          }
          await Global.saveCachedStagedSplashConfig(null);
        }
      }
      debugPrint('───────────────────────────────────────────────────────');
    } catch (e, st) {
      debugPrint('❌ [SplashCacheService] Error syncing splash data: $e');
      log('[SplashCacheService] StackTrace: $st');
    }
  }

  Future<SplashItemModel?> _downloadAndResolveAssets(SplashItemModel splash) async {
    final urls = splash.allMediaUrls;
    if (urls.isEmpty) {
      debugPrint('[Splash Download] ℹ️ No media assets declared for ${splash.cacheKey}');
      return splash;
    }

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('[Splash Download] 🚀 Resolving local assets for ${splash.cacheKey} (${urls.length} files)');
    bool allSuccess = true;
    int index = 0;
    String? resolvedBgPath = splash.localBgPath;
    String? resolvedOverlayPath = splash.localOverlayPath;

    for (final url in urls) {
      index++;
      try {
        // 1. Check if already in cache
        final existing = await _cacheManager.getFileFromCache(url);
        if (existing != null && existing.file.existsSync() && existing.file.lengthSync() > 0) {
          final sizeKb = (existing.file.lengthSync() / 1024).toStringAsFixed(1);
          debugPrint('[Splash Download] ⚡ [$index/${urls.length}] ALREADY CACHED: $url ($sizeKb KB)');
          debugPrint('[Splash Download]    Local Path: ${existing.file.path}');
          if (url == splash.background.imageUrl || url == splash.background.videoUrl) {
            resolvedBgPath = existing.file.path;
          }
          if (url == splash.overlay.url) resolvedOverlayPath = existing.file.path;
          continue;
        }

        // 2. Download fresh file
        debugPrint('[Splash Download] ⏳ [$index/${urls.length}] Downloading: $url ...');
        final fileInfo = await _cacheManager.downloadFile(url);
        if (fileInfo.file.existsSync() && fileInfo.file.lengthSync() > 0) {
          final sizeKb = (fileInfo.file.lengthSync() / 1024).toStringAsFixed(1);
          debugPrint('[Splash Download] ✅ [$index/${urls.length}] DOWNLOAD SUCCESS! ($sizeKb KB)');
          debugPrint('[Splash Download]    Saved to: ${fileInfo.file.path}');
          if (url == splash.background.imageUrl || url == splash.background.videoUrl) {
            resolvedBgPath = fileInfo.file.path;
          }
          if (url == splash.overlay.url) resolvedOverlayPath = fileInfo.file.path;
        } else {
          debugPrint('[Splash Download] ❌ [$index/${urls.length}] Downloaded file is empty: $url');
          allSuccess = false;
        }
      } catch (e, st) {
        debugPrint('[Splash Download] ❌ [$index/${urls.length}] FAILED to download: $url | Error: $e');
        log('[Splash Download] Error details: $e | $st');
        allSuccess = false;
      }
    }

    debugPrint('[Splash Download] 🏁 Result for ${splash.cacheKey}: ${allSuccess ? "ALL ASSETS READY ✅" : "SOME DOWNLOADS FAILED ❌"}');
    debugPrint('═══════════════════════════════════════════════════════');
    if (!allSuccess) return null;

    return splash.copyWith(
      localBgPath: resolvedBgPath,
      localOverlayPath: resolvedOverlayPath,
    );
  }

  Future<void> _evictAssets(SplashItemModel splash) async {
    for (final url in splash.allMediaUrls) {
      try {
        await _cacheManager.removeFile(url);
        debugPrint('[Splash Eviction] 🗑️ Removed cached asset: $url');
      } catch (e) {
        debugPrint('❌ [Splash Eviction] Failed to evict asset $url: $e');
      }
    }
  }
}
