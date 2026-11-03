import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hyper_local/screens/onboarding/model/onboarding_model.dart';

class HexColorHelper {
  /// Safely parse hex color strings (#RRGGBB, #AARRGGBB, #RGB, RRGGBB)
  static Color parse(String? hex, {Color fallback = Colors.transparent}) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    String cleanHex = hex.trim().replaceAll('#', '');
    if (cleanHex.length == 3) {
      // Expand 3-digit shorthand (e.g. #FFF -> #FFFFFF)
      cleanHex = cleanHex.split('').map((c) => '$c$c').join();
    }
    if (cleanHex.length == 6) {
      // Add default alpha channel
      cleanHex = 'FF$cleanHex';
    }
    if (cleanHex.length == 8) {
      final value = int.tryParse(cleanHex, radix: 16);
      if (value != null) {
        return Color(value);
      }
    }
    return fallback;
  }

  /// Estimates the luminance of the screen background to guarantee text/button legibility
  static double estimateBackgroundLuminance(OnboardingBackground bg, [OnboardingOverlay? overlay]) {
    double baseLuminance = 1.0;
    if (bg.isSolid) {
      baseLuminance = parse(bg.color, fallback: Colors.white).computeLuminance();
    } else if (bg.isGradient) {
      final start = parse(bg.gradientStartColor, fallback: const Color(0xFF0D6EFD)).computeLuminance();
      final end = parse(bg.gradientEndColor, fallback: const Color(0xFF20C997)).computeLuminance();
      baseLuminance = (start + end) / 2.0;
    } else {
      // Image background default
      baseLuminance = 0.5;
    }

    // Blend with overlay if enabled
    if (overlay != null && overlay.enabled) {
      final overlayLum = parse(overlay.color, fallback: Colors.black).computeLuminance();
      final op = overlay.opacity.clamp(0.0, 1.0);
      baseLuminance = (overlayLum * op) + (baseLuminance * (1.0 - op));
    }

    return baseLuminance;
  }

  /// Returns high contrast foreground color based on background luminance
  static Color getContrastColor(Color background, {Color darkText = const Color(0xFF1F2937), Color lightText = Colors.white}) {
    return background.computeLuminance() > 0.5 ? darkText : lightText;
  }
}

class GradientAngleHelper {
  /// Converts CSS gradient angle in degrees (where 0deg = to top, 90deg = to right,
  /// 180deg = to bottom, 270deg = to left) to Flutter's (begin, end) Alignment pair.
  static (Alignment begin, Alignment end) alignmentsForAngle(double angleInDegrees) {
    // Exact cardinal directions
    final normalized = (angleInDegrees % 360 + 360) % 360;
    if ((normalized - 180).abs() < 0.1) {
      return (Alignment.topCenter, Alignment.bottomCenter);
    } else if ((normalized - 0).abs() < 0.1) {
      return (Alignment.bottomCenter, Alignment.topCenter);
    } else if ((normalized - 90).abs() < 0.1) {
      return (Alignment.centerLeft, Alignment.centerRight);
    } else if ((normalized - 270).abs() < 0.1) {
      return (Alignment.centerRight, Alignment.centerLeft);
    } else if ((normalized - 45).abs() < 0.1) {
      return (Alignment.bottomLeft, Alignment.topRight);
    } else if ((normalized - 135).abs() < 0.1) {
      return (Alignment.topLeft, Alignment.bottomRight);
    } else if ((normalized - 225).abs() < 0.1) {
      return (Alignment.topRight, Alignment.bottomLeft);
    } else if ((normalized - 315).abs() < 0.1) {
      return (Alignment.bottomRight, Alignment.topLeft);
    }

    // Convert CSS angle to standard math angle in radians (CSS: 0 is North/up, clockwise)
    final mathAngle = (90 - normalized) * (math.pi / 180);
    final cosVal = math.cos(mathAngle);
    final sinVal = math.sin(mathAngle);

    // Alignment coordinates in Flutter: X from -1 to 1, Y from -1 to 1 (Y is down)
    final endX = cosVal;
    final endY = -sinVal;

    return (Alignment(-endX, -endY), Alignment(endX, endY));
  }
}

class DesignMapper {
  static BoxFit mapBoxFit(String? fit) {
    switch (fit?.toLowerCase().trim()) {
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      case 'fitwidth':
      case 'fit_width':
        return BoxFit.fitWidth;
      case 'fitheight':
      case 'fit_height':
        return BoxFit.fitHeight;
      case 'scaleDown':
      case 'scale_down':
        return BoxFit.scaleDown;
      case 'none':
        return BoxFit.none;
      case 'contain':
      default:
        return BoxFit.contain;
    }
  }

  static Alignment mapAlignment(String? position) {
    switch (position?.toLowerCase().trim().replaceAll('-', '').replaceAll('_', '')) {
      case 'top':
      case 'topcenter':
        return Alignment.topCenter;
      case 'topleft':
        return Alignment.topLeft;
      case 'topright':
        return Alignment.topRight;
      case 'bottom':
      case 'bottomcenter':
        return Alignment.bottomCenter;
      case 'bottomleft':
        return Alignment.bottomLeft;
      case 'bottomright':
        return Alignment.bottomRight;
      case 'left':
      case 'centerleft':
        return Alignment.centerLeft;
      case 'right':
      case 'centerright':
        return Alignment.centerRight;
      case 'center':
      default:
        return Alignment.center;
    }
  }

  static TextAlign mapTextAlign(String? alignment) {
    switch (alignment?.toLowerCase().trim()) {
      case 'left':
      case 'start':
        return TextAlign.left;
      case 'right':
      case 'end':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  static CrossAxisAlignment mapCrossAxisAlignment(String? alignment) {
    switch (alignment?.toLowerCase().trim()) {
      case 'left':
      case 'start':
        return CrossAxisAlignment.start;
      case 'right':
      case 'end':
        return CrossAxisAlignment.end;
      case 'center':
      default:
        return CrossAxisAlignment.center;
    }
  }
}
