import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/global.dart';

import '../router/app_routes.dart';
import 'app_images.dart';

bool isTablet({BuildContext? context}) {
  final shortestSide =
      MediaQuery.of(
        context ?? navigatorKey.currentState!.context,
      ).size.shortestSide;
  return shortestSide >= 600;
}

double sz(double num, {double? seprateTabletSize}) {
  if (isTablet()) {
    return seprateTabletSize ?? num;
  }
  return num;
}

String? parseString(dynamic value, {String context = 'parseString'}) {
  if (value == null) {
    // developer.log('parseString: value is null → returning null', name: context);
    return null;
  }

  if (value == "") {
    // developer.log('parseString: value is empty string → returning null', name: context);
    return null;
  }

  // developer.log('parseString: value string value is "$value" (original: $value)', name: context);
  return value.toString();
}

double? parseDouble(dynamic value, {String context = 'parseDouble'}) {
  if (value == null) {
    // developer.log('parseDouble: value is null → returning null', name: context);
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    try {
      final double? parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    } catch (e) {
      // developer.log('parseDouble: error parsing String "$value" → returning null', name: context);
    }
  }

  // developer.log('parseDouble: unrecognized type or format for "$value" → returning null', name: context);
  return null;
}

int? parseInt(dynamic value, {String context = 'parseInt'}) {
  if (value == null) {
    // developer.log('parseInt: value is null → returning null', name: context);
    return null;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    try {
      final int? parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    } catch (e) {
      // developer.log('parseInt: error parsing String "$value" → returning null', name: context);
    }
  }

  // developer.log('parseInt: unrecognized type or format for "$value" → returning null', name: context);
  return null;
}

bool? parseBool(dynamic value, {String context = 'parseBool'}) {
  if (value == null) {
    // developer.log('parseBool: value is null → returning null', name: context);
    return null;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final String str = value.trim().toLowerCase();
    if (str == 'true' || str == '1' || str == 'yes') {
      return true;
    }
    if (str == 'false' || str == '0' || str == 'no') {
      return false;
    }
  }

  // developer.log('parseBool: unrecognized value "$str" (original: $value) → returning null', name: context);
  return null;
}

enum ApiStatus { initial, loading, success, failed }

enum MobileANdEmailStatus { initial, loading, isnew, isuse }

String myLogoImage() {
  return AppImages.splashLogo;
}

Future<void> redirectionCondition(BuildContext context) async {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    if (Platform.isAndroid) {
      bool isUserAgree = Global.isLocationAccepted;
      if (isUserAgree) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.locaitonDisclosure);
      }
    } else {
      context.go(AppRoutes.home);
    }
  });
}

String removeUnderscores(String label) {
  return label.replaceAll('_', ' ').trim();
}

bool isNetworkImage(String path) {
  return path.startsWith('http://') || path.startsWith('https://');
}

bool isBottom(dynamic scroll) {
  if (scroll is ScrollController) {
    if (!scroll.hasClients) return false;
    final maxScroll = scroll.position.maxScrollExtent;
    final currentScroll = scroll.offset;
    if (maxScroll <= 0 || currentScroll <= 0) return false;
    return currentScroll >= (maxScroll * 0.9);
  } else if (scroll is ScrollMetrics) {
    final maxScroll = scroll.maxScrollExtent;
    final currentScroll = scroll.pixels;
    if (maxScroll <= 0 || currentScroll <= 0) return false;
    return currentScroll >= (maxScroll * 0.9);
  }
  return false;
}

// 1. Create a ColorMapper class
class CustomColorMapper extends ColorMapper {
  final Color targetColor;
  final Color replacementColor;

  const CustomColorMapper({
    required this.targetColor,
    required this.replacementColor,
  });

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    // If the SVG engine finds the old color, swap it with the new one
    if (color == targetColor) {
      return replacementColor;
    }
    // Otherwise, leave the original color alone
    return color;
  }
}
