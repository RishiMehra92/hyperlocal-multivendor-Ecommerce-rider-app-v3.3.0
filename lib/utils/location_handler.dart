import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

class LocationHandler {
  static bool _isDialogShowing = false;
  static StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  /// Initialize monitoring of location service status
  static void initialize() {
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      ServiceStatus status,
    ) {
      if (status == ServiceStatus.disabled) {
        checkLocationAvailability();
      } else if (status == ServiceStatus.enabled) {
        final context = navigatorKey.currentContext;
        if (_isDialogShowing && context != null && context.mounted) {
          try {
            Navigator.of(context, rootNavigator: true).pop();
          } catch (e) {
            debugPrint('Error popping location dialog: ');
          }
          _isDialogShowing = false;
        }
      }
    });

    checkLocationAvailability();
  }

  /// Stop monitoring
  static void dispose() {
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
  }

  /// Check location service and permission, show dialog if needed
  static Future<void> checkLocationAvailability() async {
    final context = navigatorKey.currentContext;
    if (_isDialogShowing || context == null || !context.mounted) return;

    final token = Global.userToken;
    if (token == null || token.isEmpty) return;

    bool isUserAgree = Global.isLocationAccepted;
    if (isUserAgree == false) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog(isPermanent: false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog(isPermanent: true);
        return;
      }
    } catch (e) {
      debugPrint('Error checking location availability: ');
    }
  }

  static void _showLocationServiceDialog() {
    final context = navigatorKey.currentContext;
    if (_isDialogShowing || context == null || !context.mounted) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              context.tr('locationServiceDisabled', fallback: 'Location Service Disabled'),
            ),
            content: Text(
              context.tr(
                'locationServiceDescription',
                fallback: 'GPS is required to track your delivery progress. Please enable location services to continue.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  _isDialogShowing = false;
                  await Geolocator.openLocationSettings();
                },
                child: Text(context.tr('enable', fallback: 'Enable')),
              ),
            ],
          ),
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  static void _showPermissionDeniedDialog({required bool isPermanent}) {
    final context = navigatorKey.currentContext;
    if (_isDialogShowing || context == null || !context.mounted) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              context.tr('locationPermissionDenied', fallback: 'Location Permission Denied'),
            ),
            content: Text(
              isPermanent
                  ? context.tr(
                    'locationPermissionPermanentDescription',
                    fallback: 'Location permission is permanently denied. Please enable it from app settings to continue.',
                  )
                  : context.tr(
                    'locationPermissionDescription',
                    fallback: 'This app needs location permission to track your delivery in real-time.',
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  _isDialogShowing = false;
                  if (isPermanent) {
                    await Geolocator.openAppSettings();
                  } else {
                    checkLocationAvailability();
                  }
                },
                child: Text(
                  isPermanent
                      ? context.tr('settings', fallback: 'Settings')
                      : context.tr('retry', fallback: 'Retry'),
                ),
              ),
            ],
          ),
    ).then((_) {
      _isDialogShowing = false;
    });
  }
}
