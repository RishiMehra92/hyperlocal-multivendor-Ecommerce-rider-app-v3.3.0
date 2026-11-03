import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:location/location.dart';
import 'package:hyper_local/screens/feed_page/view/map/store_pickup_route/services/location_service.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';

class LocationPermissionWrapper extends StatefulWidget {
  final Widget child;

  const LocationPermissionWrapper({super.key, required this.child});

  @override
  State<LocationPermissionWrapper> createState() =>
      _LocationPermissionWrapperState();
}

class _LocationPermissionWrapperState extends State<LocationPermissionWrapper>
    with WidgetsBindingObserver {
  bool _hasPermission = false;
  bool _isGpsEnabled = false;
  bool _checking = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationStatus();
    // Periodically re-check every 3 seconds to auto-unlock when user enables GPS from settings
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkLocationStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationStatus();
    }
  }

  Future<void> _checkLocationStatus() async {
    try {
      final location = Location();
      final serviceEnabled = await location.serviceEnabled();
      final permission = await location.hasPermission();

      final bool hasPermission =
          permission == PermissionStatus.granted ||
          permission == PermissionStatus.grantedLimited;

      if (mounted) {
        setState(() {
          _isGpsEnabled = serviceEnabled;
          _hasPermission = hasPermission;
          _checking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  Future<void> _requestAccess() async {
    setState(() {
      _checking = true;
    });

    final success = await LocationService.requestPermissionAndService();
    await _checkLocationStatus();

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text:
                !_isGpsEnabled
                    ? 'Please enable GPS/Location Services'
                    : 'Please grant Location Permission in App Settings',
            color: Colors.white,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasPermission && _isGpsEnabled) {
      return widget.child;
    }

    // Determine the specific issue
    final bool isGpsIssue = !_isGpsEnabled;
    final String title =
        isGpsIssue
            ? context.tr('locationServiceDisabled')
            : context.tr('locationPermissionDenied');
    final String description =
        isGpsIssue
            ? context.tr('locationServiceDescription')
            : context.tr('locationPermissionDescription');
    final String buttonLabel =
        isGpsIssue
            ? context.tr('enable')
            : context.tr('grantPermission');
    final IconData icon =
        isGpsIssue ? Icons.gps_off_rounded : Icons.location_off_rounded;

    return CustomScaffold(
      padding: EdgeInsets.all(24.w),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Glowing circular icon container
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade200.withValues(alpha: 0.3),
                  blurRadius: 20.r,
                  spreadRadius: 5.r,
                ),
              ],
            ),
            child: Icon(icon, size: 64.sp, color: Colors.red.shade600),
          ),
          SizedBox(height: 32.h),

          // Title
          CustomText(
            text: title,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),

          // Description
          CustomText(
            text: description,
            fontWeight: FontWeight.w400,
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
          SizedBox(height: 40.h),

          // Action button
          CustomButton(
            text: buttonLabel,
            onPressed: _requestAccess,
            width: double.infinity,
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          ),
          SizedBox(height: 16.h),

          // Retry button
          TextButton(
            onPressed: () {
              setState(() {
                _checking = true;
              });
              _checkLocationStatus();
            },
            child: CustomText(
              text: context.tr('retry'),
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
